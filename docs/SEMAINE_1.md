# 🟢 Semaine 1 : Docker, FastAPI & Tests

## 🎯 Objectif de la Semaine

**Conteneuriser et exposer un modèle ML localement via API + premiers tests unitaires**

### ❓ Questions Clés
- Comment dockeriser l'application ML ?
- Comment exposer l'inférence via une API performante ?
- Comment mettre en place les premiers tests de validation ?

### ⏱️ Répartition des Heures (20h)
- **7h** → Docker (concepts, commandes) + création Dockerfile
- **7h** → Implémentation d'une API FastAPI (modèle ML)
- **6h** → Écrire et exécuter les premiers tests unitaires avec pytest

## ✅ Tâches Accomplies

### 1. 🤖 Entraînement du Modèle ML
- **Algorithme** : RandomForestClassifier
- **Dataset** : Iris (scikit-learn)
- **Précision** : ~95%
- **Sauvegarde** : Modèle + métadonnées JSON

### 2. 🚀 API FastAPI
- **Endpoints** : 4 (/, /health, /predict, /model/info)
- **Validation** : Pydantic pour les données
- **Documentation** : Swagger UI + ReDoc
- **Gestion d'erreurs** : Codes HTTP appropriés

### 3. 🐳 Docker
- **Base** : Python 3.11-slim
- **Optimisations** : Multi-stage, .dockerignore
- **Health check** : Vérification automatique
- **Port** : 8000 exposé

### 4. 🧪 Tests
- **Couverture** : API + Modèle ML
- **Types** : Unitaires + Intégration
- **Outils** : pytest + httpx
- **Configuration** : pyproject.toml (pytest configuré)

## 📦 Livrables Créés

### Fichiers Principaux
- **`app.py`** : API FastAPI avec endpoints complets
- **`train_model.py`** : Script d'entraînement RandomForest sur Iris
- **`pyproject.toml`** : Configuration Poetry (unique)

### Docker
- **`Dockerfile`** : Image optimisée Python 3.11-slim
- **`docker-compose.yml`** : Orchestration simple
- **`.dockerignore`** : Optimisation du build

### Tests
- **`tests/test_api.py`** : Tests complets de l'API FastAPI
- **`tests/test_model.py`** : Tests du modèle ML

### Automatisation
- **`Makefile`** : 20+ commandes automatisées
- **`scripts/setup_poetry.sh`** : Installation automatique Poetry
- **`scripts/validate_project.sh`** : Validation complète

### Documentation
- **`README.md`** : Documentation complète avec exemples
- **`docs/SEMAINE_1.md`** : Documentation détaillée de la semaine 1
- **`.cursorignore`** : Configuration Cursor IDE optimisée

## 🚀 Fonctionnalités Implémentées

### API FastAPI
- ✅ Endpoint de santé (`/health`)
- ✅ Prédiction ML (`/predict`)
- ✅ Informations modèle (`/model/info`)
- ✅ Documentation interactive (`/docs`, `/redoc`)
- ✅ Validation Pydantic des données
- ✅ Gestion d'erreurs robuste

### Modèle ML
- ✅ RandomForestClassifier sur dataset Iris
- ✅ Sauvegarde du modèle (.pkl)
- ✅ Métadonnées JSON
- ✅ Précision ~95% (typique)

### Tests
- ✅ Tests d'API (endpoints, validation, erreurs)
- ✅ Tests de modèle (entraînement, prédiction, métadonnées)
- ✅ Tests avec données typiques et limites

### Docker
- ✅ Image optimisée (Python 3.11-slim)
- ✅ Build multi-étapes
- ✅ Variables d'environnement
- ✅ Health check configuré
- ✅ Port exposé (8000)

## 🎓 Compétences Développées

### Docker
- ✅ Création de Dockerfile optimisé
- ✅ Gestion des dépendances système
- ✅ Variables d'environnement
- ✅ Health checks
- ✅ Multi-stage builds (concepts)

### FastAPI
- ✅ API REST moderne
- ✅ Validation Pydantic
- ✅ Documentation automatique
- ✅ Gestion d'erreurs
- ✅ Middleware et événements

### Tests
- ✅ Tests unitaires pytest
- ✅ Tests d'intégration API
- ✅ Mocks et fixtures
- ✅ Tests de validation

### Poetry
- ✅ Gestion des dépendances
- ✅ Environnements virtuels
- ✅ Configuration pyproject.toml
- ✅ Scripts personnalisés
- ✅ Groupes de dépendances

## 🚀 Instructions de Démarrage

### Installation Rapide
```bash
# 1. Cloner le projet
git clone <votre-repo>
cd mlops-core

# 2. Installation automatique
make install

# 3. Entraîner le modèle
make train

# 4. Lancer l'API
make run
```

### Vérification
```bash
# Tests
make test

# Build Docker
make build

# Validation complète
./scripts/validate_project.sh
```

## 📊 Métriques

| Métrique | Valeur |
|----------|--------|
| **Fichiers créés** | 20+ |
| **Lignes de code** | ~1000+ |
| **Tests unitaires** | 15+ |
| **Endpoints API** | 4 |
| **Commandes Make** | 20+ |
| **Scripts utilitaires** | 2 |

## 🔗 Liens Utiles

- **API Documentation** : http://localhost:8000/docs
- **Health Check** : http://localhost:8000/health
- **ReDoc** : http://localhost:8000/redoc

## ✅ Validation des Objectifs

| Objectif | Status | Détails |
|----------|--------|---------|
| **Docker** | ✅ | Dockerfile + docker-compose + scripts |
| **FastAPI** | ✅ | API complète avec validation et docs |
| **Tests** | ✅ | Suite de tests robuste avec pytest |
| **Documentation** | ✅ | README + scripts + exemples |
| **Automatisation** | ✅ | Makefile + scripts utilitaires |

## 🚀 Prochaines Étapes (Semaine 2)

- 🔄 CI/CD avec GitHub Actions
- 🔧 Intégration des tests dans le pipeline
- 📦 Build et push automatique des images Docker
- 🏷️ Tagging et versioning automatique

## 📚 Ressources

- [FastAPI Documentation](https://fastapi.tiangolo.com/fr/)
- [Docker Getting Started](https://docs.docker.com/get-started/)
- [pytest Documentation](https://docs.pytest.org/)
- [scikit-learn Iris Dataset](https://scikit-learn.org/stable/modules/generated/sklearn.datasets.load_iris.html)

---

**🎉 Semaine 1 terminée avec succès !**

Tous les objectifs sont atteints et le projet est prêt pour la suite de la formation MLOps.
