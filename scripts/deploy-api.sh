#!/bin/bash
# Script de déploiement de l'API sur la VM GCP
# Ce script est exécuté par le startup script de la VM

set -euo pipefail

# Configuration
APP_DIR="/opt/mlops-api"
APP_USER="mlops"
DOCKER_IMAGE="${DOCKER_IMAGE:-iris-api:latest}"  # Utilise la variable d'environnement ou valeur par défaut
MODEL_BUCKET="${MODEL_BUCKET:-}"  # Sera passé depuis Terraform
API_KEY="${API_KEY:-}"  # Sera passé depuis Secret Manager ou metadata

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

# Créer le répertoire pour les modèles
mkdir -p "$APP_DIR/models"
chown "$APP_USER:$APP_USER" "$APP_DIR/models"

# Télécharger le modèle depuis GCS si le bucket est configuré
if [ -n "$MODEL_BUCKET" ]; then
    echo "Téléchargement du modèle depuis GCS: $MODEL_BUCKET"
    
    # Utiliser gcloud storage (recommandé par Google)
    # Note: gcloud est généralement pré-installé sur les images GCP
    if command -v gcloud &> /dev/null; then
        echo "Utilisation de gcloud storage..."
        gcloud storage cp "gs://$MODEL_BUCKET/iris_model.pkl" "$APP_DIR/models/" || echo "Modèle non trouvé dans le bucket"
        gcloud storage cp "gs://$MODEL_BUCKET/model_metadata.json" "$APP_DIR/models/" || echo "Métadonnées non trouvées dans le bucket"
    else
        echo "⚠️  gcloud non trouvé. Installation de gsutil en fallback..."
        apt-get update
        apt-get install -y gsutil || {
            echo "❌ Impossible d'installer gsutil. Le modèle doit être présent localement."
        }
        gsutil cp "gs://$MODEL_BUCKET/iris_model.pkl" "$APP_DIR/models/" || echo "Modèle non trouvé dans le bucket"
        gsutil cp "gs://$MODEL_BUCKET/model_metadata.json" "$APP_DIR/models/" || echo "Métadonnées non trouvées dans le bucket"
    fi
    
    chown -R "$APP_USER:$APP_USER" "$APP_DIR/models"
else
    echo "⚠️  MODEL_BUCKET non configuré. Le modèle doit être présent localement."
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
    volumes:
      - $APP_DIR/models:/app/models
    environment:
      - MODEL_DIR=/app/models
      - API_KEY=${API_KEY}
      - LOG_LEVEL=INFO
      - ENVIRONMENT=production
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
