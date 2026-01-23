# 🟣 Phase 5 : Orchestration - Kubernetes avec Auto-Scaling

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
6. [Architecture du Déploiement](#-architecture-du-déploiement)
7. [Installation et Configuration](#-installation-et-configuration)
8. [Guide de Déploiement](#-guide-de-déploiement)
9. [Workflows MLflow](#-workflows-mlflow)
10. [Auto-Scaling avec HPA](#-auto-scaling-avec-hpa)
11. [Tests et Validation](#-tests-et-validation)
12. [Commandes Utiles](#-commandes-utiles)
13. [Sécurité](#-sécurité)
14. [Dépannage](#-dépannage)
15. [Métriques](#-métriques)
16. [Validation des Objectifs](#-validation-des-objectifs)
17. [Prochaines Étapes](#-prochaines-étapes-phase-6)
18. [Ressources](#-ressources)

---

## 🎯 Objectif de la Phase

**Orchestrer l'application ML containerisée sur Kubernetes avec haute disponibilité et auto-scaling**

### ❓ Questions Clés
- Qu'est-ce qu'un Pod, un Deployment et un Service dans Kubernetes ?
- Comment exposer une application dockerisée dans un cluster K8s ?
- Comment gérer les configurations et secrets dans Kubernetes ?
- Comment mettre en place le scaling automatique basé sur les métriques ?

### ⏱️ Répartition des Heures (20h)
- **8h** → Apprentissage des concepts K8s (Pods, Deployments, Services, ConfigMaps, Secrets)
- **8h** → Installation et utilisation de minikube/kind localement
- **4h** → Déploiement de l'API ML dockerisée sur le cluster local K8s

---

## 📋 Tâches à Accomplir

### 1. 🎓 Apprendre les Concepts Kubernetes
- Comprendre l'architecture d'un cluster Kubernetes
- Maîtriser les concepts de base : Pods, Deployments, Services
- Gérer les configurations avec ConfigMaps et Secrets
- Comprendre les Namespaces pour l'isolation

### 2. 🛠️ Installation et Configuration
- Installer kubectl (client Kubernetes)
- Configurer un cluster local (minikube ou kind)
- Vérifier la connectivité au cluster

### 3. 🚀 Déploiement de l'Application
- Créer les manifests Kubernetes (Deployment, Service, ConfigMap, Secret)
- Déployer l'API FastAPI sur le cluster
- Configurer les health checks (liveness et readiness probes)
- Exposer l'API via Service et Ingress

### 4. 📊 Intégration MLflow
- Déployer un serveur MLflow dans le cluster
- Configurer le partage de volumes pour les données MLflow
- Connecter l'API au serveur MLflow

### 5. ⚖️ Auto-Scaling
- Configurer le Horizontal Pod Autoscaler (HPA)
- Définir les métriques de scaling (CPU, mémoire)
- Tester le scaling automatique

---

## 📦 Livrables Créés

### Structure des Fichiers Kubernetes

```
k8s/
├── namespace.yaml              # Namespace mlops pour isolation
├── deployment.yaml             # Deployment API (2 replicas)
├── mlflow-deployment.yaml      # Deployment MLflow server (1 replica)
├── service.yaml                # Service ClusterIP pour l'API
├── mlflow-service.yaml         # Service ClusterIP pour MLflow
├── service-nodeport.yaml       # Service NodePort (dev/test)
├── configmap.yaml              # Configuration non sensible
├── secret.yaml.example         # Template pour secrets
├── ingress.yaml                # Ingress pour exposition externe
├── hpa.yaml                    # Horizontal Pod Autoscaler
└── README.md                   # Guide rapide de déploiement
```

### Fichiers Principaux

#### `k8s/deployment.yaml` - Déploiement de l'API
- **Replicas** : 2 pods pour haute disponibilité
- **Strategy** : RollingUpdate (zero-downtime)
- **Health Checks** : Liveness et readiness probes sur `/health`
- **Ressources** : Requests et limits CPU/mémoire
- **Sécurité** : Containers non-root, capabilities limitées
- **Volumes** : Partage de `mlruns/` via hostPath

#### `k8s/mlflow-deployment.yaml` - Serveur MLflow
- **Replicas** : 1 (singleton)
- **Strategy** : Recreate (serveur avec état)
- **Image** : `ghcr.io/mlflow/mlflow:v2.9.2`
- **Backend Store** : Fichier local (`file:///mlruns`)
- **Volume** : Partage du même volume que l'API

#### `k8s/service.yaml` - Service ClusterIP
- **Type** : ClusterIP (accès interne uniquement)
- **Port** : 8000
- **Selector** : `app: iris-api`
- **Load Balancing** : Round-robin entre les pods

#### `k8s/configmap.yaml` - Configuration
- Variables d'environnement non sensibles :
  - `ENVIRONMENT`: production
  - `MODEL_DIR`: /app/models
  - `LOG_LEVEL`: INFO

#### `k8s/secret.yaml.example` - Template Secrets
- `API_KEY`: Clé API pour authentification
- `MLFLOW_TRACKING_URI`: URI du serveur MLflow ou GCS

#### `k8s/hpa.yaml` - Auto-Scaling
- **Min replicas** : 2
- **Max replicas** : 10
- **Métriques** : CPU (70%) et mémoire (80%)
- **Comportement** : Scaling up réactif, scaling down prudent

#### `k8s/ingress.yaml` - Exposition Externe
- **Controller** : nginx-ingress
- **TLS** : Support HTTPS (cert-manager)
- **Annotations** : Rate limiting, CORS, timeouts

---

## ✅ Fonctionnalités Implémentées

### Déploiement Kubernetes
- ✅ Namespace `mlops` pour isolation
- ✅ Deployment avec 2 replicas pour haute disponibilité
- ✅ Rolling update sans interruption de service
- ✅ Health checks (liveness et readiness probes)
- ✅ Gestion des ressources (requests et limits)
- ✅ Sécurité renforcée (non-root, capabilities limitées)

### Services et Exposition
- ✅ Service ClusterIP pour accès interne
- ✅ Service NodePort pour développement/test
- ✅ Ingress pour exposition externe avec TLS
- ✅ Load balancing automatique entre pods

### Configuration et Secrets
- ✅ ConfigMap pour variables d'environnement non sensibles
- ✅ Secrets Kubernetes pour données sensibles (API keys)
- ✅ Injection via `envFrom` et `env`
- ✅ Template de secret avec instructions

### MLflow Integration
- ✅ Serveur MLflow déployé dans le cluster
- ✅ Partage de volumes entre API et MLflow
- ✅ Service ClusterIP pour accès interne
- ✅ Support de trois modes :
  - Serveur MLflow dans K8s (recommandé)
  - Local avec hostPath (développement)
  - GCS (production cloud)

### Auto-Scaling
- ✅ Horizontal Pod Autoscaler (HPA) configuré
- ✅ Scaling basé sur CPU et mémoire
- ✅ Comportement configurable (stabilisation, politiques)
- ✅ Métriques via metrics-server

### Commandes Makefile
- ✅ `make k8s-setup` : Installation minikube/kind
- ✅ `make k8s-deploy` : Déploiement API
- ✅ `make k8s-deploy-mlflow` : Déploiement API + MLflow
- ✅ `make k8s-status` : Vérification du statut
- ✅ `make k8s-logs` : Visualisation des logs
- ✅ `make k8s-port-forward` : Accès à l'API
- ✅ `make k8s-mlflow-ui` : Accès à MLflow UI
- ✅ `make k8s-test` : Tests automatisés
- ✅ `make k8s-clean` : Nettoyage complet

---

## 🎓 Concepts Kubernetes

### Pod
**Plus petite unité déployable** dans Kubernetes. Contient un ou plusieurs containers qui partagent :
- Le même réseau (même IP)
- Le même stockage (volumes)
- Le même namespace

**Exemple** : Un Pod contient l'API FastAPI.

### Deployment
**Orchestrateur qui gère un ensemble de Pods identiques** (replicas). Assure :
- ✅ Création et mise à jour des Pods
- ✅ Rolling update (déploiement sans interruption)
- ✅ Rollback en cas de problème
- ✅ Scaling (augmentation/réduction)

**Dans notre cas** : 2 Pods identiques pour la haute disponibilité.

### Service
**Expose un ensemble de Pods comme un service réseau**. Fournit :
- ✅ IP stable (ClusterIP)
- ✅ Équilibrage de charge entre les Pods
- ✅ DNS interne (`service-name.namespace.svc.cluster.local`)

**Types** :
- **ClusterIP** : Accès interne uniquement
- **NodePort** : Accès externe via port sur chaque node
- **LoadBalancer** : IP publique externe (cloud)
- **Ingress** : Routage HTTP/HTTPS basé sur domaine

### ConfigMap
**Stocke des données de configuration non sensibles** (clé-valeur).

**Dans notre cas** : `ENVIRONMENT`, `MODEL_DIR`, `LOG_LEVEL`.

### Secret
**Stocke des données sensibles** (clés API, mots de passe). Similaire à ConfigMap mais :
- ✅ Encodé en base64
- ✅ Plus sécurisé (ne pas exposer dans les logs)

**Dans notre cas** : `API_KEY`, `MLFLOW_TRACKING_URI`.

### Namespace
**Isole des ressources dans un cluster**. Utile pour :
- ✅ Séparer les environnements (dev, staging, prod)
- ✅ Limiter les permissions (RBAC)
- ✅ Organiser les ressources

**Dans notre cas** : Namespace `mlops` pour toutes les ressources.

### Volume
**Permet aux pods de partager des données**. Types :
- **hostPath** : Monte un répertoire de la machine hôte
- **PersistentVolume** : Stockage persistant
- **ConfigMap/Secret** : Montés comme volumes

**Dans notre cas** : `hostPath` pour partager `mlruns/` entre pods.

### HPA (Horizontal Pod Autoscaler)
**Ajuste automatiquement le nombre de replicas** selon les métriques (CPU, mémoire).

**Dans notre cas** : Scale entre 2 et 10 pods selon CPU (70%) et mémoire (80%).

---

## 🏗️ Architecture du Déploiement

### Vue d'Ensemble

Le cluster Kubernetes héberge **3 applications principales** réparties dans **2 namespaces** :

| Application | Namespace | Rôle |
|-------------|-----------|------|
| **nginx** (Ingress Controller) | `ingress-nginx` | Reverse proxy, routage HTTP/HTTPS |
| **iris-api** (FastAPI) | `mlops` | API ML pour prédictions |
| **mlflow-server** (MLflow) | `mlops` | Tracking et gestion des modèles ML |

### Namespaces

#### Namespace `ingress-nginx`

**Rôle** : Héberge l'Ingress Controller nginx (optionnel, pour exposition externe)

**Ressources** :
- Deployment `ingress-nginx-controller`
- Service `ingress-nginx-controller` (LoadBalancer ou NodePort)
- ConfigMaps, Secrets pour la configuration nginx

**Installation** :
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
```

**Vérification** :
```bash
kubectl get pods -n ingress-nginx
kubectl get service -n ingress-nginx
```

#### Namespace `mlops`

**Rôle** : Héberge les applications métier (API et MLflow)

**Ressources** :
- Deployment `iris-api` (2 replicas)
- Deployment `mlflow-server` (1 replica)
- Services `iris-api-service` et `mlflow-server-service`
- ConfigMap `iris-api-config`
- Secret `iris-api-secrets`
- Ingress `iris-api-ingress` (optionnel)
- HPA `iris-api-hpa` (optionnel)

**Création** :
```bash
kubectl apply -f k8s/namespace.yaml
```

**Vérification** :
```bash
kubectl get all -n mlops
```

### Applications et Pods

#### 1. Nginx Ingress Controller (Optionnel)

**Namespace** : `ingress-nginx` (ou `kube-system`)

**Deployment** : `ingress-nginx-controller`

**Container** :
- **Image** : `registry.k8s.io/ingress-nginx/controller`
- **Application** : nginx (reverse proxy)
- **Ports** : 80 (HTTP), 443 (HTTPS)

**Rôle** :
- ✅ Lit les règles Ingress de tous les namespaces
- ✅ Route le trafic HTTP/HTTPS vers les Services appropriés
- ✅ Gère TLS/HTTPS (terminaison SSL)
- ✅ Rate limiting (protection DDoS)
- ✅ CORS (Cross-Origin Resource Sharing)
- ✅ Load balancing au niveau HTTP

**Service** :
- **Type** : `LoadBalancer` (production cloud) ou `NodePort` (local)
- **Accès** : Production via IP publique du LoadBalancer, Local via `http://<node-ip>:<nodePort>`

#### 2. Iris API (FastAPI)

**Namespace** : `mlops`

**Deployment** : `iris-api`

**Pods** : `iris-api-<hash>-1`, `iris-api-<hash>-2` (2 replicas)

**Container** :
- **Image** : `iris-api:latest` (ou depuis Artifact Registry)
- **Application** : FastAPI (serveur web Python)
- **Port** : 8000

**Rôle** :
- ✅ API REST pour prédictions ML
- ✅ Endpoints : `/predict`, `/health`, `/metrics`
- ✅ Authentification via API Key
- ✅ Charge les modèles depuis MLflow
- ✅ Métriques Prometheus

**Service** :
- **Type** : `ClusterIP` (accès interne uniquement)
- **DNS** : `iris-api-service.mlops.svc.cluster.local`
- **Port** : 8000

**Accès** :
- Depuis nginx : `http://iris-api-service:8000`
- Depuis mlflow-server : `http://iris-api-service:8000`
- Depuis l'extérieur : Via port-forward ou Ingress

#### 3. MLflow Server

**Namespace** : `mlops`

**Deployment** : `mlflow-server`

**Pod** : `mlflow-server-<hash>` (1 replica)

**Container** :
- **Image** : `ghcr.io/mlflow/mlflow:v2.9.2`
- **Application** : MLflow (serveur de tracking ML)
- **Port** : 5000

**Rôle** :
- ✅ Stocke les runs ML (expériences, paramètres, métriques)
- ✅ Sert les modèles ML (artifacts)
- ✅ UI MLflow (interface web)
- ✅ API REST MLflow

**Service** :
- **Type** : `ClusterIP` (accès interne uniquement)
- **DNS** : `mlflow-server-service.mlops.svc.cluster.local`
- **Port** : 5000

**Accès** :
- Depuis iris-api : `http://mlflow-server-service:5000`
- Depuis l'extérieur : Via port-forward (`make k8s-mlflow-ui`)

### Services

#### Service iris-api

**Namespace** : `mlops`

**Nom** : `iris-api-service`

**Type** : `ClusterIP` (interne uniquement)

**Port** : 8000 → 8000

**Sélecteur** : `app: iris-api`

**DNS** : `iris-api-service.mlops.svc.cluster.local`

**Rôle** :
- ✅ Load balancing entre les 2 pods iris-api
- ✅ DNS stable (même si les pods redémarrent)
- ✅ Point d'accès unique pour nginx

**Accès depuis nginx** :
```yaml
# Dans ingress.yaml
backend:
  service:
    name: iris-api-service  # Service dans namespace mlops
    port:
      number: 8000
```

#### Service mlflow-server

**Namespace** : `mlops`

**Nom** : `mlflow-server-service`

**Type** : `ClusterIP` (interne uniquement)

**Port** : 5000 → 5000

**Sélecteur** : `app: mlflow-server`

**DNS** : `mlflow-server-service.mlops.svc.cluster.local`

**Rôle** :
- ✅ Point d'accès stable pour mlflow-server
- ✅ Utilisé par iris-api pour charger les modèles

**Accès depuis iris-api** :
```python
# Dans le code Python
MLFLOW_TRACKING_URI = "http://mlflow-server-service:5000"
```

### Communication Inter-Namespace

Kubernetes permet la communication entre namespaces via le DNS interne.

#### Format DNS Kubernetes

```
<service-name>.<namespace>.svc.cluster.local
```

#### Exemples dans l'Architecture

**1. Nginx → Iris API** :
```yaml
# Dans ingress.yaml (namespace: mlops)
# Nginx (namespace: ingress-nginx) lit cette règle
backend:
  service:
    name: iris-api-service  # Service dans namespace mlops
    port:
      number: 8000
```

**DNS utilisé** : `iris-api-service.mlops.svc.cluster.local:8000`

**2. Iris API → MLflow Server** :
```python
# Dans secret.yaml (namespace: mlops)
MLFLOW_TRACKING_URI: "http://mlflow-server-service:5000"
# ou explicitement :
# MLFLOW_TRACKING_URI: "http://mlflow-server-service.mlops.svc.cluster.local:5000"
```

**DNS utilisé** : `mlflow-server-service.mlops.svc.cluster.local:5000`

#### Raccourci DNS

Dans le même namespace, vous pouvez utiliser juste le nom du service :

```python
# Dans namespace mlops
MLFLOW_TRACKING_URI: "http://mlflow-server-service:5000"
# Équivalent à :
# MLFLOW_TRACKING_URI: "http://mlflow-server-service.mlops.svc.cluster.local:5000"
```

### Volumes Partagés

#### Volume `mlruns-volume`

**Type** : `hostPath`

**Path sur le nœud** : `/tmp/mlruns`

**Monté dans** :

**1. Pods iris-api** :
```yaml
volumeMounts:
- name: mlruns-volume
  mountPath: /app/mlruns  # Où le code Python cherche mlruns/
  readOnly: false
```

**Usage** :
- ✅ Nécessaire si `MLFLOW_TRACKING_URI=""` (mode local)
- ❌ Pas nécessaire si `MLFLOW_TRACKING_URI="http://mlflow-server-service:5000"` (mode serveur)

**2. Pod mlflow-server** :
```yaml
volumeMounts:
- name: mlruns-volume
  mountPath: /mlruns  # MLflow stocke tout ici
  readOnly: false
```

**Usage** :
- ✅ Toujours nécessaire (mlflow-server stocke les données ici)

#### Partage de Données

**Workflow avec MLflow Server** :
1. MLflow server stocke dans `/mlruns` (volume partagé)
2. Iris-api charge via HTTP : `http://mlflow-server-service:5000`
3. Le volume n'est pas utilisé par iris-api (mais nécessaire pour mlflow-server)

**Workflow Local** :
1. Modèle dans `/app/mlruns` (volume partagé)
2. Iris-api charge directement depuis le système de fichiers
3. Le volume est utilisé par iris-api

### Flux de Trafic

#### Flux 1 : Client → API (via Ingress)

**Étapes** :
1. Client Internet envoie une requête HTTP/HTTPS vers `iris-api.example.com`
2. DNS résout vers l'IP du LoadBalancer (nginx)
3. Service `ingress-nginx-controller` route vers le Pod nginx (namespace: `ingress-nginx`)
4. Nginx lit les règles Ingress (cherche dans TOUS les namespaces)
5. Nginx trouve l'Ingress `iris-api-ingress` (namespace: `mlops`)
6. Nginx route vers le Service `iris-api-service` (namespace: `mlops`)
7. Service load balance vers un Pod iris-api (1 ou 2)
8. FastAPI traite la requête et retourne la réponse

#### Flux 2 : API → MLflow Server (interne)

**Étapes** :
1. Pod iris-api envoie une requête HTTP vers `http://mlflow-server-service:5000`
2. Service `mlflow-server-service` route vers le Pod mlflow-server
3. MLflow traite la requête et retourne le modèle ou les métadonnées
4. Pod iris-api charge le modèle et l'utilise pour les prédictions

#### Flux 3 : Port-Forward (développement)

**Étapes** :
1. Votre machine locale utilise `kubectl port-forward`
2. Le port-forward se connecte directement au Service `iris-api-service`
3. Service load balance vers un Pod iris-api (1 ou 2)
4. FastAPI traite la requête et retourne la réponse sur `localhost:8000`

**Note** : Le port-forward contourne complètement nginx et l'Ingress.

### Modes MLflow

| Mode | MLFLOW_TRACKING_URI | Volume | Usage |
|------|---------------------|--------|-------|
| **K8s Server** | `http://mlflow-server-service:5000` | Partagé | Portfolio/Production |
| **Local** | `""` | hostPath + mount | Développement |
| **GCS** | `gs://bucket/mlruns/` | Aucun | Production cloud |

### Tableau Récapitulatif

| Composant | Namespace | Type | Nom | Port | Accès |
|-----------|-----------|------|-----|------|-------|
| **nginx** | `ingress-nginx` | Deployment | `ingress-nginx-controller` | 80, 443 | Internet (LoadBalancer) |
| **iris-api** | `mlops` | Deployment | `iris-api` | 8000 | Interne (ClusterIP) |
| **mlflow-server** | `mlops` | Deployment | `mlflow-server` | 5000 | Interne (ClusterIP) |
| **Ingress** | `mlops` | Ingress | `iris-api-ingress` | - | Règles de routage |
| **Volume** | `mlops` | Volume | `mlruns-volume` | - | Partagé entre pods |

---

## 🚀 Installation et Configuration

### Prérequis

| Outil | Version | Description |
|-------|---------|-------------|
| **kubectl** | >= 1.28 | Client Kubernetes |
| **Docker** | >= 20.10 | Pour minikube/kind |
| **minikube** | >= 1.30 | Ou **kind** >= 0.20 | Cluster local |

### Installation Automatique (Recommandé)

```bash
# Avec minikube
make k8s-setup

# Avec kind
make k8s-setup-kind

# Ou directement
./scripts/setup-k8s.sh minikube
./scripts/setup-k8s.sh kind
```

### Installation Manuelle

#### 1. Installer kubectl

**macOS** :
```bash
brew install kubectl
```

**Linux** :
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

#### 2. Installer minikube ou kind

**minikube** (macOS) :
```bash
brew install minikube
minikube start --driver=docker --memory=4096 --cpus=2
```

**kind** :
```bash
brew install kind  # macOS
kind create cluster --name mlops-cluster
```

#### 3. Vérifier

```bash
kubectl cluster-info
kubectl get nodes
```

---

## 🚀 Guide de Déploiement

### Étape 1 : Préparer l'Image Docker

**Option A : Image Locale (minikube)**
```bash
eval $(minikube docker-env)
make build
```

**Option B : Artifact Registry (Production)**
```yaml
# Dans k8s/deployment.yaml
image: europe-west1-docker.pkg.dev/PROJECT_ID/mlops-repo/iris-api:latest
imagePullPolicy: Always
```

### Étape 2 : Préparer les Secrets

```bash
cp k8s/secret.yaml.example k8s/secret.yaml
# Éditer k8s/secret.yaml avec vos valeurs
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
  API_KEY: "votre-api-key-ici"  # openssl rand -hex 32
  MLFLOW_TRACKING_URI: "http://mlflow-server-service:5000"  # Ou "gs://bucket/mlruns/"
```

### Étape 3 : Déployer

**Option A : Avec MLflow Server** (Recommandé)
```bash
make k8s-deploy-mlflow
```

**Option B : MLflow Local**
```bash
# 1. Monter mlruns/ (terminal séparé)
minikube mount $(pwd)/mlruns:/tmp/mlruns

# 2. Déployer
make k8s-deploy
```

**Manuellement** :
```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/mlflow-deployment.yaml  # Si MLflow server
kubectl apply -f k8s/mlflow-service.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

### Étape 4 : Vérifier

```bash
make k8s-status
# ou
kubectl get pods,services -n mlops
```

**Résultat attendu** :
```
NAME                        READY   STATUS    RESTARTS   AGE
iris-api-xxxxxxxxxx-xxxxx   1/1     Running   0          30s
iris-api-xxxxxxxxxx-xxxxx   1/1     Running   0          30s
mlflow-server-xxxxx         1/1     Running   0          30s
```

### Étape 5 : Accéder à l'API

**Port-Forward** (Développement) :
```bash
make k8s-port-forward
# http://localhost:8000
```

**MLflow UI** (si déployé) :
```bash
make k8s-mlflow-ui
# http://localhost:5000
```

**NodePort** (Test) :
```bash
kubectl apply -f k8s/service-nodeport.yaml
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
curl http://$NODE_IP:30080/health
```

**Ingress** (Production) :
```bash
# Installer Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
kubectl apply -f k8s/ingress.yaml
```

---

## 🔄 Workflows MLflow

### Workflow 1 : Migration des Données Existantes

**Objectif** : Utiliser un modèle déjà entraîné localement

```bash
# 1. Monter mlruns/ local vers le cluster
minikube mount $(pwd)/mlruns:/tmp/mlruns

# 2. Déployer (MLFLOW_TRACKING_URI="")
make k8s-deploy

# 3. Vérifier
kubectl exec -it deployment/iris-api -n mlops -- ls -la /app/mlruns
```

### Workflow 2 : Réentraînement vers MLflow Server

**Objectif** : Entraîner un nouveau modèle vers le serveur MLflow

```bash
# 1. Déployer MLflow server
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/mlflow-deployment.yaml
kubectl apply -f k8s/mlflow-service.yaml

# 2. Port-forward (terminal séparé)
kubectl port-forward service/mlflow-server-service 5000:5000 -n mlops

# 3. Entraîner vers le serveur
export MLFLOW_TRACKING_URI="http://localhost:5000"
make train

# 4. Déployer l'API
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml  # MLFLOW_TRACKING_URI="http://mlflow-server-service:5000"
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

### Workflow 3 : Production avec GCS

**Objectif** : Utiliser GCS comme backend MLflow (production cloud)

```bash
# 1. Configurer secret.yaml
# MLFLOW_TRACKING_URI: "gs://bucket-name/mlruns/"

# 2. Déployer (pas besoin de volume hostPath)
kubectl apply -f k8s/deployment.yaml

# 3. L'API charge automatiquement depuis GCS
```

---

## 📊 Auto-Scaling avec HPA

### Installation de metrics-server

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### Déploiement du HPA

```bash
kubectl apply -f k8s/hpa.yaml
```

### Vérification

```bash
kubectl get hpa -n mlops
kubectl describe hpa iris-api-hpa -n mlops
```

### Test du Scaling

```bash
# Générer de la charge
while true; do curl http://localhost:8000/health; done

# Observer le scaling
watch kubectl get pods -n mlops
kubectl get hpa -n mlops
```

Le HPA scale automatiquement entre 2 et 10 pods selon CPU (70%) et mémoire (80%).

---

## 🧪 Tests et Validation

### Test 1 : Health Check

```bash
make k8s-port-forward  # Terminal 1
curl http://localhost:8000/health  # Terminal 2
```

**Résultat attendu** :
```json
{
  "status": "healthy",
  "model_loaded": true,
  "version": "1.0.0"
}
```

### Test 2 : Prédiction

```bash
export API_KEY=$(kubectl get secret iris-api-secrets -n mlops -o jsonpath='{.data.API_KEY}' | base64 -d)

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

### Test 3 : Logs

```bash
make k8s-logs
# ou
kubectl logs -f deployment/iris-api -n mlops
```

### Test 4 : Scaling Manuel

```bash
kubectl scale deployment iris-api --replicas=3 -n mlops
kubectl get pods -n mlops
```

### Test 5 : Auto-Scaling (HPA)

```bash
# Installer metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Déployer HPA
kubectl apply -f k8s/hpa.yaml

# Générer de la charge
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
| `make k8s-deploy` | Déployer l'API |
| `make k8s-deploy-mlflow` | Déployer API + MLflow server |
| `make k8s-status` | Vérifier le statut |
| `make k8s-logs` | Voir les logs |
| `make k8s-port-forward` | Port-forward vers l'API |
| `make k8s-mlflow-ui` | Port-forward vers MLflow UI |
| `make k8s-test` | Tester l'API |
| `make k8s-clean` | Nettoyer complètement |

### Commandes kubectl Essentielles

```bash
# Voir toutes les ressources
kubectl get all -n mlops

# Décrire un pod
kubectl describe pod <pod-name> -n mlops

# Exécuter une commande dans un pod
kubectl exec -it <pod-name> -n mlops -- /bin/bash

# Voir les événements
kubectl get events -n mlops --sort-by='.lastTimestamp'

# Redémarrer le déploiement
kubectl rollout restart deployment/iris-api -n mlops

# Rollback
kubectl rollout undo deployment/iris-api -n mlops

# Voir les ressources utilisées
kubectl top pods -n mlops
```

---

## 🔒 Sécurité

### Bonnes Pratiques Implémentées

- ✅ **Secrets Kubernetes** : Jamais en clair dans Git
- ✅ **Containers non-root** : `runAsNonRoot: true`, `runAsUser: 1000`
- ✅ **Capabilities limitées** : `drop: [ALL]`
- ✅ **Read-only root filesystem** : Optionnel (désactivé pour logs)
- ✅ **Seccomp profile** : `RuntimeDefault`
- ✅ **TLS via Ingress** : Support HTTPS en production
- ✅ **RBAC** : Permissions limitées par namespace

### Recommandations Production

- 🔐 Utiliser External Secrets Operator avec Secret Manager GCP/AWS
- 🔐 Activer Network Policies pour isolation réseau
- 🔐 Configurer Pod Security Standards
- 🔐 Utiliser cert-manager pour TLS automatique
- 🔐 Activer audit logging
- 🔐 Scanner les images pour vulnérabilités (Trivy, Snyk)

---

## 🔍 Dépannage

### Pods ne démarrent pas

**Symptômes** : `Pending` ou `CrashLoopBackOff`

**Solutions** :
```bash
kubectl describe pod <pod-name> -n mlops
kubectl logs <pod-name> -n mlops
kubectl get events -n mlops --sort-by='.lastTimestamp'

# Causes courantes :
# - Image non trouvée : Vérifier deployment.yaml
# - Secrets manquants : Vérifier secret.yaml
# - Ressources insuffisantes : Vérifier le cluster
```

### API ne répond pas

**Solutions** :
```bash
kubectl get pods -n mlops
kubectl logs -f deployment/iris-api -n mlops
kubectl get service iris-api-service -n mlops

# Tester depuis un pod
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl http://iris-api-service:8000/health
```

### Secrets non trouvés

**Solutions** :
```bash
kubectl get secret iris-api-secrets -n mlops
kubectl describe secret iris-api-secrets -n mlops

# Recréer si nécessaire
kubectl delete secret iris-api-secrets -n mlops
kubectl apply -f k8s/secret.yaml
```

### Image non trouvée

**Avec minikube** :
```bash
eval $(minikube docker-env)
docker build -t iris-api:latest .
```

**Avec Artifact Registry** :
```bash
gcloud auth configure-docker europe-west1-docker.pkg.dev
# Modifier deployment.yaml avec l'image complète
```

### HPA ne fonctionne pas

**Solutions** :
```bash
# Vérifier metrics-server
kubectl get deployment metrics-server -n kube-system

# Installer si nécessaire
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Vérifier les métriques
kubectl top pods -n mlops
kubectl describe hpa iris-api-hpa -n mlops
```

---

## 📊 Métriques

| Métrique | Valeur |
|----------|--------|
| **Fichiers créés** | 10+ manifests Kubernetes |
| **Pods déployés** | 2 (API) + 1 (MLflow) |
| **Services** | 2 (ClusterIP) |
| **Auto-scaling** | 2-10 pods selon charge |
| **Health checks** | Liveness + Readiness |
| **Commandes Make** | 10+ commandes k8s-* |

---

## ✅ Validation des Objectifs

| Objectif | Status | Détails |
|----------|--------|---------|
| **Concepts K8s** | ✅ | Compris : Pods, Deployments, Services, ConfigMaps, Secrets |
| **Installation** | ✅ | minikube/kind installé et cluster créé |
| **Manifests** | ✅ | Tous les manifests créés |
| **Déploiement** | ✅ | API déployée sur le cluster local |
| **Health Checks** | ✅ | Liveness et readiness probes configurés |
| **MLflow Integration** | ✅ | Serveur MLflow déployé et connecté |
| **Auto-Scaling** | ✅ | HPA configuré et fonctionnel |
| **Tests** | ✅ | API accessible et fonctionnelle |
| **Documentation** | ✅ | Guide complet avec exemples |

---

## 🚀 Prochaines Étapes (Phase 6)

- 📊 Observabilité & Monitoring (Prometheus, Grafana)
- 🔍 Métriques avancées
- 📈 Dashboards de monitoring
- 🚨 Alertes et notifications
- 📝 Logging structuré et centralisé

---

## 📚 Ressources

### Documentation

- [Guide Kubernetes](../k8s/README.md) - Guide rapide de déploiement
- [Kubernetes Documentation](https://kubernetes.io/docs/) - Documentation officielle
- [minikube](https://minikube.sigs.k8s.io/) - Cluster local
- [kind](https://kind.sigs.k8s.io/) - Kubernetes in Docker

### Ressources Externes

- [Kubernetes Concepts](https://kubernetes.io/docs/concepts/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [MLflow Kubernetes](https://mlflow.org/docs/latest/tracking.html#scenario-5-mlflow-on-kubernetes)
- [HPA Documentation](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)

---

**🎉 Phase 5 terminée avec succès !**

L'API MLOps est maintenant déployée sur Kubernetes avec :
- ✅ Haute disponibilité (2 replicas)
- ✅ Health checks configurés
- ✅ Configuration et secrets gérés
- ✅ Auto-scaling optionnel (HPA)
- ✅ Serveur MLflow intégré
- ✅ Documentation complète

Le projet est prêt pour la Phase 6 (Observabilité & Monitoring) !
