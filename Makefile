# Makefile pour le projet MLOps - Semaines 1-3
# Usage: make <command>

.PHONY: help install uninstall train test run build clean format lint ci terraform-init terraform-plan terraform-apply terraform-destroy terraform-output terraform-validate terraform-fmt terraform-refresh mlflow-ui mlflow-experiments dvc-init dvc-repro dvc-status dvc-push dvc-pull dvc-pipeline

# Variables
PYTHON := poetry run python
PIP := poetry run pip
PYTEST := poetry run pytest
BLACK := poetry run black
FLAKE8 := poetry run flake8
ISORT := poetry run isort

# Aide
help: ## Afficher cette aide
	@echo "🌸 MLOps Iris API - Commandes disponibles"
	@echo "========================================"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Installation
install: ## Installer Poetry et les dépendances
	@echo "📦 Installation de l'environnement..."
	@chmod +x scripts/setup.sh
	@./scripts/setup.sh

uninstall: ## Supprimer l'environnement Poetry
	@echo "🗑️ Suppression complète de l'environnement Poetry..."
	@echo "   Suppression de l'environnement virtuel..."
	@rm -rf .venv
	@echo "   Suppression du fichier poetry.lock..."
	@rm -f poetry.lock
	@echo "   Suppression des caches Python..."
	@rm -rf .pytest_cache/ __pycache__/ *.pyc
	@find . -name "*.pyc" -delete
	@find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "   Suppression des fichiers de build..."
	@rm -rf build/ dist/ *.egg-info/
	@echo "   Désinstallation de Poetry..."
	@echo "⚠️  Téléchargement et exécution de script depuis internet"
	@curl -sSL https://install.python-poetry.org | python3 - --uninstall || echo "Poetry non installé"
	@echo "   Suppression du binaire Poetry..."
	@rm -f ~/.local/bin/poetry
	@echo "   Nettoyage des caches et données Poetry..."
	@rm -rf ~/.config/pypoetry ~/.cache/pypoetry ~/.local/share/pypoetry
	@echo "   Suppression de Poetry du PATH (à faire manuellement)..."
	@echo "   Éditez ~/.zshrc ou ~/.bashrc pour supprimer la ligne:"
	@echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
	@echo "✅ Nettoyage complet terminé !"

# Entraînement du modèle
train: ## Entraîner le modèle ML
	@echo "🤖 Entraînement du modèle..."
	$(PYTHON) -m src.training.train

# Tests
test: ## Exécuter tous les tests
	@echo "🧪 Exécution des tests..."
	$(PYTEST)

# API
run: ## Lancer l'API en mode développement
	@echo "🚀 Lancement de l'API..."
	poetry run uvicorn src.serving.app:app --reload --host 127.0.0.1 --port 8000

run-prod: ## Lancer l'API en mode production
	@echo "🚀 Lancement de l'API en production..."
	poetry run uvicorn src.serving.app:app --host 0.0.0.0 --port 8000

# Docker
build: ## Construire l'image Docker
	@echo "🐳 Construction de l'image Docker..."
	docker build -t iris-api:latest .

run-docker: ## Lancer l'API avec Docker
	@echo "🐳 Lancement avec Docker..."
	docker run -p 127.0.0.1:8000:8000 iris-api:latest

run-docker-bg: ## Lancer l'API avec Docker en arrière-plan
	@echo "🐳 Lancement avec Docker en arrière-plan..."
	docker run -d -p 127.0.0.1:8000:8000 --name iris-api iris-api:latest

stop-docker: ## Arrêter le conteneur Docker
	@echo "🛑 Arrêt du conteneur Docker..."
	docker stop iris-api || true
	docker rm iris-api || true

# Qualité du code (configuration dans pyproject.toml)
format: ## Formater le code avec Black et isort
	@echo "🎨 Formatage du code..."
	$(BLACK) .
	$(ISORT) .

lint: ## Vérifier la qualité du code
	@echo "🔍 Vérification de la qualité du code..."
	$(FLAKE8) --exclude=.venv,venv,__pycache__,.git,.env,build,dist,*.egg-info,.pytest_cache,.mypy_cache,poetry.lock --count --select=E9,F63,F7,F82 --show-source --statistics .
	$(BLACK) --check .
	$(ISORT) --check-only .

# CI/CD 
ci: lint test ## Exécuter les vérifications CI (lint + test)
	@echo "✅ Toutes les vérifications CI sont passées !"

# Nettoyage
clean: ## Nettoyer les fichiers temporaires
	@echo "🧹 Nettoyage..."
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	rm -rf .pytest_cache/
	rm -rf dist/
	rm -rf build/

clean-models: ## Nettoyer les modèles entraînés
	@echo "🧹 Nettoyage des modèles..."
	rm -rf models/

# Développement
dev-setup: install train ## Configuration complète pour le développement
	@echo "✅ Configuration de développement terminée !"

# Documentation
docs: ## Générer la documentation
	@echo "📚 Génération de la documentation..."
	@echo "Documentation disponible sur: http://localhost:8000/docs"

# Santé de l'API
health: ## Vérifier la santé de l'API
	@echo "❤️  Vérification de la santé de l'API..."
	@curl -f http://localhost:8000/health || echo "❌ API non accessible"

# Déploiement
deploy: build run-docker-bg ## Déployer l'API (build + run)
	@echo "🚀 Déploiement terminé !"
	@echo "API disponible sur: http://localhost:8000"
	@echo "Documentation: http://localhost:8000/docs"

# Terraform (Semaine 3)
terraform-init: ## Initialiser Terraform
	@echo "🏗️  Initialisation de Terraform..."
	@cd terraform && terraform init

terraform-validate: ## Valider la configuration Terraform
	@echo "✅ Validation de la configuration Terraform..."
	@cd terraform && terraform validate

terraform-fmt: ## Formater les fichiers Terraform
	@echo "🎨 Formatage des fichiers Terraform..."
	@cd terraform && terraform fmt -recursive

terraform-plan: terraform-init ## Planifier les changements Terraform
	@echo "📋 Planification des changements Terraform..."
	@cd terraform && terraform plan

terraform-apply: terraform-init ## Appliquer la configuration Terraform
	@echo "🚀 Application de la configuration Terraform..."
	@cd terraform && terraform apply

terraform-destroy: ## Détruire l'infrastructure Terraform
	@echo "⚠️  Destruction de l'infrastructure Terraform..."
	@cd terraform && terraform destroy

terraform-output: ## Afficher les outputs Terraform
	@echo "📊 Outputs Terraform:"
	@cd terraform && terraform output

terraform-refresh: ## Rafraîchir l'état Terraform
	@echo "🔄 Rafraîchissement de l'état Terraform..."
	@cd terraform && terraform refresh

# MLflow (Semaine 4)
mlflow-ui: ## Lancer l'interface MLflow UI
	@echo "📊 Lancement de MLflow UI..."
	@echo "Interface disponible sur: http://localhost:5000"
	@poetry run mlflow ui --host 127.0.0.1 --port 5000

mlflow-experiments: ## Lister les expériences MLflow
	@echo "📊 Expériences MLflow:"
	@poetry run mlflow experiments list || echo "Aucune expérience trouvée"

# DVC (Semaine 4)
dvc-init: ## Initialiser DVC dans le projet
	@echo "🔄 Initialisation de DVC..."
	@poetry run dvc init || echo "DVC déjà initialisé"

dvc-repro: ## Réexécuter le pipeline DVC
	@echo "🔄 Réexécution du pipeline DVC..."
	@poetry run dvc repro

dvc-status: ## Vérifier l'état du pipeline DVC
	@echo "📊 État du pipeline DVC:"
	@poetry run dvc status || echo "DVC non initialisé"

dvc-push: ## Pousser les données versionnées (si remote configuré)
	@echo "📤 Push des données DVC..."
	@poetry run dvc push || echo "Aucun remote configuré"

dvc-pull: ## Télécharger les données versionnées
	@echo "📥 Pull des données DVC..."
	@poetry run dvc pull || echo "Aucun remote configuré"

dvc-pipeline: ## Afficher le pipeline DVC
	@echo "📊 Pipeline DVC:"
	@poetry run dvc dag || echo "Pipeline non configuré"
