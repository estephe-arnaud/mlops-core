#!/bin/bash

# Script d'installation et configuration de Poetry (macOS/Linux)
# Usage: ./scripts/setup_poetry.sh

set -euo pipefail

echo "🐍 Setup Poetry (python3.11 requis)"

OS_NAME="$(uname -s 2>/dev/null || echo unknown)"
SHELL_NAME="$(basename "${SHELL:-/bin/bash}")"

ensure_path_local_bin() {
	# Ajoute ~/.local/bin au PATH de façon idempotente et recharge le shell courant
	local export_line="export PATH=\"$HOME/.local/bin:$PATH\""
	case "$SHELL_NAME" in
		zsh)
			local rc_file="$HOME/.zshrc"
			grep -qs "^export PATH=\\\"\$HOME/.local/bin:\$PATH\\\"$" "$rc_file" 2>/dev/null || echo "$export_line" >> "$rc_file"
			# Recharge le shell interactif
			if [[ "$OS_NAME" == "Darwin" ]]; then
				exec zsh -l
			else
				exec zsh -l
			fi
			;;
		bash|sh)
			local rc_file="$HOME/.bashrc"
			grep -qs "^export PATH=\\\"\$HOME/.local/bin:\$PATH\\\"$" "$rc_file" 2>/dev/null || echo "$export_line" >> "$rc_file"
			# Recharge le shell interactif
			exec bash -l
			;;
		*)
			# Par défaut, écrire dans .profile
			local rc_file="$HOME/.profile"
			grep -qs "^export PATH=\\\"\$HOME/.local/bin:\$PATH\\\"$" "$rc_file" 2>/dev/null || echo "$export_line" >> "$rc_file"
			;;
	 esac
}

install_python_311() {
	if [[ "$OS_NAME" == "Darwin" ]]; then
		if command -v brew >/dev/null 2>&1; then
			echo "📦 Installation de python@3.11 via Homebrew"
			brew install python@3.11 || true
		else
			echo "❌ Homebrew introuvable. Installez-le: https://brew.sh/"
			return 1
		fi
	else
		# Linux - Méthodes officielles par distribution
		if command -v apt-get >/dev/null 2>&1; then
			echo "📦 Installation de python3.11 via apt-get (Ubuntu/Debian officiel)"
			sudo apt-get update -y
			sudo apt-get install -y python3.11 python3.11-venv python3.11-distutils || true
		elif command -v dnf >/dev/null 2>&1; then
			echo "📦 Installation de python3.11 via dnf (Fedora/RHEL officiel)"
			sudo dnf install -y python3.11 python3.11-pip || true
		elif command -v pacman >/dev/null 2>&1; then
			echo "📦 Installation de python via pacman (Arch Linux officiel)"
			sudo pacman -Sy --noconfirm python || true
		elif command -v snap >/dev/null 2>&1; then
			echo "📦 Installation de python3.11 via snap (universel)"
			sudo snap install python311 --classic || true
		else
			echo "❌ Gestionnaire de paquets non pris en charge."
			echo "   Installez Python 3.11 manuellement ou utilisez snap: sudo snap install python311 --classic"
			return 1
		fi
	fi
}

detect_python_311() {
	local py_bin=""
	if [[ "$OS_NAME" == "Darwin" ]]; then
		# Priorités: opt path Homebrew, lien classique Homebrew, sinon PATH
		if [[ -x "/opt/homebrew/opt/python@3.11/bin/python3.11" ]]; then
			py_bin="/opt/homebrew/opt/python@3.11/bin/python3.11"
		elif [[ -x "/usr/local/opt/python@3.11/bin/python3.11" ]]; then
			py_bin="/usr/local/opt/python@3.11/bin/python3.11"
		elif [[ -x "/opt/homebrew/bin/python3.11" ]]; then
			py_bin="/opt/homebrew/bin/python3.11"
		elif command -v python3.11 >/dev/null 2>&1; then
			py_bin="$(command -v python3.11)"
		fi
	else
		# Linux - Vérifier snap puis PATH standard
		if [[ -x "/snap/python311/current/bin/python3.11" ]]; then
			py_bin="/snap/python311/current/bin/python3.11"
		elif command -v python3.11 >/dev/null 2>&1; then
			py_bin="$(command -v python3.11)"
		fi
	fi
	printf "%s" "$py_bin"
}

# 1) Détecter ou installer python3.11
PY_BIN="$(detect_python_311)"
if [[ -z "$PY_BIN" ]]; then
	echo "ℹ️ python3.11 introuvable, tentative d'installation..."
	install_python_311 || true
	PY_BIN="$(detect_python_311)"
fi

if [[ -z "$PY_BIN" ]]; then
	echo "❌ python3.11 toujours introuvable après tentative d'installation."
	if [[ "$OS_NAME" == "Darwin" ]]; then
		echo "   Astuce (macOS): brew install python@3.11"
	else
		echo "   Astuces Linux:"
		echo "   • Ubuntu/Debian: sudo apt-get install -y python3.11"
		echo "   • Fedora: sudo dnf install -y python3.11"
		echo "   • Arch: sudo pacman -S python"
		echo "   • Universel: sudo snap install python311 --classic"
	fi
	exit 1
fi

# 2) Installer Poetry si absent (via python3.11 explicite)
if ! command -v poetry >/dev/null 2>&1 && [[ ! -x "$HOME/.local/bin/poetry" ]]; then
	echo "📦 Installation de Poetry..."
	if ! command -v curl >/dev/null 2>&1; then
		echo "ℹ️ curl introuvable, installation recommandée pour l'installation de Poetry."
	fi
	curl -sSL https://install.python-poetry.org | "$PY_BIN" -
fi

# 3) Localiser le binaire Poetry et s'assurer du PATH
POETRY_BIN="$(command -v poetry || true)"
if [[ -z "$POETRY_BIN" && -x "$HOME/.local/bin/poetry" ]]; then
	POETRY_BIN="$HOME/.local/bin/poetry"
fi

if [[ -z "${POETRY_BIN:-}" ]]; then
	echo "ℹ️ Ajout de ~/.local/bin au PATH puis rechargement du shell..."
	ensure_path_local_bin
	POETRY_BIN="$(command -v poetry || true)"
fi

if [[ -z "${POETRY_BIN:-}" ]]; then
	echo "❌ 'poetry' introuvable après mise à jour du PATH."
	echo "   Vous pouvez ajouter manuellement: echo 'export PATH=\"$HOME/.local/bin:$PATH\"' >> ~/.zshrc && exec zsh"
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
