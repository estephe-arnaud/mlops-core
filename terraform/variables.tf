variable "project_id" {
  description = "ID du projet GCP"
  type        = string
}

variable "region" {
  description = "Région GCP pour les ressources"
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  description = "Zone GCP pour la VM"
  type        = string
  default     = "europe-west1-a"
}

variable "bucket_name" {
  description = "Nom du bucket GCS pour les modèles ML"
  type        = string
  default     = ""
}

variable "vm_name" {
  description = "Nom de la VM Compute Engine"
  type        = string
  default     = "iris-api-server"
}

variable "machine_type" {
  description = "Type de machine pour la VM"
  type        = string
  default     = "e2-micro"
}

variable "vm_image" {
  description = "Image OS pour la VM"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "disk_size_gb" {
  description = "Taille du disque en GB"
  type        = number
  default     = 10
}

variable "network_name" {
  description = "Nom du réseau VPC"
  type        = string
  default     = "mlops-vpc"
}

variable "service_account_name" {
  description = "Nom du compte de service"
  type        = string
  default     = "mlops-api-sa"
}

variable "enable_public_ip" {
  description = "Activer une IP publique pour la VM. ⚠️ SÉCURITÉ : Désactivé par défaut. Activez uniquement si nécessaire et utilisez un Load Balancer en production."
  type        = bool
  default     = false # ⚠️ SÉCURITÉ : Désactivé par défaut pour réduire la surface d'attaque
}

variable "allowed_ssh_ips" {
  description = "Liste des IPs autorisées pour SSH (CIDR). ⚠️ SÉCURITÉ CRITIQUE : Cette variable DOIT être configurée explicitement dans terraform.tfvars. Ne laissez JAMAIS la valeur par défaut en production !"
  type        = list(string)
  default     = [] # ⚠️ SÉCURITÉ : Liste vide par défaut (deny by default). Configurez explicitement dans terraform.tfvars avec vos IPs autorisées (ex: ["123.45.67.89/32"])
}

variable "allowed_http_ips" {
  description = "Liste des IPs autorisées pour HTTP/HTTPS (CIDR). ⚠️ SÉCURITÉ CRITIQUE : Cette variable DOIT être configurée explicitement dans terraform.tfvars. Liste vide par défaut (deny by default). Pour une API publique, utilisez un Load Balancer avec Cloud Armor plutôt que d'exposer directement la VM."
  type        = list(string)
  default     = [] # ⚠️ SÉCURITÉ : Liste vide par défaut (deny by default). Configurez explicitement dans terraform.tfvars. Ne JAMAIS utiliser ["0.0.0.0/0"] en production sans protection (Load Balancer + WAF).
}

variable "force_destroy_bucket" {
  description = "Permet la suppression du bucket même s'il contient des objets. ⚠️ DANGEREUX en production - peut causer une perte irréversible de données. Utilisez false en production."
  type        = bool
  default     = false # ⚠️ SÉCURITÉ : Désactivé par défaut pour protéger les données
}

variable "tags" {
  description = "Tags pour les ressources"
  type        = map(string)
  default = {
    project     = "mlops"
    environment = "dev"
    managed_by  = "terraform"
  }
}

variable "docker_image" {
  description = "Image Docker complète pour l'API (ex: gcr.io/PROJECT-ID/iris-api:latest ou docker.io/USER/iris-api:latest)"
  type        = string
  default     = "iris-api:latest"
}

variable "secret_manager_api_key_name" {
  description = "Nom du secret dans Secret Manager pour l'API_KEY. Si vide, l'API_KEY doit être fournie via métadonnées VM (non recommandé)."
  type        = string
  default     = ""
}

variable "auto_deploy_api" {
  description = "Déployer automatiquement l'API au démarrage de la VM via le startup-script"
  type        = bool
  default     = true
}

variable "cors_origins" {
  description = "Origines CORS autorisées (séparées par des virgules). ⚠️ SÉCURITÉ : En production, ne pas utiliser '*'. Exemple : 'https://example.com,https://app.example.com'. Pour dev local : '*' (recommandé)"
  type        = string
  default     = "*"  # Valeur par défaut pour développement local (plus flexible)
}

# ============================================================================
# SECRET MANAGER
# ============================================================================

variable "create_secret_manager_secret" {
  description = "Créer le secret Secret Manager via Terraform. Si true, api_key_value doit être fourni (via variable ou data source)."
  type        = bool
  default     = false
}

variable "api_key_value" {
  description = "Valeur de l'API_KEY pour créer le secret dans Secret Manager. ⚠️ SENSIBLE : Ne pas commiter dans terraform.tfvars. Utilisez une variable d'environnement ou un fichier séparé."
  type        = string
  default     = ""
  sensitive   = true
}

# ============================================================================
# KMS (Key Management Service)
# ============================================================================

variable "enable_kms_encryption" {
  description = "Activer le chiffrement KMS pour le bucket GCS. Si true, kms_key_name doit être configuré."
  type        = bool
  default     = false
}

variable "kms_key_name" {
  description = "Nom complet de la clé KMS pour chiffrer le bucket (ex: projects/PROJECT/locations/LOCATION/keyRings/RING/cryptoKeys/KEY). Nécessite enable_kms_encryption = true."
  type        = string
  default     = ""
}

# ============================================================================
# LOAD BALANCER
# ============================================================================

variable "enable_load_balancer" {
  description = "Activer un Load Balancer HTTP(S) pour l'API. Recommandé en production pour remplacer l'IP publique directe."
  type        = bool
  default     = false
}

variable "load_balancer_name" {
  description = "Nom du Load Balancer"
  type        = string
  default     = "mlops-api-lb"
}

variable "enable_cloud_armor" {
  description = "Activer Cloud Armor pour protection DDoS sur le Load Balancer. Nécessite enable_load_balancer = true."
  type        = bool
  default     = false
}

# ============================================================================
# MONITORING
# ============================================================================

variable "enable_monitoring_alerts" {
  description = "Activer les alertes Cloud Monitoring pour la VM. ✅ Recommandé en production."
  type        = bool
  default     = true  # ⚠️ Activé par défaut pour production-ready
}

variable "notification_channels" {
  description = "Liste des canaux de notification pour les alertes (ex: emails). Format: [\"email:admin@example.com\"]"
  type        = list(string)
  default     = []
}
