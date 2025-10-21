# Makefile pour le projet MLOps - Semaine 1
# Usage: make <command>

.PHONY: help install uninstall train test run build clean format lint

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
	$(PYTHON) train_model.py

# Tests
test: ## Exécuter tous les tests
	@echo "🧪 Exécution des tests..."
	$(PYTEST)

# API
run: ## Lancer l'API en mode développement
	@echo "🚀 Lancement de l'API..."
	poetry run uvicorn app:app --reload --host 127.0.0.1 --port 8000

run-prod: ## Lancer l'API en mode production
	@echo "🚀 Lancement de l'API en production..."
	poetry run uvicorn app:app --host 0.0.0.0 --port 8000

# Docker
build: ## Construire l'image Docker
	@echo "🐳 Construction de l'image Docker..."
	docker build -t iris-api:latest .

run-docker: ## Lancer l'API avec Docker
	@echo "🐳 Lancement avec Docker..."
	docker run -p 8000:8000 iris-api:latest

run-docker-bg: ## Lancer l'API avec Docker en arrière-plan
	@echo "🐳 Lancement avec Docker en arrière-plan..."
	docker run -d -p 8000:8000 --name iris-api iris-api:latest

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
	$(FLAKE8) .
	$(BLACK) --check .
	$(ISORT) --check-only .

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
