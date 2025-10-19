# 🟡 Semaine 3 : Infrastructure as Code (Terraform)

## 🎯 Objectif de la Semaine

**Provisionner une infrastructure cloud simple sur GCP via Terraform**

### ❓ Questions Clés
- Qu'est-ce que l'IaC et comment structurer un projet Terraform ?
- Comment provisionner des ressources de base (bucket, VM) ?
- Comment gérer les rôles IAM ?

### ⏱️ Répartition des Heures (20h)
- **6h** → Apprentissage des bases de Terraform (HCL, variables, state local)
- **7h** → Écrire le code pour provisionner un bucket GCS et une petite VM GCP
- **7h** → Gérer les IAM (comptes de service) pour l'accès aux ressources

## 📋 Tâches à Accomplir

### 1. 🏗️ Configuration Terraform
- Installer et configurer Terraform
- Comprendre la syntaxe HCL
- Gérer les variables et le state local

### 2. ☁️ Ressources GCP
- Créer un bucket Google Cloud Storage
- Provisionner une VM Compute Engine
- Configurer les réseaux et firewall

### 3. 🔐 Gestion IAM
- Créer des comptes de service
- Définir les rôles et permissions
- Sécuriser l'accès aux ressources

### 4. 📚 Documentation
- Documenter l'architecture
- Créer des schémas d'infrastructure
- Rédiger les procédures de déploiement

## 📦 Livrables Attendus

### Structure Terraform
```
terraform/
├── main.tf              # Configuration principale
├── variables.tf         # Variables d'entrée
├── outputs.tf          # Valeurs de sortie
├── terraform.tfvars    # Valeurs des variables
├── providers.tf        # Configuration des providers
└── README.md           # Documentation
```

### Ressources à Créer
- **Bucket GCS** : Stockage des modèles et données
- **VM Compute Engine** : Instance pour déploiement
- **VPC Network** : Réseau privé
- **Firewall Rules** : Règles de sécurité
- **Service Account** : Compte de service pour l'API

## 🚀 Architecture Prévue

```hcl
# main.tf (exemple)
provider "google" {
  project = var.project_id
  region  = var.region
}

# Bucket GCS pour les modèles
resource "google_storage_bucket" "models" {
  name          = "${var.project_id}-ml-models"
  location      = var.region
  force_destroy = true
}

# VM pour l'API
resource "google_compute_instance" "api_server" {
  name         = "iris-api-server"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {}
  }

  service_account {
    email  = google_service_account.api_sa.email
    scopes = ["cloud-platform"]
  }
}
```

## 🛠️ Outils à Utiliser

### Terraform
- **Version** : >= 1.0
- **Provider** : Google Cloud Platform
- **State** : Local (puis remote en production)

### Google Cloud Platform
- **Services** : Compute Engine, Cloud Storage, IAM
- **Région** : europe-west1 (ou autre)
- **Zone** : europe-west1-a

### Gestion des Secrets
- **Variables** : terraform.tfvars
- **Secrets** : Google Secret Manager (optionnel)

## 📊 Métriques Attendues

| Ressource | Configuration |
|-----------|---------------|
| **VM** | e2-micro (1 vCPU, 1GB RAM) |
| **Storage** | 10GB SSD |
| **Bucket** | Standard storage class |
| **Network** | VPC avec firewall |

## 🔗 Ressources

- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [Google Cloud Provider](https://registry.terraform.io/providers/hashicorp/google/latest)
- [GCP Free Tier](https://cloud.google.com/free)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/)

## 📈 Progression

### Phase 1 : Setup (6h)
- [ ] Installation de Terraform
- [ ] Configuration GCP CLI
- [ ] Création du projet GCP
- [ ] Structure des fichiers Terraform

### Phase 2 : Infrastructure de Base (7h)
- [ ] Configuration du provider Google
- [ ] Création du bucket GCS
- [ ] Configuration du réseau VPC
- [ ] Règles de firewall

### Phase 3 : VM et IAM (7h)
- [ ] Création de la VM Compute Engine
- [ ] Configuration du service account
- [ ] Attribution des rôles IAM
- [ ] Test de connexion

## 🎯 Objectifs de Validation

- [ ] `terraform init` s'exécute sans erreur
- [ ] `terraform plan` montre les ressources à créer
- [ ] `terraform apply` crée l'infrastructure
- [ ] La VM est accessible via SSH
- [ ] Le bucket GCS est accessible
- [ ] Les rôles IAM sont correctement configurés

## 🔐 Sécurité

### Bonnes Pratiques
- Utiliser des variables pour les valeurs sensibles
- Limiter les permissions IAM au minimum
- Activer les logs d'audit
- Utiliser des clés de service avec rotation

### Rôles IAM Nécessaires
- **Storage Admin** : Pour le bucket GCS
- **Compute Instance Admin** : Pour la VM
- **Service Account User** : Pour l'API

## 🚀 Prochaines Étapes (Semaine 4)

- 📊 MLflow pour le tracking des expériences
- 🔄 DVC pour le versioning des données
- 📈 Monitoring et observabilité

## 📚 Documentation à Créer

### Schémas d'Architecture
- Diagramme de l'infrastructure
- Flux de données
- Architecture de sécurité

### Procédures
- Déploiement de l'infrastructure
- Mise à jour des ressources
- Désactivation/destruction

---

**🔄 Semaine 3 en cours de planification**

Cette semaine se concentre sur l'infrastructure as Code et la préparation de l'environnement cloud.
