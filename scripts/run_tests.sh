#!/bin/bash

# Script d'exécution des tests pour la semaine 1 MLOps
# Usage: ./scripts/run_tests.sh

echo "🧪 Exécution des tests pour l'API Classification Iris"
echo "=================================================="

# Vérification de l'environnement Python
echo "📋 Vérification de l'environnement..."
python --version
pip --version

# Installation des dépendances si nécessaire
echo "📦 Installation des dépendances..."
pip install -r requirements.txt

# Entraînement du modèle si nécessaire
echo "🤖 Entraînement du modèle..."
if [ ! -f "models/iris_model.pkl" ]; then
    echo "   Modèle non trouvé, entraînement en cours..."
    python train_model.py
else
    echo "   Modèle déjà entraîné ✓"
fi

# Exécution des tests
echo "🧪 Exécution des tests unitaires..."
pytest -v --tb=short

# Vérification de la couverture de code
echo "📊 Analyse de la couverture de code..."
pytest --cov=app --cov-report=term-missing

echo "✅ Tests terminés !"
