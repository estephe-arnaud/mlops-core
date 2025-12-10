#!/bin/bash
# Script de démarrage automatique pour la VM MLOps
# Généré par Terraform - Ne pas modifier manuellement

set -euo pipefail

# Configuration
LOG_FILE="/var/log/startup.log"
DEPLOY_SCRIPT_URL="gs://${bucket_name}/scripts/deploy-api.sh"
DEPLOY_SCRIPT_PATH="/tmp/deploy-api.sh"

# Logging
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=========================================="
echo "Démarrage de la VM MLOps"
echo "Date: $(date)"
echo "=========================================="

# Mise à jour du système
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

# Si auto_deploy_api est activé, télécharger et exécuter le script de déploiement
%{ if auto_deploy_api ~}
echo "=========================================="
echo "Déploiement automatique de l'API"
echo "=========================================="

# Exporter les variables d'environnement
export MODEL_BUCKET="${bucket_name}"
export DOCKER_IMAGE="${docker_image}"

%{ if secret_manager_api_key_name != "" ~}
# Récupérer l'API_KEY depuis Secret Manager
echo "Récupération de l'API_KEY depuis Secret Manager: ${secret_manager_api_key_name}"
export API_KEY=$(gcloud secrets versions access latest --secret="${secret_manager_api_key_name}" --project="${project_id}" 2>/dev/null || echo "")
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
export API_KEY=""
%{ endif ~}

# Télécharger le script de déploiement depuis GCS
echo "Téléchargement du script de déploiement depuis GCS..."
if command -v gcloud &> /dev/null; then
    gcloud storage cp "$DEPLOY_SCRIPT_URL" "$DEPLOY_SCRIPT_PATH" || {
        echo "⚠️  Impossible de télécharger le script depuis GCS. Tentative d'inclusion inline..."
        # Si le script n'est pas dans GCS, on peut le créer inline (fallback)
        # Pour l'instant, on échoue proprement
        echo "❌ Le script deploy-api.sh doit être uploadé dans gs://${bucket_name}/scripts/"
        echo "   Vous pouvez l'uploader avec: gcloud storage cp scripts/deploy-api.sh $DEPLOY_SCRIPT_URL"
        exit 1
    }
else
    echo "❌ gcloud non disponible. Impossible de télécharger le script de déploiement."
    exit 1
fi

# Rendre le script exécutable
chmod +x "$DEPLOY_SCRIPT_PATH"

# Exécuter le script de déploiement
echo "Exécution du script de déploiement..."
bash "$DEPLOY_SCRIPT_PATH"

echo "✅ Déploiement automatique terminé"
%{ else ~}
echo "ℹ️  Déploiement automatique désactivé (auto_deploy_api=false)"
echo "   Vous pouvez déployer manuellement l'API plus tard"
%{ endif ~}

echo "=========================================="
echo "Démarrage de la VM terminé"
echo "Date: $(date)"
echo "=========================================="

