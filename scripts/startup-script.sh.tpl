#!/bin/bash
# Script de démarrage automatique pour la VM MLOps
# Généré par Terraform - Ne pas modifier manuellement
# Ce script installe Docker et déploie automatiquement l'API

set -euo pipefail

# Configuration
LOG_FILE="/var/log/startup.log"

# Logging
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=========================================="
echo "Démarrage de la VM MLOps"
echo "Date: $(date)"
echo "=========================================="

# Mise à jour du système
export DEBIAN_FRONTEND=noninteractive
apt-get update

# Installation de Docker
if ! command -v docker &> /dev/null; then
    echo "Installation de Docker..."
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Ajouter la clé GPG officielle de Docker
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Ajouter le repository Docker
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    systemctl start docker
    systemctl enable docker
    
    echo "✅ Docker installé avec succès"
else
    echo "✅ Docker déjà installé"
fi

# Vérifier que docker compose (plugin) est disponible
if ! docker compose version &> /dev/null; then
    echo "⚠️  docker compose (plugin) non disponible, installation..."
    apt-get install -y docker-compose-plugin || {
        echo "⚠️  Installation du plugin échouée, utilisation de docker-compose standalone"
        apt-get install -y docker-compose || {
            echo "❌ Impossible d'installer docker-compose"
            exit 1
        }
    }
fi

# Ajouter l'utilisateur root au groupe docker (pour les commandes système)
# Note: Les commandes docker dans le script sont exécutées avec sudo si nécessaire
usermod -aG docker root || true

# Déployer l'API automatiquement
echo "=========================================="
echo "Déploiement automatique de l'API"
echo "=========================================="

# Configuration pour le déploiement
APP_DIR="/opt/mlops-api"
APP_USER="mlops"
DOCKER_IMAGE="${docker_image}"
CORS_ORIGINS="${cors_origins}"
MLFLOW_TRACKING_URI="${mlflow_tracking_uri}"

# Fonction d'erreur
error_exit() {
    echo "ERREUR: $1" >&2
    exit 1
}

# Vérifier que Docker est installé
if ! command -v docker &> /dev/null; then
    error_exit "Docker n'est pas installé"
fi

%{ if secret_manager_api_key_name != "" ~}
# Récupérer l'API_KEY depuis Secret Manager
echo "Récupération de l'API_KEY depuis Secret Manager: ${secret_manager_api_key_name}"
API_KEY=$(gcloud secrets versions access latest --secret="${secret_manager_api_key_name}" --project="${project_id}" 2>/dev/null || echo "")
if [ -z "$API_KEY" ]; then
    echo "❌ ERREUR CRITIQUE : Impossible de récupérer l'API_KEY depuis Secret Manager."
    echo "   Le secret '${secret_manager_api_key_name}' n'existe pas ou n'est pas accessible."
    echo "   Vérifiez que le secret existe et que le service account a les permissions nécessaires."
    exit 1
fi
echo "✅ API_KEY récupérée avec succès depuis Secret Manager"
%{ else ~}
# API_KEY non configurée via Secret Manager
# ⚠️ SÉCURITÉ : En production, l'API_KEY doit être configurée via Secret Manager
echo "⚠️  API_KEY non configurée via Secret Manager."
echo "   Pour activer l'authentification en production, configurez secret_manager_api_key_name dans terraform.tfvars"
echo "   L'API fonctionnera sans authentification (mode développement uniquement)."
API_KEY=""
%{ endif ~}

# Créer l'utilisateur pour l'application (si n'existe pas)
if ! id "$APP_USER" &>/dev/null; then
    useradd -r -s /bin/bash -d "$APP_DIR" -m "$APP_USER" || true
fi

# Ajouter l'utilisateur au groupe docker pour pouvoir exécuter docker compose
usermod -aG docker "$APP_USER" || true

# Créer le répertoire de l'application
mkdir -p "$APP_DIR"
chown "$APP_USER:$APP_USER" "$APP_DIR"

# Note: models/metadata.json et models/metrics.json sont inclus dans l'image Docker
# Ils sont versionnés avec Git via DVC et copiés dans l'image au build time
# Le modèle est chargé depuis MLflow via GCS en utilisant mlflow_run_id depuis metadata.json

# ⚠️ SÉCURITÉ : Vérifier que CORS_ORIGINS est configuré en production
if [ -z "$CORS_ORIGINS" ]; then
    echo "⚠️  AVERTISSEMENT : CORS_ORIGINS non configuré. L'API utilisera '*' par défaut (non sécurisé en production)"
    echo "   Configurez CORS_ORIGINS dans Terraform ou via les métadonnées de la VM"
fi

# Créer le fichier docker-compose.yml
cat > "$APP_DIR/docker-compose.yml" <<EOF
version: '3.8'

services:
  iris-api:
    image: ${DOCKER_IMAGE}
    container_name: iris-api
    restart: unless-stopped
    ports:
      - "0.0.0.0:8000:8000"
    environment:
      - MODEL_DIR=/app/models
      - API_KEY=${API_KEY}
      - ENVIRONMENT=production
      - CORS_ORIGINS=${CORS_ORIGINS:-}
      - MLFLOW_TRACKING_URI=${MLFLOW_TRACKING_URI:-}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
EOF

chown "$APP_USER:$APP_USER" "$APP_DIR/docker-compose.yml"

# Note: L'image Docker doit être buildée et pushée vers un registry (GCR, Docker Hub, etc.)
echo "⚠️  Note: Assurez-vous que l'image Docker $DOCKER_IMAGE est disponible"
echo "   Vous pouvez la builder localement ou la puller depuis un registry"

# Détecter la commande docker compose (plugin) ou docker-compose (standalone)
if command -v docker &> /dev/null && docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
    echo "✅ Utilisation de docker compose (plugin)"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
    echo "✅ Utilisation de docker-compose (standalone)"
else
    error_exit "Aucune commande docker compose disponible"
fi

# Créer un service systemd pour gérer l'API
cat > /etc/systemd/system/mlops-api.service <<EOF
[Unit]
Description=MLOps Iris API Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$APP_DIR
ExecStart=/bin/bash -c "cd $APP_DIR && $DOCKER_COMPOSE_CMD up -d"
ExecStop=/bin/bash -c "cd $APP_DIR && $DOCKER_COMPOSE_CMD down"
User=$APP_USER
Group=$APP_USER

[Install]
WantedBy=multi-user.target
EOF

# Recharger systemd et activer le service (démarrage automatique au boot)
systemctl daemon-reload
systemctl enable mlops-api.service || echo "Service déjà activé"

echo "=========================================="
echo "Configuration terminée"
echo "Le service mlops-api est activé et démarrera automatiquement au boot"
echo ""
echo "Pour démarrer l'API maintenant :"
echo "  sudo systemctl start mlops-api"
echo ""
echo "Pour voir les logs :"
echo "  journalctl -u mlops-api -f"
echo "Pour redémarrer l'API :"
echo "  systemctl restart mlops-api"
echo "=========================================="

echo "✅ Déploiement automatique terminé"

echo "=========================================="
echo "Démarrage de la VM terminé"
echo "Date: $(date)"
echo "=========================================="

