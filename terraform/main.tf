# ============================================================================
# RÉSEAU VPC
# ============================================================================

resource "google_compute_network" "vpc_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
  description             = "Réseau VPC pour l'infrastructure MLOps"
}

resource "google_compute_subnetwork" "vpc_subnet" {
  name          = "${var.network_name}-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
  description   = "Sous-réseau pour les ressources MLOps"
}

# ============================================================================
# FIREWALL RULES
# ============================================================================

# Règle pour autoriser SSH
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.network_name}-allow-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ssh_ips
  target_tags   = ["ssh-allowed"]
  description   = "Autorise SSH depuis les IPs spécifiées"
  
  # Activation du logging pour audit de sécurité
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Règle pour autoriser HTTP (pour l'API FastAPI)
# ⚠️ SÉCURITÉ : Utilise la variable allowed_http_ips pour contrôler l'accès
# ⚠️ SÉCURITÉ CRITIQUE : allowed_http_ips doit être configuré explicitement (liste vide par défaut)
resource "google_compute_firewall" "allow_http" {
  name    = "${var.network_name}-allow-http"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "8000"]
  }

  source_ranges = var.allowed_http_ips
  target_tags   = ["http-server"]
  description   = "Autorise HTTP/HTTPS pour l'API depuis les IPs configurées. ⚠️ Configurez allowed_http_ips dans terraform.tfvars"
  
  # Activation du logging pour audit de sécurité
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Règle pour autoriser le trafic interne (restreinte aux ports nécessaires)
# ⚠️ SÉCURITÉ : Principe du moindre privilège - uniquement les ports nécessaires
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.network_name}-allow-internal"
  network = google_compute_network.vpc_network.name

  # ICMP pour ping (utile pour le diagnostic réseau)
  allow {
    protocol = "icmp"
  }

  # TCP : Ports spécifiques uniquement (API et SSH)
  allow {
    protocol = "tcp"
    ports    = ["8000", "22"] # API FastAPI (8000) et SSH (22)
  }

  # UDP : Pas de ports UDP nécessaires pour cette infrastructure
  # Si nécessaire, ajoutez des ports spécifiques ici

  source_ranges = ["10.0.1.0/24"]
  description   = "Autorise le trafic interne restreint (ports 8000, 22, ICMP uniquement)"
  
  # Activation du logging pour audit de sécurité
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# ============================================================================
# SERVICE ACCOUNT ET IAM
# ============================================================================

resource "google_service_account" "api_service_account" {
  account_id   = var.service_account_name
  display_name = "Service Account pour l'API MLOps"
  description  = "Compte de service utilisé par la VM pour accéder aux ressources GCP"
}

# Rôle pour accéder au bucket GCS
# ⚠️ SÉCURITÉ : Utilise storage.objectAdmin (lecture/écriture) au lieu de storage.admin (gestion complète)
resource "google_project_iam_member" "storage_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.api_service_account.email}"
}

# ⚠️ SÉCURITÉ : Rôle compute.instanceAdmin.v1 supprimé car non nécessaire pour une VM simple
# La VM n'a pas besoin de gérer d'autres instances. Si nécessaire, utilisez un rôle plus restrictif.

# Rôle pour les logs
resource "google_project_iam_member" "logging_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.api_service_account.email}"
}

# Rôle pour le monitoring
resource "google_project_iam_member" "monitoring_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.api_service_account.email}"
}

# Rôle pour Secret Manager (accès aux secrets)
# ⚠️ SÉCURITÉ : Ajouté conditionnellement si secret_manager_api_key_name est configuré
resource "google_project_iam_member" "secret_manager_accessor" {
  count   = var.secret_manager_api_key_name != "" ? 1 : 0
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.api_service_account.email}"
}

# ============================================================================
# BUCKET GCS POUR LES MODÈLES
# ============================================================================

resource "google_storage_bucket" "models_bucket" {
  name          = var.bucket_name != "" ? var.bucket_name : "${var.project_id}-ml-models"
  location      = var.region
  force_destroy = var.force_destroy_bucket # ⚠️ SÉCURITÉ : Configurable via variable (false par défaut)

  uniform_bucket_level_access = true

  versioning {
    enabled = true # Active le versioning pour les modèles
  }

  lifecycle_rule {
    condition {
      age = 365 # Supprime les objets après 1 an
    }
    action {
      type = "Delete"
    }
  }

  labels = var.tags
}

# IAM pour le bucket : accès en lecture/écriture pour le service account
resource "google_storage_bucket_iam_member" "bucket_sa_access" {
  bucket = google_storage_bucket.models_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.api_service_account.email}"
}

# ============================================================================
# VM COMPUTE ENGINE
# ============================================================================

resource "google_compute_instance" "api_server" {
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["http-server", "ssh-allowed"]

  boot_disk {
    initialize_params {
      image = var.vm_image
      size  = var.disk_size_gb
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.vpc_subnet.name

    # IP publique (optionnelle)
    dynamic "access_config" {
      for_each = var.enable_public_ip ? [1] : []
      content {
        # Éphemère IP publique
      }
    }
  }

  service_account {
    email  = google_service_account.api_service_account.email
    # ⚠️ SÉCURITÉ : Scopes spécifiques au lieu de "cloud-platform" (accès complet)
    # cloud-platform donne accès à TOUS les services GCP - trop large !
    scopes = concat([
      "https://www.googleapis.com/auth/devstorage.read_write", # GCS (lecture/écriture)
      "https://www.googleapis.com/auth/logging.write",         # Logs
      "https://www.googleapis.com/auth/monitoring.write"       # Monitoring
    ], var.secret_manager_api_key_name != "" ? [
      "https://www.googleapis.com/auth/cloud-platform"         # Secret Manager (nécessite cloud-platform pour les secrets)
    ] : [])
  }

  metadata = {
    startup-script = templatefile("${path.root}/scripts/startup-script.sh.tpl", {
      bucket_name                 = google_storage_bucket.models_bucket.name
      docker_image                = var.docker_image
      secret_manager_api_key_name = var.secret_manager_api_key_name
      project_id                  = var.project_id
      auto_deploy_api             = var.auto_deploy_api
    })
  }

  labels = var.tags

  # Permet de redémarrer la VM même si elle est arrêtée
  allow_stopping_for_update = true
}
