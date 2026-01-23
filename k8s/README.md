# 🚀 Guide de Déploiement Kubernetes

> 📚 **Documentation complète** : Consultez [`docs/PHASE_5.md`](../docs/PHASE_5.md) pour la documentation détaillée avec tous les concepts, workflows, et exemples.

## 📋 Vue d'Ensemble

Ce répertoire contient tous les manifests Kubernetes nécessaires pour déployer l'API MLOps sur un cluster Kubernetes. Le déploiement inclut :

- **API FastAPI** : 2 replicas pour haute disponibilité
- **Serveur MLflow** : 1 replica pour le tracking des expériences
- **Services** : ClusterIP pour accès interne
- **Configuration** : ConfigMap et Secrets
- **Auto-Scaling** : HPA (Horizontal Pod Autoscaler)
- **Exposition** : Ingress pour production

## 🏗️ Structure des Manifests

```
k8s/
├── namespace.yaml              # Namespace mlops
├── deployment.yaml             # Deployment API (2 replicas)
├── mlflow-deployment.yaml      # Deployment MLflow server
├── service.yaml                # Service ClusterIP API
├── mlflow-service.yaml        # Service ClusterIP MLflow
├── service-nodeport.yaml      # Service NodePort (dev/test)
├── configmap.yaml             # Configuration non sensible
├── secret.yaml.example         # Template secrets
├── ingress.yaml                # Ingress (production)
├── hpa.yaml                    # Auto-scaling
└── README.md                   # Ce fichier
```

## 🚀 Déploiement Rapide

### Prérequis

- `kubectl` installé et configuré
- Cluster Kubernetes accessible (minikube, kind, ou cloud)
- Image Docker `iris-api:latest` disponible

### Étape 1 : Préparer les Secrets

```bash
# Copier le template
cp k8s/secret.yaml.example k8s/secret.yaml

# Éditer avec vos valeurs
# ⚠️ Ne JAMAIS commiter secret.yaml !
```

**Contenu minimal de `k8s/secret.yaml`** :
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: iris-api-secrets
  namespace: mlops
type: Opaque
stringData:
  API_KEY: "votre-api-key-ici"  # Générer : openssl rand -hex 32
  MLFLOW_TRACKING_URI: "http://mlflow-server-service:5000"  # Ou "gs://bucket/mlruns/"
```

### Étape 2 : Déployer

**Option A : Avec MLflow Server** (Recommandé)

```bash
make k8s-deploy-mlflow
```

**Option B : MLflow Local** (Développement)

```bash
# 1. Monter mlruns/ vers minikube (terminal séparé)
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

### Étape 3 : Vérifier

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

### Étape 4 : Accéder

**API** :
```bash
make k8s-port-forward      # http://localhost:8000
```

**MLflow UI** :
```bash
make k8s-mlflow-ui         # http://localhost:5000
```

## 📝 Commandes Utiles

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

## 🧪 Tests

### Test de Santé

```bash
make k8s-port-forward  # Terminal 1
curl http://localhost:8000/health  # Terminal 2
```

### Test de Prédiction

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

### Test Automatisé

```bash
make k8s-test
```

## ⚖️ Auto-Scaling

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

Le HPA scale automatiquement entre 2 et 10 pods selon CPU (70%) et mémoire (80%).

## 🌐 Exposition Externe

### NodePort (Développement/Test)

```bash
kubectl apply -f k8s/service-nodeport.yaml
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
curl http://$NODE_IP:30080/health
```

### Ingress (Production)

```bash
# Installer Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

# Déployer l'Ingress
kubectl apply -f k8s/ingress.yaml
```

**⚠️ Important** : Modifier `k8s/ingress.yaml` avec votre domaine réel avant de déployer.

## 🔍 Dépannage

### Pods ne démarrent pas

```bash
kubectl describe pod <pod-name> -n mlops
kubectl logs <pod-name> -n mlops
kubectl get events -n mlops --sort-by='.lastTimestamp'
```

### API ne répond pas

```bash
kubectl get pods -n mlops
kubectl logs -f deployment/iris-api -n mlops
kubectl get service iris-api-service -n mlops
```

### Secrets non trouvés

```bash
kubectl get secret iris-api-secrets -n mlops
kubectl describe secret iris-api-secrets -n mlops
```

### Image non trouvée (minikube)

```bash
eval $(minikube docker-env)
docker build -t iris-api:latest .
```

## 📚 Documentation

- [📖 Phase 5 : Orchestration](../docs/PHASE_5.md) - Documentation complète avec :
  - Architecture détaillée
  - Concepts Kubernetes
  - Installation et configuration
  - Workflows MLflow
  - Tests et validation
  - Dépannage
- [Makefile](../Makefile) - Toutes les commandes `make k8s-*`

## 🔒 Sécurité

### Bonnes Pratiques

- ✅ Secrets Kubernetes (jamais en clair dans Git)
- ✅ Containers non-root
- ✅ Capabilities limitées
- ✅ TLS via Ingress en production

### Recommandations Production

- 🔐 Utiliser External Secrets Operator avec Secret Manager GCP/AWS
- 🔐 Activer Network Policies
- 🔐 Configurer Pod Security Standards
- 🔐 Utiliser cert-manager pour TLS automatique
- 🔐 Scanner les images pour vulnérabilités

## 🗑️ Nettoyage

```bash
make k8s-clean
# ou
kubectl delete namespace mlops
```

---

**💡 Astuce** : Pour une compréhension approfondie des concepts Kubernetes et des workflows détaillés, consultez [`docs/PHASE_5.md`](../docs/PHASE_5.md).
