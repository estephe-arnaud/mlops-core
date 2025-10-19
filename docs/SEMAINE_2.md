# 🟡 Semaine 2 : CI/CD (GitHub Actions)

## 🎯 Objectif de la Semaine

**Automatiser le processus de build/test/push de l'image Docker sur push GitHub**

### ❓ Questions Clés
- Comment garantir la validation du code avant le build ?
- Comment automatiser le build et le push vers un registre ?

### ⏱️ Répartition des Heures (20h)
- **8h** → Concevoir et écrire un workflow GitHub Actions pour CI
- **8h** → Intégrer : run tests → build image → push image (Artifact Registry ou Docker Hub)
- **4h** → Ajouter un linter (flake8 ou équivalent) au pipeline

## 📋 Tâches à Accomplir

### 1. 🔧 Workflow GitHub Actions
- Créer le workflow YAML pour GitHub Actions
- Configurer l'authentification au registre
- Intégrer les tests unitaires et le linting

### 2. 🐳 Build et Push Docker
- Automatiser le build de l'image Docker
- Push vers Docker Hub ou Artifact Registry
- Gestion des tags et versions

### 3. 🧪 Intégration des Tests
- Exécution automatique des tests à chaque push
- Validation de la qualité du code
- Reporting des résultats

### 4. 🔍 Linting et Qualité
- Configuration de flake8 ou équivalent
- Vérification automatique du style de code
- Intégration dans le pipeline CI

## 📦 Livrables Attendus

### Fichiers à Créer
- **`.github/workflows/ci.yml`** : Workflow GitHub Actions complet
- **`.flake8`** : Configuration du linter
- **`pyproject.toml`** : Mise à jour avec les dépendances de dev

### Fonctionnalités
- ✅ Workflow CI automatisé
- ✅ Tests exécutés à chaque push
- ✅ Build et push Docker automatique
- ✅ Linting intégré
- ✅ Notifications de statut

## 🚀 Workflow CI/CD Prévu

```yaml
# .github/workflows/ci.yml (à créer)
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: |
          pip install poetry
          poetry install
      - name: Lint with flake8
        run: |
          poetry run flake8 .
      - name: Test with pytest
        run: |
          poetry run pytest --cov=app
      - name: Build Docker image
        run: |
          docker build -t iris-api:${{ github.sha }} .
      - name: Push to registry
        run: |
          # Push vers Docker Hub ou Artifact Registry
```

## 🛠️ Outils à Utiliser

### GitHub Actions
- **Triggers** : Push, Pull Request
- **Environnements** : ubuntu-latest
- **Secrets** : Docker Hub credentials

### Docker
- **Registry** : Docker Hub ou Google Artifact Registry
- **Tags** : SHA du commit, latest
- **Multi-arch** : (optionnel)

### Linting
- **flake8** : Style et erreurs Python
- **black** : Formatage automatique
- **isort** : Organisation des imports

## 📊 Métriques Attendues

| Métrique | Objectif |
|----------|----------|
| **Temps de build** | < 5 minutes |
| **Couverture de tests** | > 80% |
| **Linting errors** | 0 |
| **Docker image size** | < 500MB |

## 🔗 Ressources

- [GitHub Actions Documentation](https://docs.github.com/fr/actions)
- [Docker Hub](https://hub.docker.com/)
- [Google Artifact Registry](https://cloud.google.com/artifact-registry)
- [flake8 Documentation](https://flake8.pycqa.org/)

## 📈 Progression

### Phase 1 : Configuration (4h)
- [ ] Créer le workflow de base
- [ ] Configurer l'environnement Python
- [ ] Installer les dépendances

### Phase 2 : Tests et Linting (4h)
- [ ] Intégrer pytest dans le workflow
- [ ] Configurer flake8
- [ ] Ajouter la couverture de code

### Phase 3 : Docker (4h)
- [ ] Build automatique de l'image
- [ ] Configuration du registre
- [ ] Push automatique

### Phase 4 : Optimisation (4h)
- [ ] Cache des dépendances
- [ ] Optimisation du Dockerfile
- [ ] Notifications

### Phase 5 : Tests et Documentation (4h)
- [ ] Tests du pipeline complet
- [ ] Documentation des secrets
- [ ] README mis à jour

## 🎯 Objectifs de Validation

- [ ] Le workflow s'exécute sur chaque push
- [ ] Les tests passent automatiquement
- [ ] L'image Docker est buildée et poussée
- [ ] Le linting ne génère aucune erreur
- [ ] Les notifications fonctionnent

## 🚀 Prochaines Étapes (Semaine 3)

- 🏗️ Infrastructure as Code avec Terraform
- ☁️ Provisioning de ressources GCP
- 🔐 Gestion des rôles IAM

---

**🔄 Semaine 2 en cours de développement**

Cette semaine se concentre sur l'automatisation complète du pipeline de développement et de déploiement.
