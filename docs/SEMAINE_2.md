# 🟢 Semaine 2 : CI/CD (GitHub Actions)

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

## 📦 Livrables Créés

### Fichiers Créés
- ✅ **`.github/workflows/ci.yml`** : Workflow GitHub Actions complet
- ✅ **`.flake8`** : Configuration du linter
- ✅ **`.dockerignore`** : Optimisation des builds Docker
- ✅ **`pyproject.toml`** : Dépendances de dev (flake8, black, isort)

### Fonctionnalités Implémentées
- ✅ Workflow CI automatisé avec 3 jobs
- ✅ Tests exécutés à chaque push (pytest)
- ✅ Linting intégré (flake8 + black + isort)
- ✅ Build et push Docker automatique
- ✅ Gestion des tags et metadata
- ✅ Cache Docker pour optimiser les builds
- ✅ Résumé du pipeline en fin d'exécution

## ✅ Workflow CI/CD Implémenté

Le workflow complet est disponible dans `.github/workflows/ci.yml` :

### Jobs du Pipeline
1. **test** : Tests et Linting
   - Checkout du code
   - Setup Python 3.11 avec cache
   - Installation de Poetry
   - Linting avec flake8
   - Vérification du formatage (Black + isort)
   - Exécution des tests pytest

2. **docker** : Build et Push Docker
   - Setup Docker Buildx
   - Login vers Docker Hub (via secrets)
   - Extraction des metadata et tags
   - Build avec cache optimisé
   - Push automatique vers Docker Hub

3. **summary** : Résumé du pipeline
   - Affichage des résultats des jobs
   - Status global du pipeline

### Features Implémentées
- ✅ Déclenchement sur push/PR vers main/develop
- ✅ Gestion des secrets Docker Hub
- ✅ Tags automatiques (SHA, date, branche)
- ✅ Cache Docker pour accélérer les builds
- ✅ Build conditionnel (push uniquement sur main/develop)
- ✅ Rapport de résumé en fin de pipeline

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

### Phase 1 : Configuration (4h) ✅
- [x] Créer le workflow de base
- [x] Configurer l'environnement Python
- [x] Installer les dépendances

### Phase 2 : Tests et Linting (4h) ✅
- [x] Intégrer pytest dans le workflow
- [x] Configurer flake8
- [x] Vérifier le formatage (Black + isort)

### Phase 3 : Docker (4h) ✅
- [x] Build automatique de l'image
- [x] Configuration du registre Docker Hub
- [x] Push automatique

### Phase 4 : Optimisation (4h) ✅
- [x] Cache des dépendances
- [x] Cache Docker Registry
- [x] Résumé du pipeline

### Phase 5 : Tests et Documentation (4h) ✅
- [x] Configuration des secrets
- [x] Documentation mise à jour
- [x] README et SEMAINE_2.md mis à jour

## ✅ Objectifs de Validation

- [x] Le workflow s'exécute sur chaque push
- [x] Les tests passent automatiquement
- [x] L'image Docker est buildée et poussée (via secrets Docker Hub)
- [x] Le linting ne génère aucune erreur
- [x] Le résumé du pipeline fonctionne

## 🚀 Prochaines Étapes (Semaine 3)

- 🏗️ Infrastructure as Code avec Terraform
- ☁️ Provisioning de ressources GCP
- 🔐 Gestion des rôles IAM

## 🎉 Tâches Accomplies

### Configuration GitHub Actions
- ✅ Workflow avec 3 jobs : test, docker, summary
- ✅ Triggers sur push et pull request
- ✅ Python 3.11 avec cache optimisé
- ✅ Installation automatique de Poetry

### Tests et Linting
- ✅ flake8 avec règles strictes
- ✅ Black pour le formatage du code
- ✅ isort pour l'organisation des imports
- ✅ pytest pour les tests unitaires

### Docker et Registry
- ✅ Docker Buildx pour builds optimisés
- ✅ Login automatique vers Docker Hub
- ✅ Tags intelligents (SHA, date, branche)
- ✅ Cache Registry pour accélérer les builds
- ✅ Push conditionnel (seulement sur main/develop)

### Configuration
- ✅ Fichier `.flake8` avec règles personnalisées
- ✅ Fichier `.dockerignore` pour optimiser les builds
- ✅ Makefile mis à jour avec commande `make ci`
- ✅ Documentation complète

---

**🎉 Semaine 2 terminée avec succès !**

Le pipeline CI/CD est maintenant complètement automatisé et prêt pour la semaine 3 (Terraform).
