#!/bin/bash

# Script simplifié d'installation de Poetry
set -euo pipefail

echo "🐍 Installation de Poetry"

# Trouver Python (préférer Homebrew sur macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: utiliser Homebrew Python 3.11 si disponible
    if [[ -x "/opt/homebrew/bin/python3.11" ]]; then
        PY_BIN="/opt/homebrew/bin/python3.11"
    elif command -v python3 >/dev/null 2>&1; then
        PY_BIN="$(command -v python3)"
    else
        echo "❌ Python introuvable. Installez avec: brew install python@3.11"
        exit 1
    fi
else
    # Linux: utiliser python3 standard
    if command -v python3 >/dev/null 2>&1; then
        PY_BIN="$(command -v python3)"
    else
        echo "❌ Python introuvable. Installez python3 d'abord."
        exit 1
    fi
fi

echo "✅ Python trouvé: $PY_BIN"

# Installer Poetry
if ! command -v poetry >/dev/null 2>&1; then
    echo "📦 Installation de Poetry..."
    curl -sSL https://install.python-poetry.org | "$PY_BIN" -
    export PATH="$HOME/.local/bin:$PATH"
else
    echo "✅ Poetry déjà installé"
fi

# Ajouter Poetry au PATH dans le shell
echo "📝 Configuration du PATH..."
SHELL_CONFIG=""
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_CONFIG="$HOME/.bashrc"
fi

if [[ -n "$SHELL_CONFIG" ]]; then
    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$SHELL_CONFIG" 2>/dev/null; then
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$SHELL_CONFIG"
        echo "✅ PATH ajouté à $SHELL_CONFIG"
    else
        echo "✅ PATH déjà configuré dans $SHELL_CONFIG"
    fi
fi

# Configuration Poetry
echo "⚙️ Configuration..."
poetry config virtualenvs.in-project true
poetry config keyring.enabled false

# Installer les dépendances
echo "📚 Installation des dépendances..."
poetry install

echo "✅ Installation terminée !"
echo "   Utilisez: poetry run <cmd>"