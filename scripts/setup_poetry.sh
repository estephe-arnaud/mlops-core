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

# Détecter le shell et ajouter au bon fichier de configuration
if [[ "$SHELL" == *"zsh"* ]]; then
	SHELL_CONFIG="$HOME/.zshrc"
else
	SHELL_CONFIG="$HOME/.bashrc"
fi

# Ajouter le path s'il n'existe pas déjà
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$SHELL_CONFIG" 2>/dev/null; then
	echo "📝 Ajout du path Poetry à $SHELL_CONFIG..."
	echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_CONFIG"
	echo "✅ Path ajouté et rechargé automatiquement"
	source "$SHELL_CONFIG"
else
	echo "✅ Le path Poetry est déjà configuré"
fi

# Configurer Poetry
echo "⚙️ Configuration Poetry..."
poetry config virtualenvs.in-project true

# Installer les dépendances (Poetry gérera automatiquement Python 3.11)
echo "📚 Installation des dépendances avec Poetry..."
poetry install

# Vérifications
echo "🔍 Vérifications finales..."
poetry --version
poetry env info

echo "✅ Installation terminée !"
echo "   Utilisez: poetry run <cmd> (ex: uvicorn app:app --reload)"