# 🌸 API Classification Iris - Semaine 1 MLOps

## 📋 Description

Ce projet implémente une API FastAPI pour la classification des fleurs d'iris, dans le cadre de la formation MLOps. Il s'agit du premier projet de la semaine 1 qui couvre :

- **Docker** : Conteneurisation de l'application
- **FastAPI** : API REST performante pour l'inférence ML
- **Tests unitaires** : Validation avec pytest

## 🎯 Objectifs de la Semaine 1

- ✅ Entraîner un modèle ML simple (RandomForest sur Iris)
- ✅ Créer une API FastAPI pour exposer le modèle
- ✅ Dockeriser l'application complète
- ✅ Implémenter des tests unitaires robustes

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

# Ou manuellement :
# 1. Installer Poetry
curl -sSL https://install.python-poetry.org | python3 -

# 2. Configurer Poetry
poetry config virtualenvs.in-project true

# 3. Installer les dépendances
poetry install

# Entraîner le modèle
make train
# ou: poetry run python train_model.py

# Lancer l'API
make run
# ou: poetry run uvicorn app:app --reload --host 0.0.0.0 --port 8000
```

### Installation Classique (pip)

```bash
# Cloner le repository
git clone <votre-repo>
cd mlops-core

# Créer un environnement virtuel
python -m venv venv
source venv/bin/activate  # Sur Windows: venv\Scripts\activate

# Installer les dépendances
pip install -r requirements.txt

# Entraîner le modèle
python train_model.py

# Lancer l'API
uvicorn app:app --host 0.0.0.0 --port 8000
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
make test-cov          # Tests avec couverture
make test-watch        # Tests en mode watch

# Avec Poetry
poetry run pytest
poetry run pytest --cov=app
poetry run pytest tests/test_api.py

# Avec pip classique
pytest
pytest --cov=app
pytest tests/test_api.py
```

### Structure des Tests

```
tests/
├── __init__.py
├── test_api.py      # Tests de l'API FastAPI
└── test_model.py    # Tests du modèle ML
```

## 🐳 Docker

### Dockerfile

Le Dockerfile utilise une image Python 3.11-slim et :
- Installe les dépendances système nécessaires
- Copie et installe les dépendances Python
- Entraîne le modèle au build
- Expose le port 8000
- Lance l'API avec uvicorn

### Commandes Docker

```bash
# Build
docker build -t iris-api .

# Run
docker run -p 8000:8000 iris-api

# Run en arrière-plan
docker run -d -p 8000:8000 --name iris-api iris-api

# Logs
docker logs iris-api

# Arrêt
docker stop iris-api
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
make test-cov         # Tests avec couverture
make test-watch       # Tests en mode watch

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
make lint             # Vérifier la qualité du code

# Nettoyage
make clean            # Nettoyer les fichiers temporaires
make clean-models     # Nettoyer les modèles entraînés

# Utilitaires
make health           # Vérifier la santé de l'API
make docs             # Afficher les liens de documentation
make help             # Afficher toutes les commandes
```

## 📁 Structure du Projet

```
mlops-core/
├── app.py                 # API FastAPI principale
├── train_model.py         # Script d'entraînement du modèle
├── pyproject.toml         # Configuration Poetry
├── requirements.txt       # Dépendances Python (fallback)
├── Makefile              # Commandes automatisées
├── Dockerfile            # Configuration Docker
├── docker-compose.yml    # Orchestration Docker
├── pytest.ini           # Configuration pytest
├── .dockerignore        # Fichiers ignorés par Docker
├── .gitignore           # Fichiers ignorés par Git
├── scripts/              # Scripts utilitaires
│   ├── setup_poetry.sh
│   ├── run_tests.sh
│   └── build_and_run.sh
├── tests/               # Tests unitaires
│   ├── __init__.py
│   ├── test_api.py
│   └── test_model.py
├── models/              # Modèles sauvegardés (généré)
│   ├── iris_model.pkl
│   └── model_metadata.json
└── README.md           # Ce fichier
```

## 🔧 Configuration

### Variables d'Environnement

| Variable | Description | Défaut |
|----------|-------------|---------|
| `PYTHONPATH` | Chemin Python | `/app` |
| `PORT` | Port de l'API | `8000` |

### Modèle ML

- **Algorithme** : RandomForestClassifier
- **Dataset** : Iris (scikit-learn)
- **Features** : 4 (longueur/largeur sépale et pétale)
- **Classes** : 3 (setosa, versicolor, virginica)
- **Précision** : ~95% (typique)

## 📈 Métriques et Monitoring

L'API expose des endpoints de monitoring :
- `/health` : État de santé général
- `/model/info` : Informations détaillées du modèle

## 🚀 Prochaines Étapes (Semaine 2)

- CI/CD avec GitHub Actions
- Intégration des tests dans le pipeline
- Build et push automatique des images Docker

## 📚 Ressources

- [FastAPI Documentation](https://fastapi.tiangolo.com/fr/)
- [Docker Getting Started](https://docs.docker.com/get-started/)
- [pytest Documentation](https://docs.pytest.org/)
- [scikit-learn Iris Dataset](https://scikit-learn.org/stable/modules/generated/sklearn.datasets.load_iris.html)

## 👥 Auteur

Formation MLOps - Semaine 1
**Objectif** : Maîtriser Docker, FastAPI et les tests unitaires pour le déploiement de modèles ML
