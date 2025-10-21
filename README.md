# 🌸 Projet 1 MLOps : Pipeline Local & CI/CD Complet

## 📋 Vue d'Ensemble

**Projet** : API Classification Iris - Formation MLOps (Semaines 1-4)  
**Technologies** : Python, FastAPI, Docker, GitHub Actions, Terraform, MLflow, DVC  
**Objectif** : Maîtriser le packaging, les API et l'automatisation de base pour le déploiement de modèles ML  

## 🎯 Objectifs du Projet 1

Ce projet couvre les **4 premières semaines** de la formation MLOps et vise à :

- ✅ **Semaine 1** : Docker, FastAPI & Tests unitaires
- 🔄 **Semaine 2** : CI/CD avec GitHub Actions  
- 🔄 **Semaine 3** : Infrastructure as Code (Terraform)
- 🔄 **Semaine 4** : MLOps local (MLflow + DVC)

## 📊 Résumé du Projet

**Projet** : API Classification Iris - Semaine 1 MLOps  
**Technologies** : Python, FastAPI, Docker, Poetry, pytest  
**Objectif** : Conteneuriser et exposer un modèle ML via API + tests unitaires  

### 📁 Structure Complète

```
mlops-core/
├── 📄 Fichiers Principaux
│   ├── app.py                    # API FastAPI principale
│   ├── train_model.py            # Script d'entraînement ML
│   ├── pyproject.toml            # Configuration Poetry (unique)
│   ├── Dockerfile               # Image Docker
│   ├── docker-compose.yml       # Orchestration Docker
│   ├── Makefile                 # Commandes automatisées
│   ├── .cursorignore            # Configuration Cursor IDE
│   └── README.md                # Documentation principale
│
├── 🧪 Tests
│   ├── tests/
│   │   ├── __init__.py
│   │   ├── test_api.py          # Tests API FastAPI
│   │   └── test_model.py        # Tests modèle ML
│
├── 🛠️ Scripts (optimisés)
│   ├── scripts/
│   │   ├── setup.sh      # Installation Poetry
│   │   └── validate_project.sh  # Validation complète
│
├── ⚙️ Configuration
│   ├── .gitignore              # Fichiers ignorés Git
│   ├── .dockerignore           # Fichiers ignorés Docker
│   ├── .cursorignore           # Fichiers ignorés Cursor IDE
│   └── env.example             # Variables d'environnement
│
├── 📚 Documentation
│   ├── docs/
│   │   ├── SEMAINE_1.md        # Semaine 1 (terminée)
│   │   ├── SEMAINE_2.md        # Semaine 2 (planifiée)
│   │   ├── SEMAINE_3.md        # Semaine 3 (planifiée)
│   │   └── SEMAINE_4.md        # Semaine 4 (planifiée)
│   └── env.example             # Template variables
│
└── 📦 Modèles (générés)
    └── models/                  # Modèles sauvegardés
        ├── iris_model.pkl      # Modèle entraîné
        └── model_metadata.json # Métadonnées modèle
```

## 🎓 Compétences Développées

### Docker
- ✅ Dockerfile optimisé
- ✅ Gestion des dépendances
- ✅ Health checks
- ✅ Variables d'environnement

### FastAPI
- ✅ API REST moderne
- ✅ Validation Pydantic
- ✅ Documentation automatique
- ✅ Gestion d'erreurs

### Tests
- ✅ Tests unitaires pytest
- ✅ Tests d'intégration
- ✅ Mocks et fixtures

### Poetry
- ✅ Gestion unique des dépendances
- ✅ Environnements virtuels
- ✅ Configuration pyproject.toml
- ✅ Scripts personnalisés

## 🚀 Démarrage Rapide

### Prérequis

- Python 3.11+
- Poetry (installé automatiquement)
- Docker
- Docker Compose (optionnel)

### Installation avec Poetry (Recommandé)

```bash
# Cloner le repository
git clone <votre-repo>
cd mlops-core

# Installation automatique avec Poetry
make install

# Entraîner le modèle
make train

# Lancer l'API
make run
```

### Avec Docker

```bash
# Build de l'image
docker build -t iris-api .

# Lancer le conteneur
docker run -p 8000:8000 iris-api

# Ou avec Docker Compose
docker-compose up --build
```

## 📊 API Endpoints

### Documentation Interactive
- **Swagger UI** : http://localhost:8000/docs
- **ReDoc** : http://localhost:8000/redoc

### Endpoints Disponibles

| Endpoint | Méthode | Description |
|----------|---------|-------------|
| `/` | GET | Informations générales sur l'API |
| `/health` | GET | État de santé de l'API |
| `/predict` | POST | Prédiction de la classe d'iris |
| `/model/info` | GET | Informations sur le modèle |

### Exemple d'Utilisation

```bash
# Test de santé
curl http://localhost:8000/health

# Prédiction
curl -X POST "http://localhost:8000/predict" \
     -H "Content-Type: application/json" \
     -d '{
       "sepal_length": 5.1,
       "sepal_width": 3.5,
       "petal_length": 1.4,
       "petal_width": 0.2
     }'
```

## 🧪 Tests

### Exécution des Tests

```bash
# Avec Make (recommandé)
make test              # Tous les tests

# Avec Poetry
poetry run pytest
poetry run pytest tests/test_api.py
```

## 🛠️ Commandes Make Disponibles

Le projet inclut un Makefile avec des commandes utiles :

```bash
# Installation et configuration
make install          # Installer Poetry et les dépendances
make dev-setup        # Configuration complète pour le développement

# Modèle ML
make train            # Entraîner le modèle

# Tests
make test             # Exécuter tous les tests

# API
make run              # Lancer l'API en mode développement
make run-prod         # Lancer l'API en mode production

# Docker
make build            # Construire l'image Docker
make run-docker       # Lancer avec Docker
make run-docker-bg    # Lancer avec Docker en arrière-plan
make stop-docker      # Arrêter le conteneur Docker

# Qualité du code
make format           # Formater le code (Black + isort)
make lint             # Vérifier la qualité du code (flake8 + black + isort)

# Nettoyage
make clean            # Nettoyer les fichiers temporaires
make clean-models     # Nettoyer les modèles entraînés

# Utilitaires
make health           # Vérifier la santé de l'API
make docs             # Afficher les liens de documentation
make help             # Afficher toutes les commandes
```

## 📚 Documentation par Semaine

### 🟢 [Semaine 1 : Docker, FastAPI & Tests](./docs/SEMAINE_1.md)
- **Objectif** : Conteneuriser et exposer un modèle ML localement via API + premiers tests unitaires
- **Technologies** : Docker, FastAPI, pytest
- **Durée** : 20h
- **Status** : ✅ **TERMINÉ**

### 🟡 [Semaine 2 : CI/CD (GitHub Actions)](./docs/SEMAINE_2.md)
- **Objectif** : Automatiser le processus de build/test/push de l'image Docker sur push GitHub
- **Technologies** : GitHub Actions, Docker Registry
- **Durée** : 20h
- **Status** : 🔄 **EN COURS**

### 🟡 [Semaine 3 : Infrastructure as Code (Terraform)](./docs/SEMAINE_3.md)
- **Objectif** : Provisionner une infrastructure cloud simple sur GCP via Terraform
- **Technologies** : Terraform, GCP, IAM
- **Durée** : 20h
- **Status** : 📋 **PLANNIFIÉ**

### 🟡 [Semaine 4 : MLOps local (MLflow + DVC)](./docs/SEMAINE_4.md)
- **Objectif** : Traquer et versionner les expériences ML localement pour la reproductibilité
- **Technologies** : MLflow, DVC
- **Durée** : 20h
- **Status** : 📋 **PLANNIFIÉ**

## 📈 Métriques du Projet

| Catégorie | Quantité |
|-----------|----------|
| **Fichiers créés** | 20+ |
| **Lignes de code** | 1000+ |
| **Tests unitaires** | 15+ |
| **Endpoints API** | 4 |
| **Commandes Make** | 20+ |
| **Scripts utilitaires** | 2 |

## 🔗 Liens Utiles

- **API** : http://localhost:8000
- **Documentation** : http://localhost:8000/docs
- **Santé** : http://localhost:8000/health
- **ReDoc** : http://localhost:8000/redoc

## 📚 Ressources

- [FastAPI Documentation](https://fastapi.tiangolo.com/fr/)
- [Docker Getting Started](https://docs.docker.com/get-started/)
- [pytest Documentation](https://docs.pytest.org/)
- [scikit-learn Iris Dataset](https://scikit-learn.org/stable/modules/generated/sklearn.datasets.load_iris.html)

## 👥 Auteur

Formation MLOps - Projet 1 (Semaines 1-4)  
**Objectif** : Maîtriser le packaging, les API et l'automatisation de base pour le déploiement de modèles ML

---

**🎉 Projet 1 en cours de développement !**

Ce projet fait partie de la formation MLOps complète et couvre les fondations essentielles pour le déploiement de modèles ML en production.