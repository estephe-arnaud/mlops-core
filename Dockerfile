# Dockerfile pour l'API FastAPI - Semaine 1 MLOps
FROM python:3.11-slim

# Variables d'environnement Python et Poetry
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app \
    POETRY_NO_INTERACTION=1 \
    POETRY_VENV_IN_PROJECT=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache

WORKDIR /app

# Installation des dépendances système pour compiler les packages Python
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Installation de Poetry
RUN pip install --no-cache-dir poetry==1.7.1

# Copie des fichiers de dépendances (optimisation du cache Docker)
COPY pyproject.toml poetry.lock ./

# Installation des dépendances Python
RUN poetry config virtualenvs.create false && \
    poetry install --only=main --no-dev && \
    rm -rf $POETRY_CACHE_DIR

# Copie du code source
COPY . .

# Création du répertoire pour les modèles ML
RUN mkdir -p models

# Entraînement du modèle ML au build
RUN python train_model.py

# Exposition du port 8000
EXPOSE 8000

# Commande de démarrage
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
