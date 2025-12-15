#!/bin/bash
# Script de démarrage automatique pour la VM MLOps
# Généré par Terraform - Ne pas modifier manuellement

set -euo pipefail

# Configuration
LOG_FILE="/var/log/startup.log"
MAX_RETRIES=3
RETRY_DELAY=5
APP_DIR="/opt/mlops-api"
APP_USER="mlops"

# Logging
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=========================================="
echo "Démarrage de la VM MLOps - $(date)"
echo "=========================================="

# Fonctions utilitaires
error_exit() {
    echo "❌ ERREUR: $1" >&2
    exit 1
}

retry_command() {
    local cmd="$1" retries=$MAX_RETRIES delay=$RETRY_DELAY
    while [ $retries -gt 0 ]; do
        if eval "$cmd"; then
            return 0
        fi
        retries=$((retries - 1))
        [ $retries -gt 0 ] && echo "⚠️  Nouvelle tentative dans $${delay}s... ($retries restantes)" && sleep $delay
    done
    return 1
}

# Nettoyage "soft" (tjs exécuté à la fin)
cleanup() {
    rm -f /tmp/api_key.tmp /tmp/api_key.*
}

# Nettoyage "hard" seulement si le script plante
cleanup_on_error() {
    echo "Erreur détectée, arrêt du conteneur iris-api..."
    docker stop iris-api 2>/dev/null || true
    docker rm iris-api 2>/dev/null || true
    cleanup
}

# À la fin normale du script : on ne touche pas au conteneur
trap cleanup EXIT

# En cas d’erreur pendant le script : on stop/rm le conteneur
trap cleanup_on_error ERR

# Mise à jour système et installation Docker
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq

if ! command -v docker &> /dev/null; then
    echo "Installation de Docker..."
    apt-get install -y docker.io docker-compose ca-certificates curl gnupg lsb-release || error_exit "Échec installation Docker"
    systemctl start docker && systemctl enable docker
    
    # Attendre que Docker soit prêt
    for i in {1..10}; do
        docker info &>/dev/null && break || sleep 1
    done
    echo "✅ Docker installé"
fi

docker info &>/dev/null || error_exit "Docker non fonctionnel"

# Détection docker-compose
if docker compose version &>/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
elif command -v docker-compose &>/dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
else
    apt-get install -y docker-compose || error_exit "docker-compose non disponible"
    DOCKER_COMPOSE_CMD="docker-compose"
fi

# Configuration Artifact Registry si nécessaire
if echo "${docker_image}" | grep -q "docker.pkg.dev"; then
    echo "Configuration Artifact Registry..."
    ARTIFACT_REGISTRY_REGION=$(echo "${docker_image}" | sed -E 's|^([a-z][a-z0-9-]+)-docker\.pkg\.dev.*|\1|')
    
    if [ -n "$${ARTIFACT_REGISTRY_REGION}" ] && [ "$${ARTIFACT_REGISTRY_REGION}" != "${docker_image}" ]; then
        if ! command -v gcloud &>/dev/null; then
            echo "Installation de gcloud..."
            if [ ! -f /etc/apt/sources.list.d/google-cloud-sdk.list ]; then
                mkdir -p /usr/share/keyrings
                echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
                    tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null
                curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
                    gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg 2>/dev/null || \
                    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - 2>/dev/null || \
                    error_exit "Impossible d'ajouter la clé GPG"
                apt-get update -qq
            fi
            apt-get install -y google-cloud-sdk || error_exit "Échec installation gcloud"
        fi
        gcloud auth configure-docker "$${ARTIFACT_REGISTRY_REGION}-docker.pkg.dev" --quiet 2>&1 || true
        echo "✅ Artifact Registry configuré"
    fi
fi

# Configuration déploiement
echo "=========================================="
echo "Déploiement de l'API"
echo "=========================================="

DOCKER_IMAGE="${docker_image}"
CORS_ORIGINS="${cors_origins}"
MLFLOW_TRACKING_URI="${mlflow_tracking_uri}"
ENVIRONMENT="production"

%{ if secret_manager_api_key_name != "" ~}
echo "Récupération de l'API_KEY depuis Secret Manager..."
TMP_API_KEY_FILE=$(mktemp /tmp/api_key.XXXXXX)
chmod 600 "$TMP_API_KEY_FILE"
if retry_command "gcloud secrets versions access latest --secret='${secret_manager_api_key_name}' --project='${project_id}' > '$TMP_API_KEY_FILE' 2>&1"; then
    API_KEY=$(cat "$TMP_API_KEY_FILE")
    rm -f "$TMP_API_KEY_FILE"
    [ -z "$API_KEY" ] && error_exit "API_KEY vide"
    echo "✅ API_KEY récupérée"
else
    rm -f "$TMP_API_KEY_FILE"
    error_exit "Impossible de récupérer l'API_KEY. Vérifiez le secret '${secret_manager_api_key_name}' et les permissions IAM"
fi
%{ else ~}
echo "⚠️  API_KEY non configurée - mode développement uniquement"
API_KEY=""
%{ endif ~}

# Validations sécurité
[ -z "$DOCKER_IMAGE" ] && error_exit "DOCKER_IMAGE non définie"
[ -z "$API_KEY" ] && [ "$ENVIRONMENT" = "production" ] && error_exit "API_KEY requise en production"
[ -n "$API_KEY" ] && [ "$ENVIRONMENT" = "production" ] && [ $${#API_KEY} -lt 32 ] && \
    error_exit "API_KEY trop courte ($${#API_KEY} caractères). Minimum 32 requis"

if [ "$ENVIRONMENT" = "production" ]; then
    if [ -z "$CORS_ORIGINS" ]; then
        echo "⚠️  AVERTISSEMENT: CORS_ORIGINS vide - l'application utilisera '*' par défaut et échouera"
    elif echo "$CORS_ORIGINS" | grep -Fq '*'; then
        echo "⚠️  AVERTISSEMENT: CORS_ORIGINS contient '*' - l'application échouera au démarrage"
    fi
fi

# Préparation environnement
id "$APP_USER" &>/dev/null || useradd -r -s /bin/bash -d "$APP_DIR" -m "$APP_USER" || true
usermod -aG docker "$APP_USER" || true
usermod -aG docker root || true
mkdir -p "$APP_DIR"
chown "$APP_USER:$APP_USER" "$APP_DIR"

# Nettoyage conteneur existant
if docker ps -a --format '{{.Names}}' | grep -q "^iris-api$"; then
    echo "⚠️  Ancien conteneur détecté, suppression..."
    docker stop iris-api 2>/dev/null || true
    docker rm iris-api 2>/dev/null || true
fi

# Création fichiers de configuration
[ -f "$APP_DIR/docker-compose.yml" ] && cp "$APP_DIR/docker-compose.yml" "$APP_DIR/docker-compose.yml.bak"

cat > "$APP_DIR/docker-compose.yml" <<EOF
version: '3.8'
services:
  iris-api:
    image: $${DOCKER_IMAGE}
    container_name: iris-api
    restart: unless-stopped
    ports:
      - "0.0.0.0:8000:8000"
    environment:
      - API_KEY=$${API_KEY}
      - MODEL_DIR=/app/models
      - ENVIRONMENT=production
      - LOG_LEVEL=INFO
      - CORS_ORIGINS=$${CORS_ORIGINS:-}
      - MLFLOW_TRACKING_URI=$${MLFLOW_TRACKING_URI:-}
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

chmod 644 "$APP_DIR/docker-compose.yml"
chown "$APP_USER:$APP_USER" "$APP_DIR/docker-compose.yml"

# Pull image Docker
echo "Récupération de l'image Docker..."
VM_ARCH=$(uname -m)
case "$VM_ARCH" in
    x86_64) DOCKER_PLATFORM="linux/amd64" ;;
    aarch64|arm64) DOCKER_PLATFORM="linux/arm64" ;;
    *) DOCKER_PLATFORM="linux/amd64" ;;  # Par défaut pour GCP
esac
echo "Architecture: $VM_ARCH (plateforme: $DOCKER_PLATFORM)"

if ! retry_command "docker pull --platform $DOCKER_PLATFORM $DOCKER_IMAGE"; then
    echo "⚠️  Tentative sans spécifier la plateforme..."
    retry_command "docker pull $DOCKER_IMAGE" || {
        echo "❌ Échec pull image. Causes possibles:"
        echo "   1. Image inexistante ou inaccessible"
        echo "   2. Pas de manifeste pour $DOCKER_PLATFORM"
        echo "   3. Problème permissions IAM"
        echo ""
        echo "Solution: docker build --platform $DOCKER_PLATFORM -t $DOCKER_IMAGE . && docker push $DOCKER_IMAGE"
        error_exit "Impossible de récupérer l'image"
    }
fi

# Vérifier que l'image existe localement
docker image inspect "$DOCKER_IMAGE" &>/dev/null || error_exit "Image Docker non disponible localement après pull"
echo "✅ Image Docker récupérée"

# Service systemd
systemctl stop mlops-api.service 2>/dev/null || true
systemctl disable mlops-api.service 2>/dev/null || true
[ -f /etc/systemd/system/mlops-api.service ] && rm -f /etc/systemd/system/mlops-api.service && systemctl daemon-reload

cat > /etc/systemd/system/mlops-api.service <<EOF
[Unit]
Description=MLOps Iris API Service
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$${APP_DIR}
ExecStart=/bin/bash -c "cd $${APP_DIR} && $${DOCKER_COMPOSE_CMD} up -d --no-deps"
ExecStop=/bin/bash -c "cd $${APP_DIR} && $${DOCKER_COMPOSE_CMD} down"
ExecReload=/bin/bash -c "cd $${APP_DIR} && $${DOCKER_COMPOSE_CMD} restart"
User=$${APP_USER}
Group=$${APP_USER}
StandardOutput=journal
StandardError=journal
TimeoutStartSec=300
TimeoutStopSec=60

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable mlops-api.service

# Démarrage service
echo "Démarrage du service..."
if systemctl start mlops-api.service; then
    echo "✅ Service démarré"
    
    # Attente démarrage conteneur
    for i in {1..12}; do
        sleep 5
        docker ps --format '{{.Names}}' | grep -q "^iris-api$" && break
    done
    
    if docker ps --format '{{.Names}}' | grep -q "^iris-api$"; then
        echo "✅ Conteneur en cours d'exécution"
        sleep 10
        command -v curl &>/dev/null && curl -f -s http://localhost:8000/health &>/dev/null && \
            echo "✅ Healthcheck réussi" || echo "⚠️  Healthcheck échoué - vérifiez: docker logs iris-api"
    else
        echo "⚠️  Conteneur non démarré après 60s"
        echo "   Logs: journalctl -u mlops-api -n 50"
        docker ps -a --filter "name=iris-api" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || true
    fi
else
    echo "⚠️  Échec démarrage service - journalctl -u mlops-api -n 50"
fi

echo "=========================================="
echo "✅ Déploiement terminé"
echo "Commandes: systemctl {start|stop|restart|status} mlops-api"
echo "Logs: journalctl -u mlops-api -f | docker logs iris-api"
echo "=========================================="
