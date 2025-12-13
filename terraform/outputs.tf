output "project_id" {
  description = "ID du projet GCP"
  value       = var.project_id
}

output "bucket_name" {
  description = "Nom du bucket GCS pour les modèles"
  value       = google_storage_bucket.models_bucket.name
  sensitive   = false
}

output "bucket_url" {
  description = "URL du bucket GCS"
  value       = "gs://${google_storage_bucket.models_bucket.name}"
}

output "mlflow_tracking_uri" {
  description = "URI MLflow Tracking configuré automatiquement"
  value       = var.mlflow_tracking_uri != "" ? var.mlflow_tracking_uri : "gs://${google_storage_bucket.models_bucket.name}/mlruns/"
}

output "vm_name" {
  description = "Nom de la VM"
  value       = google_compute_instance.api_server.name
}

output "vm_zone" {
  description = "Zone de la VM"
  value       = google_compute_instance.api_server.zone
}

output "vm_external_ip" {
  description = "IP publique de la VM (si activée)"
  value       = var.enable_public_ip ? google_compute_instance.api_server.network_interface[0].access_config[0].nat_ip : "Non configurée"
}

output "vm_internal_ip" {
  description = "IP interne de la VM"
  value       = google_compute_instance.api_server.network_interface[0].network_ip
}

output "vm_ssh_command" {
  description = "Commande SSH pour se connecter à la VM"
  value       = "gcloud compute ssh ${google_compute_instance.api_server.name} --zone=${google_compute_instance.api_server.zone} --project=${var.project_id}"
}

output "service_account_email" {
  description = "Email du compte de service"
  value       = google_service_account.api_service_account.email
}

output "service_account_id" {
  description = "ID du compte de service"
  value       = google_service_account.api_service_account.id
}

output "network_name" {
  description = "Nom du réseau VPC"
  value       = google_compute_network.vpc_network.name
}

output "subnetwork_name" {
  description = "Nom du sous-réseau"
  value       = google_compute_subnetwork.vpc_subnet.name
}

output "region" {
  description = "Région des ressources"
  value       = var.region
}

output "zone" {
  description = "Zone des ressources"
  value       = var.zone
}

# ============================================================================
# SECRET MANAGER OUTPUTS
# ============================================================================

output "secret_manager_secret_name" {
  description = "Nom du secret Secret Manager créé"
  value       = var.create_secret_manager_secret ? (var.secret_manager_api_key_name != "" ? var.secret_manager_api_key_name : "mlops-api-key") : null
  sensitive   = false
}

# ============================================================================
# LOAD BALANCER OUTPUTS
# ============================================================================

output "load_balancer_ip" {
  description = "IP publique du Load Balancer (si activé)"
  value       = var.enable_load_balancer ? google_compute_global_forwarding_rule.api_forwarding_rule[0].ip_address : null
}

output "load_balancer_url" {
  description = "URL du Load Balancer (si activé)"
  value       = var.enable_load_balancer ? "http://${google_compute_global_forwarding_rule.api_forwarding_rule[0].ip_address}" : null
}

# ============================================================================
# MONITORING OUTPUTS
# ============================================================================

output "monitoring_enabled" {
  description = "Indique si le monitoring est activé"
  value       = var.enable_monitoring_alerts
}
