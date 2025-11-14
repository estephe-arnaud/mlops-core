# 🔧 Configuration CI/CD - GitHub Actions

Ce guide explique comment configurer le pipeline CI/CD GitHub Actions pour le projet mlops-core.

## 📋 Prérequis

- Repository GitHub
- Compte Docker Hub (gratuit)
- Accès aux paramètres du repository

## 🚀 Configuration des Secrets Docker Hub

Pour que le pipeline puisse pousser les images Docker vers Docker Hub, vous devez configurer les secrets suivants dans votre repository GitHub :

### 1. Créer un Personal Access Token sur Docker Hub

1. Allez sur [Docker Hub](https://hub.docker.com/)
2. Connectez-vous à votre compte
3. Allez dans **Account Settings** > **Security**
4. Cliquez sur **New Access Token**
5. Donnez un nom à votre token (ex: `github-actions`)
6. Copiez le token (⚠️ il ne sera affiché qu'une seule fois !)

### 2. Configurer les Secrets GitHub

1. Allez sur votre repository GitHub
2. Cliquez sur **Settings** > **Secrets and variables** > **Actions**
3. Cliquez sur **New repository secret**
4. Ajoutez les deux secrets suivants :

#### Secret 1 : `DOCKERHUB_USERNAME`
- **Name**: `DOCKERHUB_USERNAME`
- **Value**: Votre nom d'utilisateur Docker Hub (ex: `monusername`)

#### Secret 2 : `DOCKERHUB_TOKEN`
- **Name**: `DOCKERHUB_TOKEN`
- **Value**: Le token que vous venez de créer

### 3. Vérifier la Configuration

Une fois les secrets configurés, vous pouvez :

1. Tester le workflow en faisant un commit sur la branche `main` ou `develop`
2. Aller dans l'onglet **Actions** de votre repository
3. Vérifier que le workflow s'exécute correctement

## 📊 Le Workflow CI/CD

Le workflow est défini dans `.github/workflows/ci.yml` et comprend 3 jobs :

### Job 1 : Tests et Linting (`test`)
- ✅ Checkout du code
- ✅ Setup Python 3.11
- ✅ Installation de Poetry
- ✅ Linting avec flake8
- ✅ Vérification du formatage (Black + isort)
- ✅ Exécution des tests pytest

### Job 2 : Build et Push Docker (`docker`)
- ✅ Setup Docker Buildx
- ✅ Login vers Docker Hub (via secrets)
- ✅ Extraction des metadata et tags
- ✅ Build avec cache optimisé
- ✅ Push automatique vers Docker Hub

### Job 3 : Résumé (`summary`)
- ✅ Affichage des résultats de tous les jobs
- ✅ Statut global du pipeline

## 🏷️ Gestion des Tags

Le workflow génère automatiquement plusieurs tags pour chaque image :

- **Date + SHA**: `2024-01-15-abc123def456`
- **SHA court**: `abc123d`
- **Branche**: `main` ou `develop`
- **Pull Request**: `pr-123` (pour les PR)

## 🔍 Débogage

### Le workflow ne se déclenche pas

Vérifiez que :
- Les fichiers sont bien dans la branche `main` ou `develop`
- Le fichier `.github/workflows/ci.yml` existe
- Il n'y a pas d'erreurs de syntaxe YAML

### Le build Docker échoue

Vérifiez que :
- Les secrets `DOCKERHUB_USERNAME` et `DOCKERHUB_TOKEN` sont bien configurés
- Le nom d'utilisateur Docker Hub est correct
- Le token est valide (pas expiré)

### Les tests échouent

Vérifiez que :
- Tous les tests passent localement (`make test`)
- Le linting est OK (`make lint`)
- Le formatage est correct (`make format`)

## 🧪 Tester Localement

Avant de push vos changements, vous pouvez tester localement :

```bash
# Installer les dépendances
make install

# Formater le code
make format

# Linter le code
make lint

# Lancer les tests
make test

# Tout vérifier en une fois (CI équivalent)
make ci
```

## 📝 Commandes Utiles

```bash
# Voir l'historique du workflow
gh run list

# Voir les logs d'une exécution spécifique
gh run view <run-id> --log

# Relancer un workflow qui a échoué
gh run rerun <run-id>
```

## 🔗 Ressources

- [GitHub Actions Documentation](https://docs.github.com/fr/actions)
- [Docker Hub Authentication](https://docs.docker.com/docker-hub/access-tokens/)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)

---

**🎉 Une fois configuré, votre pipeline CI/CD sera automatiquement déclenché à chaque push !**
