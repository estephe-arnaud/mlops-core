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
}

# Règle pour autoriser HTTP (pour l'API FastAPI)
resource "google_compute_firewall" "allow_http" {
  name    = "${var.network_name}-allow-http"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "8000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
  description   = "Autorise HTTP/HTTPS pour l'API"
}

# Règle pour autoriser le trafic interne
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.network_name}-allow-internal"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = ["10.0.1.0/24"]
  description   = "Autorise tout le trafic interne au sous-réseau"
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
resource "google_project_iam_member" "storage_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.api_service_account.email}"
}

# Rôle pour les opérations de base sur Compute Engine
resource "google_project_iam_member" "compute_instance_user" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.api_service_account.email}"
}

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

# ============================================================================
# BUCKET GCS POUR LES MODÈLES
# ============================================================================

resource "google_storage_bucket" "models_bucket" {
  name          = var.bucket_name != "" ? var.bucket_name : "${var.project_id}-ml-models"
  location      = var.region
  force_destroy = true # Permet la suppression même si le bucket contient des objets

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
    scopes = ["cloud-platform"] # Accès complet aux services GCP
  }

  metadata = {
    startup-script = <<-EOF
      #!/bin/bash
      # Script de démarrage pour installer Docker et l'API
      apt-get update
      apt-get install -y docker.io docker-compose
      systemctl start docker
      systemctl enable docker
      
      # Ajouter l'utilisateur au groupe docker
      usermod -aG docker $USER
      
      # Logs
      echo "VM démarrée avec succès" >> /var/log/startup.log
    EOF
  }

  labels = var.tags

  # Permet de redémarrer la VM même si elle est arrêtée
  allow_stopping_for_update = true
}
