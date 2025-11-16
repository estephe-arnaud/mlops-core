# 🏗️ Infrastructure as Code - Terraform

Ce répertoire contient la configuration Terraform pour provisionner l'infrastructure GCP du projet MLOps.

## 📋 Vue d'Ensemble

Cette infrastructure provisionne :
- **Bucket GCS** : Stockage des modèles ML et données
- **VM Compute Engine** : Instance pour déployer l'API FastAPI
- **VPC Network** : Réseau privé avec sous-réseau
- **Firewall Rules** : Règles de sécurité (SSH, HTTP)
- **Service Account** : Compte de service avec permissions IAM

## 🚀 Prérequis

### 1. Installer Terraform

```bash
# macOS
brew install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Vérifier l'installation
terraform version
```

### 2. Installer Google Cloud SDK

```bash
# macOS
brew install google-cloud-sdk

# Linux
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Vérifier l'installation
gcloud version
```

### 3. Configurer GCP

```bash
# Se connecter à GCP
gcloud auth login

# Créer un projet GCP (ou utiliser un existant)
gcloud projects create votre-projet-id --name="MLOps Project"

# Sélectionner le projet
gcloud config set project votre-projet-id

# Activer les APIs nécessaires
gcloud services enable compute.googleapis.com
gcloud services enable storage-component.googleapis.com
gcloud services enable iam.googleapis.com
```

## 📁 Structure des Fichiers

```
terraform/
├── main.tf                 # Ressources principales (VPC, VM, Bucket, IAM)
├── variables.tf            # Variables d'entrée
├── outputs.tf              # Valeurs de sortie
├── providers.tf            # Configuration des providers
├── terraform.tfvars.example # Exemple de configuration
├── .gitignore              # Fichiers à ignorer
└── README.md               # Cette documentation
```

## ⚙️ Configuration

### 1. Créer le fichier de configuration

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

### 2. Éditer `terraform.tfvars`

Ouvrez `terraform.tfvars` et remplissez les valeurs :

```hcl
project_id = "votre-projet-gcp-id"
region     = "europe-west1"
zone       = "europe-west1-a"
```

⚠️ **Important** : Ne commitez JAMAIS `terraform.tfvars` (il est dans `.gitignore`)

## 🚀 Utilisation

### Initialisation

```bash
# Initialiser Terraform (télécharge les providers)
terraform init
```

### Planification

```bash
# Voir ce qui sera créé (sans créer)
terraform plan
```

### Application

```bash
# Créer l'infrastructure
terraform apply

# Confirmer avec "yes" quand demandé
```

### Vérification

```bash
# Voir les outputs
terraform output

# Voir les outputs spécifiques
terraform output vm_external_ip
terraform output bucket_name
```

### Destruction

```bash
# ⚠️  Supprime TOUTES les ressources créées
terraform destroy
```

## 📊 Ressources Créées

### Bucket GCS
- **Nom** : `{project_id}-ml-models` (ou personnalisé)
- **Région** : Configurée dans `terraform.tfvars`
- **Versioning** : Activé
- **Lifecycle** : Suppression après 365 jours

### VM Compute Engine
- **Type** : e2-micro (free tier)
- **OS** : Ubuntu 22.04 LTS
- **Disque** : 10GB SSD
- **IP** : Publique (si activée)
- **Script de démarrage** : Installe Docker automatiquement

### VPC Network
- **Réseau** : `mlops-vpc`
- **Sous-réseau** : `10.0.1.0/24`
- **Région** : Configurée dans `terraform.tfvars`

### Firewall Rules
- **SSH** : Port 22 (IPs configurées)
- **HTTP** : Ports 80, 8000 (0.0.0.0/0)
- **Interne** : Tout le trafic dans le sous-réseau

### Service Account
- **Nom** : `mlops-api-sa`
- **Rôles** :
  - `storage.objectAdmin` : Accès au bucket
  - `compute.instanceAdmin.v1` : Gestion des instances
  - `logging.logWriter` : Écriture des logs
  - `monitoring.metricWriter` : Métriques

## 🔐 Sécurité

### Bonnes Pratiques

1. **Restreindre SSH** : Modifiez `allowed_ssh_ips` dans `terraform.tfvars` pour limiter l'accès SSH
2. **IP Publique** : Désactivez `enable_public_ip` si vous n'en avez pas besoin
3. **IAM** : Utilisez le principe du moindre privilège
4. **Secrets** : Ne commitez jamais `terraform.tfvars`

### Recommandations Production

- Utiliser un backend distant pour le state (GCS, S3)
- Activer les logs d'audit GCP
- Utiliser des clés de service avec rotation
- Implémenter des politiques de sécurité strictes
- Utiliser Cloud Armor pour la protection DDoS

## 📝 Commandes Utiles

```bash
# Voir l'état actuel
terraform show

# Rafraîchir l'état
terraform refresh

# Valider la configuration
terraform validate

# Formater les fichiers
terraform fmt

# Voir les outputs
terraform output -json
```

## 🔗 Connexion à la VM

### Via gcloud

```bash
# Utiliser la commande générée par Terraform
terraform output vm_ssh_command

# Ou directement
gcloud compute ssh iris-api-server \
  --zone=europe-west1-a \
  --project=votre-projet-id
```

## 🐳 Déploiement de l'API sur la VM

Une fois la VM créée, vous pouvez déployer l'API :

```bash
# Se connecter à la VM
gcloud compute ssh iris-api-server --zone=europe-west1-a

# Sur la VM, cloner le projet
git clone https://github.com/votre-repo/mlops-core.git
cd mlops-core

# Installer Docker (déjà fait par le startup script)
# Build l'image
docker build -t iris-api .

# Lancer le conteneur
docker run -d -p 8000:8000 --name iris-api iris-api

# Vérifier que l'API fonctionne
curl http://localhost:8000/health
```

## 🐛 Dépannage

### Erreur : "API not enabled"

```bash
# Activer les APIs nécessaires
gcloud services enable compute.googleapis.com
gcloud services enable storage-component.googleapis.com
```

### Erreur : "Bucket name already exists"

Le nom du bucket doit être unique globalement. Changez `bucket_name` dans `terraform.tfvars`.

### Erreur : "Insufficient permissions"

Vérifiez que votre compte a les permissions nécessaires :
- `roles/owner` ou
- `roles/editor` + `roles/iam.securityAdmin`

## 📚 Ressources

- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [Google Cloud Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GCP Free Tier](https://cloud.google.com/free)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/)

---

**🎉 Infrastructure provisionnée avec succès !**

Cette infrastructure est prête pour déployer l'API MLOps sur GCP.
