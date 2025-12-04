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
  count   = var.secret_manager_api_key_name != "" || var.create_secret_manager_secret ? 1 : 0
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.api_service_account.email}"
}

# ============================================================================
# SECRET MANAGER
# ============================================================================

# Création du secret Secret Manager via Terraform (si activé)
resource "google_secret_manager_secret" "api_key" {
  count     = var.create_secret_manager_secret ? 1 : 0
  secret_id = var.secret_manager_api_key_name != "" ? var.secret_manager_api_key_name : "mlops-api-key"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = var.tags
}

# Version du secret avec la valeur de l'API_KEY
resource "google_secret_manager_secret_version" "api_key" {
  count       = var.create_secret_manager_secret && var.api_key_value != "" ? 1 : 0
  secret      = google_secret_manager_secret.api_key[0].id
  secret_data = var.api_key_value
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

  # Chiffrement KMS (Customer-Managed Encryption Keys)
  dynamic "encryption" {
    for_each = var.enable_kms_encryption && var.kms_key_name != "" ? [1] : []
    content {
      default_kms_key_name = var.kms_key_name
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
    ], (var.secret_manager_api_key_name != "" || var.create_secret_manager_secret) ? [
      "https://www.googleapis.com/auth/cloud-platform"         # Secret Manager (nécessite cloud-platform pour les secrets)
    ] : [])
  }

  metadata = {
    startup-script = templatefile("${path.module}/../scripts/startup-script.sh.tpl", {
      bucket_name                 = google_storage_bucket.models_bucket.name
      docker_image                = var.docker_image
      secret_manager_api_key_name = var.create_secret_manager_secret ? (var.secret_manager_api_key_name != "" ? var.secret_manager_api_key_name : "mlops-api-key") : var.secret_manager_api_key_name
      project_id                  = var.project_id
      auto_deploy_api             = var.auto_deploy_api
    })
  }

  labels = var.tags

  # Permet de redémarrer la VM même si elle est arrêtée
  allow_stopping_for_update = true
}

# ============================================================================
# LOAD BALANCER ET CLOUD ARMOR
# ============================================================================

# Instance group pour le Load Balancer
resource "google_compute_instance_group" "api_instances" {
  count     = var.enable_load_balancer ? 1 : 0
  name      = "${var.vm_name}-ig"
  zone      = var.zone
  instances = [google_compute_instance.api_server.id]

  named_port {
    name = "http"
    port = 8000
  }
}

# Health check pour le Load Balancer
resource "google_compute_health_check" "api_health_check" {
  count   = var.enable_load_balancer ? 1 : 0
  name    = "${var.vm_name}-health-check"
  project = var.project_id

  http_health_check {
    port         = 8000
    request_path = "/health"
  }

  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
}

# Backend service
resource "google_compute_backend_service" "api_backend" {
  count         = var.enable_load_balancer ? 1 : 0
  name          = "${var.vm_name}-backend"
  project       = var.project_id
  protocol      = "HTTP"
  port_name     = "http"
  timeout_sec   = 30
  health_checks = [google_compute_health_check.api_health_check[0].id]

  backend {
    group                 = google_compute_instance_group.api_instances[0].id
    balancing_mode        = "UTILIZATION"
    capacity_scaler      = 1.0
    max_utilization      = 0.8
  }

  # Cloud Armor security policy (si activé)
  security_policy = var.enable_load_balancer && var.enable_cloud_armor ? google_compute_security_policy.cloud_armor_policy[0].id : null
}

# Cloud Armor Security Policy
resource "google_compute_security_policy" "cloud_armor_policy" {
  count   = var.enable_load_balancer && var.enable_cloud_armor ? 1 : 0
  name    = "${var.vm_name}-armor-policy"
  project = var.project_id

  # Règle par défaut : autoriser tout (peut être restreint)
  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Règle par défaut : autoriser tout le trafic"
  }

  # Règle pour bloquer les IPs suspectes (exemple)
  # rule {
  #   action   = "deny(403)"
  #   priority = "1000"
  #   match {
  #     versioned_expr = "SRC_IPS_V1"
  #     config {
  #       src_ip_ranges = ["1.2.3.4/32"]  # IPs à bloquer
  #     }
  #   }
  #   description = "Bloquer les IPs suspectes"
  # }
}

# URL Map
resource "google_compute_url_map" "api_url_map" {
  count           = var.enable_load_balancer ? 1 : 0
  name            = "${var.vm_name}-url-map"
  project         = var.project_id
  default_service = google_compute_backend_service.api_backend[0].id
}

# Target HTTP Proxy
resource "google_compute_target_http_proxy" "api_proxy" {
  count   = var.enable_load_balancer ? 1 : 0
  name    = "${var.vm_name}-http-proxy"
  project = var.project_id
  url_map = google_compute_url_map.api_url_map[0].id
}

# Forwarding Rule (IP publique du Load Balancer)
resource "google_compute_global_forwarding_rule" "api_forwarding_rule" {
  count     = var.enable_load_balancer ? 1 : 0
  name      = var.load_balancer_name
  project   = var.project_id
  target    = google_compute_target_http_proxy.api_proxy[0].id
  port_range = "80"
  ip_protocol = "TCP"
}

# Firewall rule pour autoriser le trafic du Load Balancer vers la VM
resource "google_compute_firewall" "allow_lb_to_vm" {
  count   = var.enable_load_balancer ? 1 : 0
  name    = "${var.network_name}-allow-lb"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["8000"]
  }

  # IPs des Load Balancers GCP
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["http-server"]
  description   = "Autorise le trafic des Load Balancers GCP vers la VM"
  
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# ============================================================================
# MONITORING ET ALERTES
# ============================================================================

# Notification Channel (email) - créé si des emails sont fournis
resource "google_monitoring_notification_channel" "email" {
  for_each     = var.enable_monitoring_alerts ? toset([for email in var.notification_channels : email if length(email) > 6 && substr(email, 0, 6) == "email:"]) : toset([])
  display_name = "Email Alert Channel - ${replace(each.value, "email:", "")}"
  type         = "email"
  project      = var.project_id

  labels = {
    email_address = replace(each.value, "email:", "")
  }
}

# Alerte : CPU élevé
resource "google_monitoring_alert_policy" "high_cpu" {
  count        = var.enable_monitoring_alerts ? 1 : 0
  display_name = "High CPU Usage - ${var.vm_name}"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "CPU usage > 80%"

    condition_threshold {
      filter          = "resource.type = \"gce_instance\" AND resource.labels.instance_id = \"${google_compute_instance.api_server.instance_id}\" AND metric.type = \"compute.googleapis.com/instance/cpu/utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [for nc in google_monitoring_notification_channel.email : nc.id]

  alert_strategy {
    auto_close = "1800s"
  }
}

# Alerte : Mémoire élevée
# Note: Désactivée car GCP n'a pas de métrique directe pour le pourcentage de mémoire
# Pour activer, il faudrait utiliser compute.googleapis.com/instance/memory/balloon/ram_used
# avec un calcul de ratio (ram_used / ram_size), ce qui nécessite une configuration plus complexe
resource "google_monitoring_alert_policy" "high_memory" {
  count        = 0  # Désactivé - métrique de pourcentage non disponible directement
  display_name = "High Memory Usage - ${var.vm_name}"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Memory usage > 85%"

    condition_threshold {
      filter          = "resource.type = \"gce_instance\" AND resource.labels.instance_id = \"${google_compute_instance.api_server.instance_id}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.85

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [for nc in google_monitoring_notification_channel.email : nc.id]

  alert_strategy {
    auto_close = "1800s"
  }
}

# Alerte : Instance down (utilise l'uptime check ou la métrique d'uptime)
resource "google_monitoring_alert_policy" "instance_down" {
  count        = var.enable_monitoring_alerts ? 1 : 0
  display_name = "Instance Down - ${var.vm_name}"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Instance is down"

    condition_threshold {
      # Utilise la métrique uptime pour détecter si l'instance est down
      filter          = "resource.type = \"gce_instance\" AND resource.labels.instance_id = \"${google_compute_instance.api_server.instance_id}\" AND metric.type = \"compute.googleapis.com/instance/uptime\""
      duration        = "300s"
      comparison      = "COMPARISON_LT"
      threshold_value = 1

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [for nc in google_monitoring_notification_channel.email : nc.id]

  alert_strategy {
    auto_close = "3600s"
  }
}
