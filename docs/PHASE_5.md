# 🟣 Phase 5 : Orchestration - Kubernetes avec auto-scaling

## 🧭 Navigation

| ← Précédent | Suivant → |
|-------------|-----------|
| [Phase 4 : Expérimentation](PHASE_4.md) | Phase 6 : Observabilité (à venir) |
| [Retour au README](../README.md) | [Toutes les phases](.) |

## 📋 Table des Matières

1. [Objectif de la Phase](#-objectif-de-la-phase)
2. [Tâches à Accomplir](#-tâches-à-accomplir)
3. [Livrables Créés](#-livrables-créés)
4. [Fonctionnalités Implémentées](#-fonctionnalités-implémentées)
5. [Concepts Kubernetes](#-concepts-kubernetes)
6. [Installation et Configuration](#-installation-et-configuration)
7. [Guide de Déploiement](#-guide-de-déploiement)
8. [Tests et Validation](#-tests-et-validation)
9. [Commandes Utiles](#-commandes-utiles)
10. [Dépannage](#-dépannage)
11. [Validation des Objectifs](#-validation-des-objectifs)
12. [Prochaines Étapes](#-prochaines-étapes-phase-6)

---

## 🎯 Objectif de la Phase

**Comprendre et pratiquer Kubernetes (déploiement de containers)**

### ❓ Questions Clés
- Qu'est-ce qu'un Pod, un Deployment et un Service ?
- Comment exposer une application dockerisée dans un cluster K8s ?
- Comment gérer les configurations et secrets dans Kubernetes ?
- Comment mettre en place le scaling automatique ?

### ⏱️ Répartition des Heures (20h)
- **8h** → Apprentissage des concepts K8s (Pods, Deployments, Services)
- **8h** → Installation et utilisation de minikube/kind localement
- **4h** → Déploiement de l'API ML dockerisée (Projet 1) sur le cluster local K8s

---

## 📋 Tâches à Accomplir

### 1. 🎓 Concepts Kubernetes
- Comprendre l'architecture Kubernetes
- Apprendre les concepts de base : Pods, Deployments, Services
- Comprendre les ConfigMaps et Secrets
- Découvrir les Namespaces

### 2. 🛠️ Installation de l'Environnement
- Installer kubectl
- Installer minikube ou kind
- Créer un cluster Kubernetes local
- Vérifier l'installation

### 3. 📦 Création des Manifests
- Créer le namespace pour l'application
- Créer le Deployment avec l'image Docker
- Créer le Service pour exposer l'API
- Créer le ConfigMap pour la configuration
- Créer le Secret pour les données sensibles

### 4. 🚀 Déploiement
- Déployer l'application sur le cluster
- Vérifier le statut des pods
- Tester l'accès à l'API
- Configurer les health checks

### 5. 🔍 Tests et Validation
- Tester les endpoints de l'API
- Vérifier les logs
- Tester le scaling
- Valider la haute disponibilité

---

## 📦 Livrables Créés

### Structure du Projet
```
mlops-core/
├── k8s/                          # Dossier Kubernetes
│   ├── namespace.yaml            # Namespace pour l'application
│   ├── deployment.yaml           # Deployment de l'API
│   ├── service.yaml              # Service ClusterIP
│   ├── service-nodeport.yaml     # Service NodePort (dev/test)
│   ├── configmap.yaml            # Configuration non sensible
│   ├── secret.yaml.example        # Template pour secrets
│   ├── ingress.yaml              # Ingress pour exposition externe
│   ├── hpa.yaml                  # Horizontal Pod Autoscaler
│   └── README.md                 # Guide de déploiement
├── scripts/
│   └── setup-k8s.sh              # Script d'installation minikube/kind
└── docs/
    └── PHASE_5.md              # Cette documentation
```

### Fichiers Principaux

#### `k8s/deployment.yaml` - Déploiement de l'API
- **Image** : `iris-api:latest` (ou depuis Artifact Registry)
- **Replicas** : 2 (haute disponibilité)
- **Health Checks** : Liveness et Readiness probes sur `/health`
- **Ressources** : Requests et limits CPU/mémoire
- **Variables d'environnement** : Depuis ConfigMap et Secret
- **Sécurité** : Utilisateur non-root, read-only filesystem (partiel)

#### `k8s/service.yaml` - Service ClusterIP
- **Type** : ClusterIP (accès interne uniquement)
- **Port** : 8000
- **Sélecteur** : `app: iris-api`

#### `k8s/configmap.yaml` - Configuration
- Variables non sensibles :
  - `ENVIRONMENT=production`
  - `MODEL_DIR=/app/models`
  - `LOG_LEVEL=INFO`

#### `k8s/secret.yaml.example` - Template Secrets
- Variables sensibles (template) :
  - `API_KEY` : Clé API pour l'authentification
  - `MLFLOW_TRACKING_URI` : URI MLflow (ex: `gs://bucket/mlruns/`)

#### `k8s/ingress.yaml` - Exposition Externe
- **Ingress Controller** : nginx (configurable)
- **TLS** : Support HTTPS (optionnel)
- **CORS** : Configuration via annotations

#### `k8s/hpa.yaml` - Auto-Scaling
- **Min Replicas** : 2
- **Max Replicas** : 10
- **Métriques** : CPU (70%) et mémoire (80%)
- **Comportement** : Scale up rapide, scale down progressif

---

## ✅ Fonctionnalités Implémentées

### Manifests Kubernetes
- ✅ Namespace dédié (`mlops`)
- ✅ Deployment avec 2 replicas pour HA
- ✅ Service ClusterIP pour accès interne
- ✅ Service NodePort pour accès externe (dev/test)
- ✅ ConfigMap pour configuration non sensible
- ✅ Secret pour données sensibles (template)
- ✅ Ingress pour exposition HTTP/HTTPS (optionnel)
- ✅ HPA pour auto-scaling (optionnel)

### Health Checks
- ✅ Liveness probe : Vérifie que l'API est vivante
- ✅ Readiness probe : Vérifie que l'API est prête
- ✅ Endpoint `/health` utilisé pour les probes
- ✅ Délai initial de 40s pour charger le modèle ML

### Sécurité
- ✅ Utilisateur non-root dans les containers
- ✅ Secrets gérés via Kubernetes Secrets
- ✅ ConfigMap pour variables non sensibles
- ✅ Security context configuré

### Scripts et Automatisation
- ✅ Script `setup-k8s.sh` pour installer minikube/kind
- ✅ Commandes Makefile pour déploiement
- ✅ Documentation complète

---

## 🎓 Concepts Kubernetes

### Pod
Un **Pod** est la plus petite unité déployable dans Kubernetes. Il contient un ou plusieurs containers qui partagent :
- Le même réseau (même IP)
- Le même stockage (volumes)
- Le même namespace

**Exemple** : Un Pod peut contenir l'API FastAPI et un sidecar pour le logging.

### Deployment
Un **Deployment** gère un ensemble de Pods identiques (replicas). Il assure :
- La création et la mise à jour des Pods
- Le rolling update (déploiement sans interruption)
- Le rollback en cas de problème
- Le scaling (augmentation/réduction du nombre de Pods)

**Dans notre cas** : Le Deployment crée 2 Pods identiques pour la haute disponibilité.

### Service
Un **Service** expose un ensemble de Pods comme un service réseau. Il fournit :
- Une IP stable (ClusterIP)
- Un équilibrage de charge entre les Pods
- Un DNS interne pour la découverte de service

**Types de Services** :
- **ClusterIP** : Accès interne uniquement
- **NodePort** : Accès externe via un port sur chaque node
- **LoadBalancer** : IP publique externe (cloud providers)
- **Ingress** : Routage HTTP/HTTPS basé sur le domaine

### ConfigMap
Un **ConfigMap** stocke des données de configuration non sensibles (clé-valeur). Utilisé pour :
- Variables d'environnement
- Fichiers de configuration
- Paramètres d'application

**Dans notre cas** : `ENVIRONMENT`, `MODEL_DIR`, `LOG_LEVEL`.

### Secret
Un **Secret** stocke des données sensibles (clés API, mots de passe, etc.). Similaire à ConfigMap mais :
- Encodé en base64
- Plus sécurisé (ne pas exposer dans les logs)
- Géré séparément

**Dans notre cas** : `API_KEY`, `MLFLOW_TRACKING_URI`.

### Namespace
Un **Namespace** isole des ressources dans un cluster. Utile pour :
- Séparer les environnements (dev, staging, prod)
- Limiter les permissions (RBAC)
- Organiser les ressources

**Dans notre cas** : Namespace `mlops` pour toutes les ressources de l'application.

---

## 🚀 Installation et Configuration

### Prérequis

| Outil | Version | Description |
|-------|---------|-------------|
| **kubectl** | >= 1.28 | Client Kubernetes |
| **Docker** | >= 20.10 | Pour minikube/kind |
| **minikube** | >= 1.30 | Ou **kind** >= 0.20 | Cluster Kubernetes local |

### Étape 1 : Installer kubectl

#### macOS
```bash
brew install kubectl
```

#### Linux
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

#### Vérifier l'installation
```bash
kubectl version --client
```

### Étape 2 : Installer minikube ou kind

#### Option A : minikube (Recommandé pour débutants)

**macOS** :
```bash
brew install minikube
```

**Linux** :
```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

**Démarrer minikube** :
```bash
minikube start --driver=docker --memory=4096 --cpus=2
```

#### Option B : kind (Kubernetes in Docker)

**Installation** :
```bash
# macOS
brew install kind

# Linux
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

**Créer le cluster** :
```bash
kind create cluster --name mlops-cluster
```

### Étape 3 : Utiliser le Script Automatique

Le projet inclut un script d'installation automatique :

```bash
# Installer avec minikube
make k8s-setup

# Ou avec kind
make k8s-setup-kind

# Ou directement
./scripts/setup-k8s.sh minikube
./scripts/setup-k8s.sh kind
```

### Étape 4 : Vérifier l'Installation

```bash
# Vérifier le cluster
kubectl cluster-info

# Voir les nodes
kubectl get nodes

# Vérifier que kubectl fonctionne
kubectl get pods --all-namespaces
```

---

## 🚀 Guide de Déploiement

### Étape 1 : Préparer l'Image Docker

#### Option A : Utiliser l'Image Locale (minikube)

```bash
# Configurer Docker pour utiliser le daemon de minikube
eval $(minikube docker-env)

# Builder l'image
make build
# ou
docker build -t iris-api:latest .
```

#### Option B : Utiliser l'Image depuis Artifact Registry (Production)

Modifier `k8s/deployment.yaml` :
```yaml
image: europe-west1-docker.pkg.dev/PROJECT_ID/mlops-repo/iris-api:latest
imagePullPolicy: Always
```

### Étape 2 : Préparer les Secrets

```bash
# Copier le template
cp k8s/secret.yaml.example k8s/secret.yaml

# Éditer avec vos valeurs
# ⚠️ Ne JAMAIS commiter secret.yaml !
```

**Contenu de `k8s/secret.yaml`** :
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: iris-api-secrets
  namespace: mlops
type: Opaque
stringData:
  API_KEY: "votre-api-key-ici"  # Générer avec: openssl rand -hex 32
  MLFLOW_TRACKING_URI: "gs://bucket-name/mlruns/"  # Si vous utilisez GCS
```

### Étape 3 : Déployer l'Application

```bash
# Déployer tout en une commande
make k8s-deploy

# Ou étape par étape
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

### Étape 4 : Vérifier le Déploiement

```bash
# Voir le statut
make k8s-status

# Ou manuellement
kubectl get pods -n mlops
kubectl get services -n mlops
kubectl get deployments -n mlops
```

**Résultat attendu** :
```
NAME                        READY   STATUS    RESTARTS   AGE
iris-api-xxxxxxxxxx-xxxxx   1/1     Running   0          30s
iris-api-xxxxxxxxxx-xxxxx   1/1     Running   0          30s
```

### Étape 5 : Accéder à l'API

#### Option 1 : Port-Forward (Développement)

```bash
# Dans un terminal
make k8s-port-forward

# Dans un autre terminal, tester
curl http://localhost:8000/health
```

#### Option 2 : NodePort (Test)

```bash
# Appliquer le service NodePort
kubectl apply -f k8s/service-nodeport.yaml

# Récupérer l'IP du node
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

# Tester
curl http://$NODE_IP:30080/health
```

#### Option 3 : Ingress (Production)

```bash
# Installer un Ingress Controller (ex: nginx)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

# Modifier ingress.yaml avec votre domaine
# Puis appliquer
kubectl apply -f k8s/ingress.yaml
```

---

## 🧪 Tests et Validation

### Test 1 : Health Check

```bash
# Via port-forward
make k8s-port-forward  # Dans un terminal

# Dans un autre terminal
curl http://localhost:8000/health
```

**Résultat attendu** :
```json
{
  "status": "healthy",
  "model_loaded": true,
  "version": "1.0.0"
}
```

### Test 2 : Prédiction avec API Key

```bash
# Récupérer l'API key depuis le secret
export API_KEY=$(kubectl get secret iris-api-secrets -n mlops -o jsonpath='{.data.API_KEY}' | base64 -d)

# Tester la prédiction
curl -X POST "http://localhost:8000/predict" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: $API_KEY" \
  -d '{
    "sepal_length": 5.1,
    "sepal_width": 3.5,
    "petal_length": 1.4,
    "petal_width": 0.2
  }'
```

**Résultat attendu** :
```json
{
  "prediction": "setosa",
  "confidence": 0.95,
  "probabilities": {...}
}
```

### Test 3 : Vérifier les Logs

```bash
# Voir les logs
make k8s-logs

# Ou pour un pod spécifique
kubectl logs <pod-name> -n mlops -f
```

### Test 4 : Vérifier le Scaling

```bash
# Voir les pods
kubectl get pods -n mlops

# Scale manuellement
kubectl scale deployment iris-api --replicas=3 -n mlops

# Vérifier
kubectl get pods -n mlops
```

### Test 5 : Auto-Scaling (HPA)

```bash
# Installer metrics-server (si nécessaire)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Déployer le HPA
kubectl apply -f k8s/hpa.yaml

# Vérifier
kubectl get hpa -n mlops

# Générer de la charge (dans un autre terminal)
while true; do curl http://localhost:8000/health; done

# Observer le scaling
watch kubectl get pods -n mlops
```

---

## 📝 Commandes Utiles

### Commandes Makefile

| Commande | Description |
|----------|-------------|
| `make k8s-setup` | Installer minikube et créer le cluster |
| `make k8s-setup-kind` | Installer kind et créer le cluster |
| `make k8s-deploy` | Déployer l'application |
| `make k8s-status` | Vérifier le statut |
| `make k8s-logs` | Voir les logs |
| `make k8s-port-forward` | Port-forward vers l'API |
| `make k8s-test` | Tester l'API |
| `make k8s-delete` | Supprimer le déploiement |
| `make k8s-clean` | Nettoyer complètement |

### Commandes kubectl

```bash
# Voir tous les ressources
kubectl get all -n mlops

# Décrire un pod
kubectl describe pod <pod-name> -n mlops

# Exécuter une commande dans un pod
kubectl exec -it <pod-name> -n mlops -- /bin/bash

# Voir les événements
kubectl get events -n mlops --sort-by='.lastTimestamp'

# Redémarrer le déploiement
kubectl rollout restart deployment/iris-api -n mlops

# Voir l'historique des déploiements
kubectl rollout history deployment/iris-api -n mlops

# Rollback vers une version précédente
kubectl rollout undo deployment/iris-api -n mlops

# Voir les logs d'un déploiement
kubectl logs -f deployment/iris-api -n mlops

# Voir les ressources utilisées
kubectl top pods -n mlops
kubectl top nodes
```

---

## 🔍 Dépannage

### Problème : Les pods ne démarrent pas

**Symptômes** :
- Pods en état `Pending` ou `CrashLoopBackOff`
- Erreurs dans les logs

**Solutions** :

```bash
# Voir les détails d'un pod
kubectl describe pod <pod-name> -n mlops

# Voir les logs
kubectl logs <pod-name> -n mlops

# Vérifier les événements
kubectl get events -n mlops --sort-by='.lastTimestamp'

# Causes courantes :
# - Image non trouvée : Vérifier le nom de l'image dans deployment.yaml
# - Secrets manquants : Vérifier que secret.yaml existe et est appliqué
# - Ressources insuffisantes : Vérifier les ressources du cluster
```

### Problème : L'API ne répond pas

**Symptômes** :
- Health check échoue
- Timeout lors des requêtes

**Solutions** :

```bash
# Vérifier que les pods sont Running
kubectl get pods -n mlops

# Vérifier les logs
kubectl logs -f deployment/iris-api -n mlops

# Vérifier le service
kubectl get service iris-api-service -n mlops

# Tester depuis un pod
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl http://iris-api-service:8000/health
```

### Problème : Secrets non trouvés

**Symptômes** :
- Erreur "secret not found" dans les logs
- Pods en état `CreateContainerConfigError`

**Solutions** :

```bash
# Vérifier que le secret existe
kubectl get secret iris-api-secrets -n mlops

# Vérifier le contenu (sans afficher les valeurs)
kubectl describe secret iris-api-secrets -n mlops

# Recréer le secret si nécessaire
kubectl delete secret iris-api-secrets -n mlops
kubectl apply -f k8s/secret.yaml
```

### Problème : Image non trouvée

**Symptômes** :
- Pods en état `ImagePullBackOff`
- Erreur "image not found"

**Solutions** :

**Avec minikube** :
```bash
# Utiliser le daemon Docker de minikube
eval $(minikube docker-env)
docker build -t iris-api:latest .
```

**Avec Artifact Registry** :
```bash
# Vérifier l'authentification
gcloud auth configure-docker europe-west1-docker.pkg.dev

# Modifier deployment.yaml pour utiliser l'image complète
# image: europe-west1-docker.pkg.dev/PROJECT_ID/mlops-repo/iris-api:latest
```

### Problème : Port-forward ne fonctionne pas

**Symptômes** :
- Connexion refusée
- Timeout

**Solutions** :

```bash
# Vérifier que le service existe
kubectl get service iris-api-service -n mlops

# Vérifier que les pods sont Running
kubectl get pods -n mlops

# Essayer un autre port
kubectl port-forward service/iris-api-service 8080:8000 -n mlops
```

### Problème : HPA ne fonctionne pas

**Symptômes** :
- HPA affiche `<unknown>` pour les métriques
- Pas de scaling automatique

**Solutions** :

```bash
# Vérifier que metrics-server est installé
kubectl get deployment metrics-server -n kube-system

# Installer metrics-server si nécessaire
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Vérifier les métriques
kubectl top pods -n mlops

# Vérifier le HPA
kubectl describe hpa iris-api-hpa -n mlops
```

---

## ✅ Validation des Objectifs

| Objectif | Status | Détails |
|----------|--------|---------|
| **Concepts K8s** | ✅ | Compris : Pods, Deployments, Services, ConfigMaps, Secrets |
| **Installation** | ✅ | minikube/kind installé et cluster créé |
| **Manifests** | ✅ | Tous les manifests créés (deployment, service, configmap, secret) |
| **Déploiement** | ✅ | API déployée sur le cluster local |
| **Health Checks** | ✅ | Liveness et readiness probes configurés |
| **Tests** | ✅ | API accessible et fonctionnelle |
| **Documentation** | ✅ | Guide complet avec exemples |

---

## 🚀 Prochaines Étapes (Phase 6)

- 📊 Observabilité & Monitoring (Prometheus, Grafana)
- 🔍 Métriques avancées
- 📈 Dashboards de monitoring
- 🚨 Alertes et notifications

---

**🎉 Phase 5 terminée avec succès !**

L'API MLOps est maintenant déployée sur Kubernetes avec :
- ✅ Haute disponibilité (2 replicas)
- ✅ Health checks configurés
- ✅ Configuration et secrets gérés
- ✅ Auto-scaling optionnel (HPA)
- ✅ Documentation complète

Le projet est prêt pour la Phase 6 (Observabilité & Monitoring) !

