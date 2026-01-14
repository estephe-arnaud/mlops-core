# 🟣 Phase 5 : Orchestration - Kubernetes avec auto-scaling

## 🧭 Navigation

| ← Précédent | Suivant → |
|-------------|-----------|
| [Phase 4 : Expérimentation](PHASE_4.md) | Phase 6 : Observabilité (à venir) |
| [Retour au README](../README.md) | [Toutes les phases](.) |

## 📋 Table des Matières

1. [Objectif de la Phase](#-objectif-de-la-phase)
2. [Architecture Kubernetes](#-architecture-kubernetes)
3. [Concepts Kubernetes](#-concepts-kubernetes)
4. [Installation](#-installation)
5. [Déploiement](#-déploiement)
6. [Workflows MLflow](#-workflows-mlflow)
7. [Tests et Validation](#-tests-et-validation)
8. [Configuration](#-configuration)
9. [Auto-Scaling](#-auto-scaling)
10. [Commandes Utiles](#-commandes-utiles)
11. [Sécurité](#-sécurité)
12. [Nettoyage](#-nettoyage)
13. [Dépannage](#-dépannage)
14. [Validation des Objectifs](#-validation-des-objectifs)
15. [Prochaines Étapes](#-prochaines-étapes-phase-6)
16. [Ressources](#-ressources)

---

## 🎯 Objectif de la Phase

**Comprendre et pratiquer Kubernetes pour orchestrer des applications containerisées**

### ❓ Questions Clés
- Qu'est-ce qu'un Pod, un Deployment et un Service ?
- Comment exposer une application dockerisée dans un cluster K8s ?
- Comment gérer les configurations et secrets dans Kubernetes ?
- Comment mettre en place le scaling automatique ?

### ⏱️ Répartition des Heures (20h)
- **8h** → Apprentissage des concepts K8s (Pods, Deployments, Services)
- **8h** → Installation et utilisation de minikube/kind localement
- **4h** → Déploiement de l'API ML dockerisée sur le cluster local K8s

---

## 🏗️ Architecture Kubernetes

### Vue d'ensemble du Cluster

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    CLUSTER KUBERNETES (1 nœud)                          │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                      Namespace: mlops                             │  │
│  │                                                                   │  │
│  │  ┌─────────────────────────────────────────────────────────────┐  │  │
│  │  │                    Deployment: iris-api                     │  │  │
│  │  │                    (gère 2 replicas)                        │  │  │
│  │  │                                                             │  │  │
│  │  │  ┌──────────────┐              ┌──────────────┐             │  │  │
│  │  │  │ Pod iris-api │              │ Pod iris-api │             │  │  │
│  │  │  │ Container:   │              │ Container:   │             │  │  │
│  │  │  │ iris-api     │              │ iris-api     │             │  │  │
│  │  │  │ Port: 8000   │              │ Port: 8000   │             │  │  │
│  │  │  │              │              │              │             │  │  │
│  │  │  │ Env:         │              │ Env:         │             │  │  │
│  │  │  │ • ConfigMap  │              │ • ConfigMap  │             │  │  │
│  │  │  │ • Secret     │              │ • Secret     │             │  │  │
│  │  │  │              │              │              │             │  │  │
│  │  │  │ Volume:      │              │ Volume:      │             │  │  │
│  │  │  │ /app/mlruns  │              │ /app/mlruns  │             │  │  │
│  │  │  └──────┬───────┘              └──────┬───────┘             │  │  │
│  │  │         │                             │                     │  │  │
│  │  │         └──────────┬──────────────────┘                     │  │  │
│  │  │                    │                                        │  │  │
│  │  │         ┌──────────▼──────────┐                             │  │  │
│  │  │         │ Service:            │                             │  │  │
│  │  │         │ iris-api-service    │                             │  │  │
│  │  │         │ Type: ClusterIP     │                             │  │  │
│  │  │         │ Port: 8000          │                             │  │  │
│  │  │         │ Load Balancing      │                             │  │  │
│  │  │         └─────────────────────┘                             │  │  │
│  │  └─────────────────────────────────────────────────────────────┘  │  │
│  │                                                                   │  │
│  │  ┌─────────────────────────────────────────────────────────────┐  │  │
│  │  │                  Deployment: mlflow-server                  │  │  │
│  │  │                  (gère 1 replica)                           │  │  │
│  │  │                                                             │  │  │
│  │  │  ┌──────────────────────────────────────┐                   │  │  │
│  │  │  │ Pod mlflow-server                    │                   │  │  │
│  │  │  │ Container: mlflow-server             │                   │  │  │
│  │  │  │ Port: 5000                           │                   │  │  │
│  │  │  │ Volume: /mlruns                      │                   │  │  │
│  │  │  └──────┬───────────────────────────────┘                   │  │  │
│  │  │         │                                                   │  │  │
│  │  │  ┌──────▼─────────┐                                         │  │  │
│  │  │  │ Service:       │                                         │  │  │
│  │  │  │ mlflow-server- │                                         │  │  │
│  │  │  │ service        │                                         │  │  │
│  │  │  │ Type: ClusterIP│                                         │  │  │
│  │  │  │ Port: 5000     │                                         │  │  │
│  │  │  └────────────────┘                                         │  │  │
│  │  └─────────────────────────────────────────────────────────────┘  │  │
│  │                                                                   │  │
│  │  ┌─────────────────────────────────────────────────────────────┐  │  │
│  │  │                    Volume: mlruns-volume                    │  │  │
│  │  │                    Type: hostPath                           │  │  │
│  │  │                    Path: /tmp/mlruns (sur le nœud)          │  │  │
│  │  │                                                             │  │  │
│  │  │  Monté dans:                                                │  │  │
│  │  │  ┌──────────────────┐  ┌──────────────────┐                 │  │  │
│  │  │  │ iris-api pods    │  │ mlflow-server pod│                 │  │  │
│  │  │  │ → /app/mlruns    │  │ → /mlruns        │                 │  │  │
│  │  │  └──────────────────┘  └──────────────────┘                 │  │  │
│  │  └─────────────────────────────────────────────────────────────┘  │  │
│  │                                                                   │  │
│  │  ┌─────────────────────────────────────────────────────────────┐  │  │
│  │  │              ConfigMap: iris-api-config                     │  │  │
│  │  │              Secret: iris-api-secrets                       │  │  │
│  │  │              HPA: iris-api-hpa                              │  │  │
│  │  └─────────────────────────────────────────────────────────────┘  │  │
│  │                                                                   │  │
│  │  Connexions HTTP:                                                 │  │
│  │  iris-api pods ──HTTP:5000──► mlflow-server-service               │  │
│  └───────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

### Flux de Trafic

```
Client (externe)
    │
    │ HTTP/HTTPS
    ▼
┌─────────────────┐
│ Ingress         │  (Optionnel, pour exposition externe)
│ (nginx/traefik) │
└────────┬────────┘
         │
         │ HTTP:8000
         ▼
┌─────────────────┐
│ Service         │  ──Load Balance──► Pod iris-api (1)
│ iris-api-service│  ──Load Balance──► Pod iris-api (2)
└─────────────────┘

Pod iris-api
    │
    │ HTTP:5000 (interne)
    ▼
┌─────────────────┐
│ Service         │  ──► Pod mlflow-server
│ mlflow-server-  │
│ service         │
└─────────────────┘
```

### Composants Kubernetes

| Composant | Rôle | Exemple |
|-----------|------|---------|
| **Namespace** | Isolation logique | `mlops` |
| **Deployment** | Gère les pods (création, redémarrage, scaling) | `iris-api`, `mlflow-server` |
| **Pod** | Conteneur(s) qui exécute(nt) l'application | `iris-api-xxx`, `mlflow-server-xxx` |
| **Service** | DNS stable + load balancing | `iris-api-service`, `mlflow-server-service` |
| **ConfigMap** | Configuration non sensible | `iris-api-config` |
| **Secret** | Configuration sensible (chiffré) | `iris-api-secrets` |
| **Volume** | Stockage partagé entre pods | `mlruns-volume` (hostPath) |
| **HPA** | Auto-scaling basé sur métriques | `iris-api-hpa` |
| **Ingress** | Exposition HTTP/HTTPS externe | `iris-api-ingress` |

### Livrables Créés

```
mlops-core/
├── k8s/                          # Manifests Kubernetes
│   ├── namespace.yaml            # Namespace mlops
│   ├── deployment.yaml           # Deployment API (2 replicas)
│   ├── mlflow-deployment.yaml    # Deployment MLflow (1 replica)
│   ├── service.yaml              # Service ClusterIP API
│   ├── mlflow-service.yaml      # Service ClusterIP MLflow
│   ├── configmap.yaml            # Configuration non sensible
│   ├── secret.yaml.example        # Template secrets
│   ├── ingress.yaml              # Ingress (production)
│   ├── hpa.yaml                  # Auto-scaling
│   └── README.md                 # Guide déploiement
├── scripts/
│   └── setup-k8s.sh              # Installation minikube/kind
└── docs/
    └── PHASE_5.md                # Cette documentation
```

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

## 🚀 Installation

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

## 🚀 Déploiement

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

# 2. Déployer (MLFLOW_TRACKING_URI="http://mlflow-server-service:5000")
make k8s-deploy-mlflow

# 3. Vérifier
kubectl exec -it deployment/mlflow-server -n mlops -- ls -la /mlruns
```

### Workflow 2 : Réentraînement vers MLflow Server

**Objectif** : Entraîner un nouveau modèle vers le serveur MLflow

> **💡 Pas besoin de mount** : Les données sont envoyées via HTTP au serveur MLflow

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

# Vérifier
kubectl get hpa -n mlops

# Générer de la charge
while true; do curl http://localhost:8000/health; done

# Observer le scaling
watch kubectl get pods -n mlops
```

---

## 🔧 Configuration

### Variables d'Environnement

**ConfigMap** (`configmap.yaml`) :
- `ENVIRONMENT`: production
- `MODEL_DIR`: /app/models
- `LOG_LEVEL`: INFO

**Secret** (`secret.yaml`) :
- `API_KEY`: Clé API pour authentification
- `MLFLOW_TRACKING_URI`: 
  - `"http://mlflow-server-service:5000"` → Serveur MLflow dans K8s
  - `""` → Local avec hostPath (nécessite mount)
  - `"gs://bucket/mlruns/"` → GCS (production cloud)

### Modes MLflow

| Mode | MLFLOW_TRACKING_URI | Volume | Usage |
|------|---------------------|--------|-------|
| **K8s Server** | `http://mlflow-server-service:5000` | Partagé | Portfolio/Production |
| **Local** | `""` | hostPath + mount | Développement |
| **GCS** | `gs://bucket/mlruns/` | Aucun | Production cloud |

---

## 📊 Auto-Scaling

```bash
# Installer metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Déployer HPA
kubectl apply -f k8s/hpa.yaml

# Vérifier
kubectl get hpa -n mlops
```

Le HPA scale automatiquement entre 2 et 10 pods selon CPU/mémoire.

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

---

## 🔒 Sécurité

- ✅ Secrets Kubernetes (jamais en clair dans Git)
- ✅ Containers non-root (securityContext)
- ✅ Capabilities limitées
- ✅ TLS via Ingress en production

---

## 🗑️ Nettoyage

```bash
make k8s-clean
# ou
kubectl delete namespace mlops
```

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

## ✅ Validation des Objectifs

| Objectif | Status | Détails |
|----------|--------|---------|
| **Concepts K8s** | ✅ | Compris : Pods, Deployments, Services, ConfigMaps, Secrets |
| **Installation** | ✅ | minikube/kind installé et cluster créé |
| **Manifests** | ✅ | Tous les manifests créés |
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
- ✅ Serveur MLflow intégré
- ✅ Documentation complète

Le projet est prêt pour la Phase 6 (Observabilité & Monitoring) !

---

## 📚 Ressources

- [Guide Kubernetes](../k8s/README.md) - Guide rapide de déploiement
- [Kubernetes Documentation](https://kubernetes.io/docs/) - Documentation officielle
- [minikube](https://minikube.sigs.k8s.io/) - Cluster local
- [kind](https://kind.sigs.k8s.io/) - Kubernetes in Docker
