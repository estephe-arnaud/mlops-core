#!/bin/bash

# Script simplifié d'installation de Poetry
# Usage: ./scripts/setup_poetry.sh

set -euo pipefail

echo "🐍 Installation simplifiée de Poetry"

# Vérifier si Python est disponible (n'importe quelle version)
if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
	echo "❌ Python introuvable. Installez Python d'abord."
	echo "   Ubuntu/Debian: sudo apt-get install python3"
	echo "   macOS: brew install python"
	echo "   Ou téléchargez depuis: https://python.org"
	exit 1
fi

# Utiliser python3 en priorité, sinon python
PY_BIN=""
if command -v python3 >/dev/null 2>&1; then
	PY_BIN="$(command -v python3)"
elif command -v python >/dev/null 2>&1; then
	PY_BIN="$(command -v python)"
fi

echo "✅ Python trouvé: $PY_BIN"

# Installer Poetry si absent
if ! command -v poetry >/dev/null 2>&1 && [[ ! -x "$HOME/.local/bin/poetry" ]]; then
	echo "📦 Installation de Poetry..."
	if ! command -v curl >/dev/null 2>&1; then
		echo "❌ curl introuvable. Installez curl d'abord."
		exit 1
	fi
	curl -sSL https://install.python-poetry.org | "$PY_BIN" -
else
	echo "✅ Poetry déjà installé"
fi

# Configurer Poetry
echo "⚙️ Configuration Poetry..."
poetry config virtualenvs.in-project true
poetry config virtualenvs.create true

# S'assurer que Poetry est dans le PATH
if ! command -v poetry >/dev/null 2>&1; then
	if [[ -x "$HOME/.local/bin/poetry" ]]; then
		echo "ℹ️ Ajout de ~/.local/bin au PATH..."
		export PATH="$HOME/.local/bin:$PATH"
	else
		echo "❌ Poetry introuvable après installation"
		exit 1
	fi
fi

# Configurer Poetry
echo "⚙️ Configuration Poetry..."
poetry config virtualenvs.in-project true
poetry config virtualenvs.create true

# Installer les dépendances (Poetry gérera automatiquement Python 3.11)
echo "📚 Installation des dépendances avec Poetry..."
poetry install

# Vérifications
echo "🔍 Vérifications finales..."
poetry --version
poetry env info

echo "✅ Installation terminée !"
echo "   Utilisez: poetry run <cmd> (ex: uvicorn app:app --reload)"