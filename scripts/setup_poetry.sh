#!/bin/bash

# Script minimal d'installation et configuration de Poetry (macOS/Linux)
# Usage: ./scripts/setup_poetry.sh

set -e

echo "🐍 Setup Poetry (minimal, python3.11 requis)"

# 1) Sélection stricte de python3.11 optimisée selon l'OS (sans modifier PATH)
PY_BIN=""
OS_NAME="$(uname -s 2>/dev/null || echo unknown)"
if [[ "$OS_NAME" == "Darwin" ]]; then
    # macOS: préférer Homebrew si présent
    if [[ -x "/opt/homebrew/bin/python3.11" ]]; then
        PY_BIN="/opt/homebrew/bin/python3.11"
    elif command -v python3.11 &> /dev/null; then
        PY_BIN="$(in)"
    fi
else
    # Linux (et autres): utiliser python3.11 du PATH
    if command -v python3.11 &> /dev/null; then
        PY_BIN="$(command -v python3.11)"
    fi
fi

if [[ -z "$PY_BIN" ]]; then
    echo "❌ python3.11 introuvable. Installez Python 3.11 puis relancez."
    if [[ "$OS_NAME" == "Darwin" ]]; then
        echo "   Exemple (macOS Homebrew): brew install python@3.11"
    else
        echo "   Exemple (Linux deb-based): sudo apt-get update && sudo apt-get install -y python3.11"
    fi
    exit 1
fi

# 2) Installer Poetry si absent (via python3.11 explicite)
if ! command -v poetry &> /dev/null; then
    echo "📦 Installation de Poetry..."
    curl -sSL https://install.python-poetry.org | "$PY_BIN" -
fi

# 3) Localiser le binaire Poetry (sans modifier le PATH)
POETRY_BIN="$(command -v poetry || true)"
if [[ -z "$POETRY_BIN" && -x "$HOME/.local/bin/poetry" ]]; then
    POETRY_BIN="$HOME/.local/bin/poetry"
fi

if [[ -z "$POETRY_BIN" ]]; then
    echo "❌ 'poetry' introuvable. Ajoutez ~/.local/bin à votre PATH puis ré-ouvrez un terminal."
    echo "   Exemple: echo 'export PATH=\"$HOME/.local/bin:$PATH\"' >> ~/.zshrc && exec zsh"
    exit 1
fi

# 4) Configurer Poetry et installer les dépendances
echo "⚙️ Configuration Poetry..."
"$POETRY_BIN" config virtualenvs.in-project true
"$POETRY_BIN" config virtualenvs.create true

echo "📚 Installation des dépendances..."
"$POETRY_BIN" install

# 5) Vérifications
"$POETRY_BIN" --version
"$POETRY_BIN" env info

echo "✅ Setup terminé. Utilisez: poetry run <cmd> (ex: uvicorn app:app --reload)"
