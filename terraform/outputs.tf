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
