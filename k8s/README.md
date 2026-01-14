# 🚀 Guide de Déploiement Kubernetes

> 📚 **Documentation complète** : Consultez [`docs/PHASE_5.md`](../docs/PHASE_5.md) pour la documentation détaillée avec tous les concepts, workflows, et exemples.

## 🚀 Déploiement Rapide

### 1. Préparer les Secrets

```bash
cp k8s/secret.yaml.example k8s/secret.yaml
# Éditer k8s/secret.yaml avec vos valeurs
```

### 2. Déployer

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

### 3. Accéder

```bash
make k8s-port-forward      # API sur http://localhost:8000
make k8s-mlflow-ui         # MLflow UI sur http://localhost:5000
```

## 📋 Commandes Utiles

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

## 📚 Documentation

- [🏗️ Architecture Détaillée](ARCHITECTURE.md) - Architecture complète avec nginx, mlflow-server et iris-api
- [📖 Phase 5 : Orchestration](../docs/PHASE_5.md) - Documentation complète avec :
  - Architecture détaillée
  - Concepts Kubernetes
  - Installation et configuration
  - Workflows MLflow
  - Tests et validation
  - Dépannage
- [Makefile](../Makefile) - Toutes les commandes `make k8s-*`
