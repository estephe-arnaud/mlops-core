# 🟢 Semaine 3 : Infrastructure as Code (Terraform)

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

## 📦 Livrables Créés

### Structure Terraform
```
terraform/
├── main.tf                    # Configuration principale (VPC, VM, Bucket, IAM)
├── variables.tf               # Variables d'entrée
├── outputs.tf                 # Valeurs de sortie
├── providers.tf               # Configuration des providers
├── terraform.tfvars.example   # Exemple de configuration
├── .gitignore                 # Fichiers à ignorer
└── README.md                  # Documentation complète
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

## ✅ Tâches Accomplies

### 1. 🏗️ Configuration Terraform
- ✅ Structure complète des fichiers Terraform
- ✅ Configuration du provider Google Cloud
- ✅ Gestion des variables et outputs
- ✅ Documentation complète

### 2. ☁️ Ressources GCP
- ✅ Bucket GCS avec versioning et lifecycle
- ✅ VM Compute Engine (e2-micro)
- ✅ Réseau VPC avec sous-réseau
- ✅ Règles de firewall (SSH, HTTP, interne)

### 3. 🔐 Gestion IAM
- ✅ Service Account dédié
- ✅ Rôles IAM configurés (Storage, Compute, Logging, Monitoring)
- ✅ Permissions sur le bucket GCS

### 4. 📚 Documentation
- ✅ README complet dans terraform/
- ✅ Exemple de configuration (terraform.tfvars.example)
- ✅ Commandes Makefile pour Terraform
- ✅ Documentation mise à jour

## 📈 Progression

### Phase 1 : Setup (6h) ✅
- [x] Installation de Terraform
- [x] Configuration GCP CLI
- [x] Création du projet GCP
- [x] Structure des fichiers Terraform

### Phase 2 : Infrastructure de Base (7h) ✅
- [x] Configuration du provider Google
- [x] Création du bucket GCS
- [x] Configuration du réseau VPC
- [x] Règles de firewall

### Phase 3 : VM et IAM (7h) ✅
- [x] Création de la VM Compute Engine
- [x] Configuration du service account
- [x] Attribution des rôles IAM
- [x] Script de démarrage avec Docker

## 🎯 Objectifs de Validation

- [x] `terraform init` s'exécute sans erreur
- [x] `terraform plan` montre les ressources à créer
- [x] `terraform apply` crée l'infrastructure
- [x] La VM est configurée avec Docker
- [x] Le bucket GCS est accessible
- [x] Les rôles IAM sont correctement configurés

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

## 🚀 Instructions de Démarrage

### Installation Rapide

```bash
# 1. Installer Terraform (si pas déjà fait)
brew install terraform  # macOS
# ou voir terraform/README.md pour autres OS

# 2. Configurer GCP
gcloud auth login
gcloud config set project votre-projet-id
gcloud services enable compute.googleapis.com
gcloud services enable storage-component.googleapis.com
gcloud services enable iam.googleapis.com

# 3. Configurer Terraform
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Éditer terraform.tfvars avec vos valeurs

# 4. Initialiser et appliquer
make terraform-init
make terraform-plan
make terraform-apply
```

### Vérification

```bash
# Voir les outputs
make terraform-output

# Valider la configuration
make terraform-validate

# Formater les fichiers
make terraform-fmt
```

## 🎓 Compétences Développées

### Terraform
- ✅ Syntaxe HCL (HashiCorp Configuration Language)
- ✅ Gestion des variables et outputs
- ✅ Providers et ressources GCP
- ✅ State management local

### Google Cloud Platform
- ✅ Compute Engine (VM)
- ✅ Cloud Storage (Bucket)
- ✅ VPC Networking
- ✅ IAM et Service Accounts
- ✅ Firewall Rules

### Infrastructure as Code
- ✅ Déclaration d'infrastructure
- ✅ Versioning de l'infrastructure
- ✅ Reproducibilité
- ✅ Documentation

## 📊 Métriques

| Métrique | Valeur |
|----------|--------|
| **Fichiers Terraform** | 7 |
| **Ressources créées** | 10+ |
| **Commandes Make** | 7 |
| **Documentation** | Complète |

## 🔗 Liens Utiles

- **Terraform README** : `terraform/README.md`
- **Commandes Make** : `make help` (section Terraform)
- **Documentation Terraform** : https://developer.hashicorp.com/terraform/docs
- **GCP Provider** : https://registry.terraform.io/providers/hashicorp/google/latest

## ✅ Validation des Objectifs

| Objectif | Status | Détails |
|----------|--------|---------|
| **Terraform Setup** | ✅ | Structure complète avec tous les fichiers |
| **Bucket GCS** | ✅ | Bucket avec versioning et lifecycle |
| **VM Compute Engine** | ✅ | VM e2-micro avec Docker pré-installé |
| **VPC Network** | ✅ | Réseau privé avec sous-réseau |
| **Firewall Rules** | ✅ | SSH, HTTP, et trafic interne |
| **IAM** | ✅ | Service Account avec rôles appropriés |
| **Documentation** | ✅ | README complet + commandes Make |

## 🚀 Prochaines Étapes (Semaine 4)

- 📊 MLflow pour le tracking des expériences
- 🔄 DVC pour le versioning des données
- 📈 Monitoring et observabilité

---

**🎉 Semaine 3 terminée avec succès !**

L'infrastructure Terraform est maintenant complètement configurée et prête pour le déploiement sur GCP.
