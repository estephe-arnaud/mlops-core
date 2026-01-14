# 🚀 Guide de Déploiement Kubernetes

Ce dossier contient tous les manifests Kubernetes nécessaires pour déployer l'API MLOps sur un cluster Kubernetes.

## 📋 Structure des Fichiers

| Fichier | Description |
|---------|-------------|
| `namespace.yaml` | Namespace dédié pour l'application |
| `deployment.yaml` | Déploiement de l'API avec 2 replicas |
| `service.yaml` | Service ClusterIP pour accès interne |
| `service-nodeport.yaml` | Service NodePort pour accès externe (dev/test) |
| `configmap.yaml` | Configuration non sensible (variables d'environnement) |
| `secret.yaml.example` | Template pour les secrets (à copier vers `secret.yaml`) |
| `ingress.yaml` | Ingress pour exposition HTTP/HTTPS (production) |
| `hpa.yaml` | Horizontal Pod Autoscaler pour auto-scaling |

## 🚀 Déploiement Rapide

### Prérequis

1. **Cluster Kubernetes** : minikube, kind, ou GKE
2. **kubectl** : Outil en ligne de commande Kubernetes
3. **Image Docker** : `iris-api:latest` (ou depuis Artifact Registry)

### Étapes

#### 1. Préparer les Secrets

```bash
# Copier le template
cp k8s/secret.yaml.example k8s/secret.yaml

# Éditer avec vos valeurs
# ⚠️ Ne JAMAIS commiter secret.yaml !
```

#### 2. Déployer l'Application

```bash
# Créer le namespace
kubectl apply -f k8s/namespace.yaml

# Créer le ConfigMap
kubectl apply -f k8s/configmap.yaml

# Créer le Secret
kubectl apply -f k8s/secret.yaml

# Déployer l'application
kubectl apply -f k8s/deployment.yaml

# Créer le Service
kubectl apply -f k8s/service.yaml
```

#### 3. Vérifier le Déploiement

```bash
# Vérifier les pods
kubectl get pods -n mlops

# Vérifier les services
kubectl get services -n mlops

# Voir les logs
kubectl logs -f deployment/iris-api -n mlops
```

#### 4. Accéder à l'API

**Option 1 : Port-forward (développement)**
```bash
kubectl port-forward service/iris-api-service 8000:8000 -n mlops
# API accessible sur http://localhost:8000
```

**Option 2 : NodePort (test)**
```bash
kubectl apply -f k8s/service-nodeport.yaml
# API accessible sur http://<node-ip>:30080
```

**Option 3 : Ingress (production)**
```bash
kubectl apply -f k8s/ingress.yaml
# API accessible via le domaine configuré
```

## 🔧 Configuration

### Variables d'Environnement

Les variables non sensibles sont dans `configmap.yaml` :
- `ENVIRONMENT`: production
- `MODEL_DIR`: /app/models
- `LOG_LEVEL`: INFO

Les variables sensibles sont dans `secret.yaml` :
- `API_KEY`: Clé API pour l'authentification
- `MLFLOW_TRACKING_URI`: URI MLflow (ex: `gs://bucket/mlruns/`)

### Image Docker

Par défaut, le deployment utilise `iris-api:latest`. Pour utiliser une image depuis Artifact Registry :

```yaml
# Dans deployment.yaml
image: europe-west1-docker.pkg.dev/PROJECT_ID/mlops-repo/iris-api:latest
imagePullPolicy: Always
```

### Ressources

Les ressources par défaut sont :
- **Requests** : 256Mi mémoire, 100m CPU
- **Limits** : 512Mi mémoire, 500m CPU

Ajustez selon vos besoins dans `deployment.yaml`.

## 📊 Auto-Scaling

Pour activer l'auto-scaling :

```bash
# Installer metrics-server (si nécessaire)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Déployer le HPA
kubectl apply -f k8s/hpa.yaml

# Vérifier
kubectl get hpa -n mlops
```

## 🔍 Monitoring

### Health Checks

L'API expose un endpoint `/health` utilisé pour les probes :
- **Liveness** : Vérifie que l'API est vivante
- **Readiness** : Vérifie que l'API est prête à recevoir du trafic

### Métriques Prometheus

L'API expose des métriques Prometheus sur `/metrics` :
```bash
kubectl port-forward service/iris-api-service 8000:8000 -n mlops
curl http://localhost:8000/metrics
```

## 🛠️ Commandes Utiles

```bash
# Voir tous les ressources
kubectl get all -n mlops

# Décrire un pod
kubectl describe pod <pod-name> -n mlops

# Exécuter une commande dans un pod
kubectl exec -it <pod-name> -n mlops -- /bin/bash

# Redémarrer le déploiement
kubectl rollout restart deployment/iris-api -n mlops

# Voir l'historique des déploiements
kubectl rollout history deployment/iris-api -n mlops

# Rollback vers une version précédente
kubectl rollout undo deployment/iris-api -n mlops
```

## 🔒 Sécurité

### Bonnes Pratiques de Sécurité

- ✅ **Secrets** : Utiliser Kubernetes Secrets (ou External Secrets Operator avec Secret Manager)
- ✅ **RBAC** : Limiter les permissions avec des ServiceAccounts dédiés
- ✅ **Security Context** : Containers non-root avec capabilities limitées
- ✅ **Image Scanning** : Scanner les images Docker pour vulnérabilités
- ✅ **TLS** : Utiliser HTTPS via Ingress en production

## 🗑️ Suppression

```bash
# Supprimer tous les ressources
kubectl delete -f k8s/

# Ou supprimer le namespace (supprime tout)
kubectl delete namespace mlops
```

## 📚 Documentation Complète

Consultez [`docs/PHASE_5.md`](../docs/PHASE_5.md) pour la documentation complète de la Phase 5.

