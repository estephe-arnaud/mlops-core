# 🏗️ Architecture Kubernetes Détaillée

Ce document explique en détail l'architecture Kubernetes du projet, avec les applications nginx, mlflow-server et iris-api dans leurs pods respectifs au sein du nœud avec les namespaces associés.

## 📋 Table des Matières

1. [Vue d'ensemble](#-vue-densemble)
2. [Architecture en Parallèle](#-architecture-en-parallèle)
3. [Namespaces](#-namespaces)
4. [Applications et Pods](#-applications-et-pods)
5. [Services](#-services)
6. [Flux de Trafic](#-flux-de-trafic)
7. [Communication Inter-Namespace](#-communication-inter-namespace)
8. [Volumes Partagés](#-volumes-partagés)

---

## 🎯 Vue d'ensemble

Le cluster Kubernetes héberge **3 applications principales** réparties dans **2 namespaces** :

| Application | Namespace | Rôle |
|-------------|-----------|------|
| **nginx** (Ingress Controller) | `ingress-nginx` | Reverse proxy, routage HTTP/HTTPS |
| **iris-api** (FastAPI) | `mlops` | API ML pour prédictions |
| **mlflow-server** (MLflow) | `mlops` | Tracking et gestion des modèles ML |

---

## 🏗️ Architecture en Parallèle

```
┌───────────────────────────────────────────────────────────────────────────┐
│                    NŒUD KUBERNETES (Node)                                 │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │  Namespace: ingress-nginx (ou kube-system)                          │  │
│  │                                                                     │  │
│  │  ┌─────────────────────────────────────────────────────────────┐    │  │
│  │  │  Deployment: ingress-nginx-controller                       │    │  │
│  │  │  (gère 1+ replicas)                                         │    │  │
│  │  │                                                             │    │  │
│  │  │  ┌──────────────────────────────────────┐                   │    │  │
│  │  │  │  Pod: ingress-nginx-controller-xxx   │                   │    │  │
│  │  │  │                                      │                   │    │  │
│  │  │  │  Container: controller               │                   │    │  │
│  │  │  │  Application: nginx                  │                   │    │  │
│  │  │  │  Ports: 80, 443                      │                   │    │  │
│  │  │  │                                      │                   │    │  │
│  │  │  │  Rôle: Reverse proxy                 │                   │    │  │
│  │  │  │  - Lit les règles Ingress            │                   │    │  │
│  │  │  │  - Route le trafic                   │                   │    │  │
│  │  │  │  - Gère TLS/HTTPS                    │                   │    │  │
│  │  │  │  - Rate limiting                     │                   │    │  │
│  │  │  │  - CORS                              │                   │    │  │
│  │  │  └──────────┬───────────────────────────┘                   │    │  │
│  │  │             │                                               │    │  │
│  │  │  ┌──────────▼──────────┐                                    │    │  │
│  │  │  │  Service:           │                                    │    │  │
│  │  │  │  ingress-nginx-     │                                    │    │  │
│  │  │  │  controller         │                                    │    │  │
│  │  │  │  Type: LoadBalancer │                                    │    │  │
│  │  │  │  Ports: 80, 443     │                                    │    │  │
│  │  │  │  Expose: Internet   │                                    │    │  │
│  │  │  └─────────────────────┘                                    │    │  │
│  │  └─────────────────────────────────────────────────────────────┘    │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │  Namespace: mlops                                                   │  │
│  │                                                                     │  │
│  │  ┌─────────────────────────────────────────────────────────────┐    │  │
│  │  │  Deployment: iris-api                                       │    │  │
│  │  │  (gère 2 replicas)                                          │    │  │
│  │  │                                                             │    │  │
│  │  │  ┌──────────────┐              ┌──────────────┐             │    │  │
│  │  │  │  Pod:        │              │  Pod:        │             │    │  │
│  │  │  │  iris-api-   │              │  iris-api-   │             │    │  │
│  │  │  │  xxx-1       │              │  xxx-2       │             │    │  │
│  │  │  │              │              │              │             │    │  │
│  │  │  │  Container:  │              │  Container:  │             │    │  │
│  │  │  │  iris-api    │              │  iris-api    │             │    │  │
│  │  │  │  Application:│              │  Application:│             │    │  │
│  │  │  │  FastAPI     │              │  FastAPI     │             │    │  │
│  │  │  │  Port: 8000  │              │  Port: 8000  │             │    │  │
│  │  │  │              │              │              │             │    │  │
│  │  │  │  Rôle: API   │              │  Rôle: API   │             │    │  │
│  │  │  │  ML          │              │  ML          │             │    │  │
│  │  │  │  - Prédictions              │  - Prédictions             │    │  │
│  │  │  │  - Health checks            │  - Health checks           │    │  │
│  │  │  │  - Métriques                │  - Métriques               │    │  │
│  │  │  │                             │                            │    │  │
│  │  │  │  Volume:                    │  Volume:                   │    │  │
│  │  │  │  /app/mlruns                │  /app/mlruns               │    │  │
│  │  │  │  (partagé avec mlflow)      │  (partagé avec mlflow)     │    │  │
│  │  │  └──────┬───────┘              └──────┬───────┘             │    │  │
│  │  │         │                             │                     │    │  │
│  │  │         └──────────┬──────────────────┘                     │    │  │
│  │  │                    │                                        │    │  │
│  │  │         ┌──────────▼──────────┐                             │    │  │
│  │  │         │  Service:           │                             │    │  │
│  │  │         │  iris-api-service   │                             │    │  │
│  │  │         │  Type: ClusterIP    │                             │    │  │
│  │  │         │  Port: 8000         │                             │    │  │
│  │  │         │  DNS: iris-api-     │                             │    │  │
│  │  │         │  service.mlops.svc. │                             │    │  │
│  │  │         │  cluster.local      │                             │    │  │
│  │  │         │  Load Balancing     │                             │    │  │
│  │  │         └─────────────────────┘                             │    │  │
│  │  └─────────────────────────────────────────────────────────────┘    │  │
│  │                                                                     │  │
│  │  ┌─────────────────────────────────────────────────────────────┐    │  │
│  │  │  Deployment: mlflow-server                                  │    │  │
│  │  │  (gère 1 replica)                                           │    │  │
│  │  │                                                             │    │  │
│  │  │  ┌──────────────────────────────────────┐                   │    │  │
│  │  │  │  Pod: mlflow-server-xxx              │                   │    │  │
│  │  │  │                                      │                   │    │  │
│  │  │  │  Container: mlflow-server            │                   │    │  │
│  │  │  │  Application: MLflow                 │                   │    │  │
│  │  │  │  Port: 5000                          │                   │    │  │
│  │  │  │                                      │                   │    │  │
│  │  │  │  Rôle: Tracking ML                   │                   │    │  │
│  │  │  │  - Stocke les runs ML                │                   │    │  │
│  │  │  │  - Sert les modèles                  │                   │    │  │
│  │  │  │  - UI MLflow (http://...:5000)       │                   │    │  │
│  │  │  │  - API REST MLflow                   │                   │    │  │
│  │  │  │                                      │                   │    │  │
│  │  │  │  Volume:                             │                   │    │  │
│  │  │  │  /mlruns                             │                   │    │  │
│  │  │  │  (partagé avec iris-api)             │                   │    │  │
│  │  │  └──────┬───────────────────────────────┘                   │    │  │
│  │  │         │                                                   │    │  │
│  │  │  ┌──────▼──────────┐                                        │    │  │
│  │  │  │  Service:       │                                        │    │  │
│  │  │  │  mlflow-server- │                                        │    │  │
│  │  │  │  service        │                                        │    │  │
│  │  │  │  Type: ClusterIP│                                        │    │  │
│  │  │  │  Port: 5000     │                                        │    │  │
│  │  │  │  DNS: mlflow-   │                                        │    │  │
│  │  │  │  server-service.│                                        │    │  │
│  │  │  │  mlops.svc.     │                                        │    │  │
│  │  │  │  cluster.local  │                                        │    │  │
│  │  │  └─────────────────┘                                        │    │  │
│  │  └─────────────────────────────────────────────────────────────┘    │  │
│  │                                                                     │  │
│  │  ┌─────────────────────────────────────────────────────────────┐    │  │
│  │  │  Volume Partagé: mlruns-volume                              │    │  │
│  │  │  Type: hostPath                                             │    │  │
│  │  │  Path: /tmp/mlruns (sur le nœud)                            │    │  │
│  │  │                                                             │    │  │
│  │  │  Monté dans:                                                │    │  │
│  │  │  ┌──────────────────┐  ┌──────────────────┐                 │    │  │
│  │  │  │ iris-api pods    │  │ mlflow-server pod│                 │    │  │
│  │  │  │ → /app/mlruns    │  │ → /mlruns        │                 │    │  │
│  │  │  └──────────────────┘  └──────────────────┘                 │    │  │
│  │  └─────────────────────────────────────────────────────────────┘    │  │
│  │                                                                     │  │
│  │  ┌─────────────────────────────────────────────────────────────┐    │  │
│  │  │  Ingress: iris-api-ingress                                  │    │  │
│  │  │  (règles de routage)                                        │    │  │
│  │  │                                                             │    │  │
│  │  │  Règles:                                                    │    │  │
│  │  │  - host: iris-api.example.com                               │    │  │
│  │  │    path: /                                                  │    │  │
│  │  │    → Service: iris-api-service                              │    │  │
│  │  │                                                             │    │  │
│  │  │  ⚠️ Lue par nginx dans ingress-nginx namespace              │    │  │
│  │  └─────────────────────────────────────────────────────────────┘    │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────────┘
```

---

## 📦 Namespaces

### Namespace `ingress-nginx`

**Rôle** : Héberge l'Ingress Controller nginx

**Ressources** :
- Deployment `ingress-nginx-controller`
- Service `ingress-nginx-controller` (LoadBalancer)
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

### Namespace `mlops`

**Rôle** : Héberge les applications métier (API et MLflow)

**Ressources** :
- Deployment `iris-api` (2 replicas)
- Deployment `mlflow-server` (1 replica)
- Services `iris-api-service` et `mlflow-server-service`
- ConfigMap `iris-api-config`
- Secret `iris-api-secrets`
- Ingress `iris-api-ingress`
- HPA `iris-api-hpa` (optionnel)

**Création** :
```bash
kubectl apply -f k8s/namespace.yaml
```

**Vérification** :
```bash
kubectl get all -n mlops
```

---

## 🚀 Applications et Pods

### 1. Nginx Ingress Controller

**Namespace** : `ingress-nginx` (ou `kube-system`)

**Deployment** : `ingress-nginx-controller`

**Pod** : `ingress-nginx-controller-<hash>`

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
```yaml
Type: LoadBalancer  # En production cloud
# ou
Type: NodePort      # En local (minikube/kind)
```

**Accès** :
- Production : IP publique du LoadBalancer
- Local : `http://<node-ip>:<nodePort>`

### 2. Iris API (FastAPI)

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
```yaml
Type: ClusterIP  # Accès interne uniquement
DNS: iris-api-service.mlops.svc.cluster.local
```

**Accès** :
- Depuis nginx : `http://iris-api-service:8000`
- Depuis mlflow-server : `http://iris-api-service:8000`
- Depuis l'extérieur : Via port-forward ou Ingress

### 3. MLflow Server

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
```yaml
Type: ClusterIP  # Accès interne uniquement
DNS: mlflow-server-service.mlops.svc.cluster.local
```

**Accès** :
- Depuis iris-api : `http://mlflow-server-service:5000`
- Depuis l'extérieur : Via port-forward (`make k8s-mlflow-ui`)

---

## 🔗 Services

### Service nginx (Ingress Controller)

**Namespace** : `ingress-nginx`

**Nom** : `ingress-nginx-controller`

**Type** : `LoadBalancer` (production) ou `NodePort` (local)

**Ports** :
- 80 → 80 (HTTP)
- 443 → 443 (HTTPS)

**Rôle** : Expose nginx vers Internet

**Accès** :
```bash
# Production
curl http://<load-balancer-ip>/health

# Local (NodePort)
curl http://<node-ip>:<nodePort>/health
```

### Service iris-api

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
    name: iris-api-service  # ← Service dans namespace mlops
    port:
      number: 8000
```

### Service mlflow-server

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

---

## 🌊 Flux de Trafic

### Flux 1 : Client → API (via Ingress)

```
1. Client Internet
   ↓ HTTP/HTTPS
   iris-api.example.com
   
2. DNS résout vers
   ↓
   IP LoadBalancer (nginx)
   
3. Service ingress-nginx-controller
   ↓
   Pod nginx (namespace: ingress-nginx)
   
4. Nginx lit les règles Ingress
   ↓ (cherche dans TOUS les namespaces)
   Ingress iris-api-ingress (namespace: mlops)
   
5. Nginx route vers
   ↓ HTTP:8000
   Service iris-api-service (namespace: mlops)
   
6. Service load balance vers
   ↓
   Pod iris-api-xxx-1 OU Pod iris-api-xxx-2
   
7. FastAPI traite la requête
   ↓
   Réponse HTTP
```

### Flux 2 : API → MLflow Server (interne)

```
1. Pod iris-api
   ↓ HTTP:5000
   Service mlflow-server-service (namespace: mlops)
   
2. Service route vers
   ↓
   Pod mlflow-server (namespace: mlops)
   
3. MLflow traite la requête
   ↓
   Retourne le modèle ou les métadonnées
   
4. Pod iris-api charge le modèle
   ↓
   Utilise pour les prédictions
```

### Flux 3 : Port-Forward (développement)

```
1. Votre machine locale
   ↓ kubectl port-forward
   Service iris-api-service (namespace: mlops)
   
2. Service load balance vers
   ↓
   Pod iris-api-xxx-1 OU Pod iris-api-xxx-2
   
3. FastAPI traite la requête
   ↓
   Réponse HTTP sur localhost:8000
```

**Note** : Le port-forward contourne complètement nginx et l'Ingress.

---

## 🔄 Communication Inter-Namespace

Kubernetes permet la communication entre namespaces via le DNS interne.

### Format DNS Kubernetes

```
<service-name>.<namespace>.svc.cluster.local
```

### Exemples dans votre architecture

#### 1. Nginx → Iris API

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

#### 2. Iris API → MLflow Server

```python
# Dans secret.yaml (namespace: mlops)
MLFLOW_TRACKING_URI: "http://mlflow-server-service:5000"
# ou explicitement :
# MLFLOW_TRACKING_URI: "http://mlflow-server-service.mlops.svc.cluster.local:5000"
```

**DNS utilisé** : `mlflow-server-service.mlops.svc.cluster.local:5000`

### Raccourci DNS

Dans le même namespace, vous pouvez utiliser juste le nom du service :

```python
# Dans namespace mlops
MLFLOW_TRACKING_URI: "http://mlflow-server-service:5000"
# Équivalent à :
# MLFLOW_TRACKING_URI: "http://mlflow-server-service.mlops.svc.cluster.local:5000"
```

### Communication Cross-Namespace

Pour appeler un service d'un autre namespace, utilisez le FQDN complet :

```python
# Depuis namespace mlops, appeler un service dans ingress-nginx
http://ingress-nginx-controller.ingress-nginx.svc.cluster.local:80
```

---

## 💾 Volumes Partagés

### Volume `mlruns-volume`

**Type** : `hostPath`

**Path sur le nœud** : `/tmp/mlruns`

**Monté dans** :

#### 1. Pods iris-api

```yaml
volumeMounts:
- name: mlruns-volume
  mountPath: /app/mlruns  # Où le code Python cherche mlruns/
  readOnly: false
```

**Usage** :
- ✅ Nécessaire si `MLFLOW_TRACKING_URI=""` (mode local)
- ❌ Pas nécessaire si `MLFLOW_TRACKING_URI="http://mlflow-server-service:5000"` (mode serveur)

#### 2. Pod mlflow-server

```yaml
volumeMounts:
- name: mlruns-volume
  mountPath: /mlruns  # MLflow stocke tout ici
  readOnly: false
```

**Usage** :
- ✅ Toujours nécessaire (mlflow-server stocke les données ici)

### Partage de Données

```
Machine hôte
    ↓ (mount)
/tmp/mlruns (sur le nœud)
    ↓ (hostPath volume)
┌─────────────────┬──────────────────┐
│ Pod iris-api    │ Pod mlflow-server│
│ /app/mlruns     │ /mlruns          │
└─────────────────┴──────────────────┘
```

**Workflow avec MLflow Server** :
1. MLflow server stocke dans `/mlruns` (volume partagé)
2. Iris-api charge via HTTP : `http://mlflow-server-service:5000`
3. Le volume n'est pas utilisé par iris-api (mais nécessaire pour mlflow-server)

**Workflow Local** :
1. Modèle dans `/app/mlruns` (volume partagé)
2. Iris-api charge directement depuis le système de fichiers
3. Le volume est utilisé par iris-api

---

## 📊 Tableau Récapitulatif

| Composant | Namespace | Type | Nom | Port | Accès |
|-----------|-----------|------|-----|------|-------|
| **nginx** | `ingress-nginx` | Deployment | `ingress-nginx-controller` | 80, 443 | Internet (LoadBalancer) |
| **iris-api** | `mlops` | Deployment | `iris-api` | 8000 | Interne (ClusterIP) |
| **mlflow-server** | `mlops` | Deployment | `mlflow-server` | 5000 | Interne (ClusterIP) |
| **Ingress** | `mlops` | Ingress | `iris-api-ingress` | - | Règles de routage |
| **Volume** | `mlops` | Volume | `mlruns-volume` | - | Partagé entre pods |

---

## 🔍 Commandes de Vérification

### Voir tous les pods par namespace

```bash
# Nginx
kubectl get pods -n ingress-nginx

# Applications mlops
kubectl get pods -n mlops

# Tous les namespaces
kubectl get pods --all-namespaces
```

### Voir les services

```bash
# Services nginx
kubectl get services -n ingress-nginx

# Services mlops
kubectl get services -n mlops
```

### Voir les Ingress

```bash
# Ingress dans mlops (lu par nginx dans ingress-nginx)
kubectl get ingress -n mlops

# Détails
kubectl describe ingress iris-api-ingress -n mlops
```

### Tester la communication inter-namespace

```bash
# Depuis un pod iris-api, appeler mlflow-server
kubectl exec -it deployment/iris-api -n mlops -- \
  curl http://mlflow-server-service:5000/health

# Depuis nginx, appeler iris-api (si possible)
kubectl exec -it deployment/ingress-nginx-controller -n ingress-nginx -- \
  curl http://iris-api-service.mlops.svc.cluster.local:8000/health
```

---

## 📚 Ressources

- [Kubernetes Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
- [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [MLflow Documentation](https://mlflow.org/docs/latest/index.html)

