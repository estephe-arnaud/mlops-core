# Dockerfile optimisé pour l'API FastAPI - MLOps Core
# Utilise un multi-stage build pour réduire la taille de l'image finale

# ============================================================================
# STAGE 1: Builder - Installation des dépendances et compilation
# ============================================================================
FROM python:3.11-slim AS builder

# Argument de build pour la version de Poetry (plus flexible qu'ENV)
ARG POETRY_VERSION=1.7.1

# Variables d'environnement pour Poetry
ENV POETRY_NO_INTERACTION=1 \
    POETRY_VENV_IN_PROJECT=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache

WORKDIR /app

# Installation des dépendances système et Poetry en une seule couche
# (gcc, g++, build-essential sont nécessaires pour certains packages comme scikit-learn)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    curl \
    build-essential \
    && pip install --no-cache-dir poetry==${POETRY_VERSION} \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /root/.cache/pip

# Copie des fichiers de dépendances (optimisation du cache Docker)
# Cette étape est mise en cache si pyproject.toml et poetry.lock ne changent pas
COPY pyproject.toml poetry.lock ./

# Installation des dépendances Python dans un environnement virtuel
# Utilisation de --no-root pour éviter d'installer le package lui-même
# Suppression du poetry export inutile (requirements.txt non utilisé)
RUN poetry config virtualenvs.create true && \
    poetry config virtualenvs.in-project true && \
    poetry install --only=main --no-dev --no-root && \
    rm -rf $POETRY_CACHE_DIR /root/.cache/pip

# ============================================================================
# STAGE 2: Runtime - Image finale légère
# ============================================================================
FROM python:3.11-slim AS runtime

# Variables d'environnement Python
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app \
    PATH="/app/.venv/bin:$PATH"

WORKDIR /app

# Création d'un utilisateur non-root et installation des dépendances runtime
# (curl pour le healthcheck, bash pour la compatibilité shell)
RUN groupadd -r appuser && useradd -r -g appuser -m appuser && \
    apt-get update && apt-get install -y --no-install-recommends \
    curl \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Copie de l'environnement virtuel depuis le stage builder
COPY --from=builder /app/.venv /app/.venv

# Copie du code source avec les bonnes permissions (après l'installation des dépendances pour optimiser le cache)
# Note: models/ est inclus (contient uniquement metadata.json et metrics.json, légers)
COPY --chown=appuser:appuser . .

# S'assurer que tous les fichiers appartiennent à appuser (y compris .venv)
RUN chown -R appuser:appuser /app

# Passage à l'utilisateur non-root
USER appuser

# Exposition du port 8000
EXPOSE 8000

# Health check intégré dans le Dockerfile
# Vérifie que l'API répond correctement sur l'endpoint /health
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Commande de démarrage
# ⚠️ SÉCURITÉ : Le 0.0.0.0 fait référence à l'INTÉRIEUR du container
# L'exposition sur la machine hôte est contrôlée par le port mapping Docker
# Dans docker-compose.yml : "127.0.0.1:8000:8000" limite l'accès à localhost ✅
# En production, utilisez un reverse proxy (nginx, traefik) et limitez l'accès
# via firewall/security groups plutôt que d'exposer directement l'API
#
# Note : Le modèle ML est chargé depuis MLflow (local: mlruns/, production: GCS)
# Les fichiers models/metadata.json et models/metrics.json sont inclus dans l'image
# L'entraînement doit être fait séparément (make train) avant de builder l'image
CMD ["uvicorn", "src.serving.app:app", "--host", "0.0.0.0", "--port", "8000"]
