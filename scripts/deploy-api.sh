#!/bin/bash
# Script de déploiement de l'API sur la VM GCP
# Ce script est exécuté par le startup script de la VM

set -euo pipefail

# Configuration
APP_DIR="/opt/mlops-api"
APP_USER="mlops"
DOCKER_IMAGE="${DOCKER_IMAGE:-iris-api:latest}"  # Utilise la variable d'environnement ou valeur par défaut
API_KEY="${API_KEY:-}"  # Sera passé depuis Secret Manager ou metadata
CORS_ORIGINS="${CORS_ORIGINS:-}"  # ⚠️ SÉCURITÉ : Doit être configuré explicitement en production
MLFLOW_TRACKING_URI="${MLFLOW_TRACKING_URI:-}"  # Configuré automatiquement par Terraform via startup-script

# Logging
LOG_FILE="/var/log/mlops-deploy.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=========================================="
echo "Déploiement de l'API MLOps"
echo "Date: $(date)"
echo "=========================================="

# Fonction d'erreur
error_exit() {
    echo "ERREUR: $1" >&2
    exit 1
}

# Vérifier que Docker est installé
if ! command -v docker &> /dev/null; then
    error_exit "Docker n'est pas installé"
fi

# Créer l'utilisateur pour l'application (si n'existe pas)
if ! id "$APP_USER" &>/dev/null; then
    useradd -r -s /bin/bash -d "$APP_DIR" -m "$APP_USER" || true
fi

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
    # Note: Pas de volume pour models/ - metadata.json et metrics.json sont inclus dans l'image
    # Le modèle est chargé depuis MLflow via GCS en utilisant mlflow_run_id depuis metadata.json
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
# Pour l'instant, on suppose qu'elle est déjà disponible ou sera buildée manuellement
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

# Recharger systemd et activer le service
systemctl daemon-reload
systemctl enable mlops-api.service || echo "Service déjà activé"

echo "=========================================="
echo "Déploiement terminé"
echo "Pour démarrer l'API: systemctl start mlops-api"
echo "Pour voir les logs: journalctl -u mlops-api -f"
echo "=========================================="
