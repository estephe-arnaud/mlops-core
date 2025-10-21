# Dockerfile pour l'API FastAPI - Semaine 1 MLOps
# Un Dockerfile est un script qui décrit comment construire une image Docker
# Chaque instruction crée une nouvelle "couche" dans l'image finale

# FROM : Définit l'image de base à utiliser
# python:3.11-slim = image officielle Python 3.11 en version légère (~45MB)
# Cette image contient déjà Python, pip et les outils essentiels
FROM python:3.11-slim

# ENV : Definit des variables d'environnement dans le conteneur
# Ces variables sont disponibles pendant le build ET l'execution
# PYTHONDONTWRITEBYTECODE=1 : Empeche Python de creer des fichiers .pyc (optimisation)
# PYTHONUNBUFFERED=1 : Force Python a afficher les logs en temps reel (pas de buffer)
# PYTHONPATH=/app : Ajoute /app au chemin Python pour les imports
# POETRY_NO_INTERACTION=1 : Mode non-interactif pour Poetry (pas de questions)
# POETRY_VENV_IN_PROJECT=1 : Cree les environnements virtuels dans le projet
# POETRY_CACHE_DIR=/tmp/poetry_cache : Cache Poetry dans /tmp (sera supprime)
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app \
    POETRY_NO_INTERACTION=1 \
    POETRY_VENV_IN_PROJECT=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache

# WORKDIR : Change le répertoire de travail courant
# Toutes les commandes suivantes s'exécutent dans /app
# Si le répertoire n'existe pas, Docker le crée automatiquement
WORKDIR /app

# RUN : Execute une commande dans le conteneur pendant le build
# Installation des dependances systeme necessaires pour compiler les packages Python
# apt-get update : Met a jour la liste des paquets
# gcc : Compilateur C (necessaire pour certains packages Python)
# g++ : Compilateur C++ (pour scikit-learn, numpy, etc.)
# curl : Outil pour telecharger des fichiers (au cas ou)
# build-essential : Ensemble d'outils de compilation essentiels
# rm -rf /var/lib/apt/lists/* : Supprime le cache apt pour reduire la taille de l'image
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Installation de Poetry via pip (plus simple que curl dans Docker)
# --no-cache-dir : n'utilise pas le cache pip (réduit la taille)
# poetry==1.7.1 : version spécifique pour la reproductibilité
RUN pip install --no-cache-dir poetry==1.7.1

# COPY : Copie des fichiers de l'hôte vers le conteneur
# Copie d'abord les fichiers de dépendances (optimisation des couches Docker)
# pyproject.toml : configuration Poetry et dépendances
# poetry.lock : versions exactes des dépendances (reproductibilité)
COPY pyproject.toml poetry.lock ./

# Configuration et installation des dependances Python avec Poetry
# poetry config virtualenvs.create false : Desactive les environnements virtuels (on est deja dans un conteneur)
# poetry install --only=main --no-dev : Installe seulement les dependances de production (pas les dev)
# rm -rf $POETRY_CACHE_DIR : Supprime le cache Poetry pour reduire la taille
RUN poetry config virtualenvs.create false && \
    poetry install --only=main --no-dev && \
    rm -rf $POETRY_CACHE_DIR

# Copie du reste du code source (après l'installation des dépendances)
# Cette séparation optimise le cache Docker : si seul le code change, les dépendances ne sont pas réinstallées
#
# OPTIMISATION DU CACHE DOCKER :
# Docker utilise un système de couches (layers) avec cache intelligent :
# 1. Chaque instruction RUN/COPY crée une nouvelle couche
# 2. Si une couche n'a pas changé, Docker réutilise le cache
# 3. Si une couche change, toutes les couches suivantes sont reconstruites
#
# STRATEGIE OPTIMISEE :
# Étape 1: COPY pyproject.toml poetry.lock ./  (couche A)
# Étape 2: RUN poetry install                    (couche B - dépend des fichiers de dépendances)
# Étape 3: COPY . .                              (couche C - dépend du code source)
#
# AVANTAGES :
# - Si seul le code change (app.py, train_model.py) → couches A et B réutilisées
# - Si les dépendances changent → couches A, B et C reconstruites
# - Gain de temps : pas de réinstallation des dépendances à chaque changement de code
# - Gain d'espace : cache partagé entre les builds
#
# EXEMPLE CONCRET :
# Build 1: pyproject.toml + code → toutes les couches construites
# Build 2: seul app.py modifié → couches A et B réutilisées, seule C reconstruite
# Build 3: nouvelle dépendance → toutes les couches reconstruites
COPY . .

# Création du répertoire pour stocker les modèles ML
# -p : crée les répertoires parents si nécessaire
RUN mkdir -p models

# Entraînement du modèle ML au moment du build
# Le modèle sera prêt dès le démarrage du conteneur
RUN python train_model.py

# EXPOSE : Documente le port que le conteneur écoute
# N'ouvre pas réellement le port (c'est fait avec -p au run)
# 8000 : port standard pour FastAPI/uvicorn
# 
# MAPPING DES PORTS DOCKER :
# docker run -p HOST_PORT:CONTAINER_PORT
# Exemples :
# - docker run -p 8000:8000  → http://localhost:8000
# - docker run -p 3000:8000  → http://localhost:3000 (port hôte différent)
# - docker run -p 9000:8000  → http://localhost:9000 (port hôte différent)
# Le premier port = machine hôte, le second = conteneur
EXPOSE 8000

# CMD : Commande par défaut exécutée au démarrage du conteneur
# Format JSON array : évite l'interprétation par le shell
# uvicorn : serveur ASGI pour FastAPI
# app:app : module app, variable app (FastAPI instance)
# --host 127.0.0.1 : écoute seulement sur localhost (plus sécurisé)
# --port 8000 : port d'écoute DANS LE CONTENEUR
#
# IMPORTANT : Ce port 8000 est le port DANS le conteneur
# Pour accéder depuis l'extérieur, utiliser le mapping des ports :
# docker run -p 8000:8000  → http://localhost:8000
# docker run -p 3000:8000  → http://localhost:3000
# Le premier port (8000 ou 3000) = machine hôte
# Le second port (8000) = port dans le conteneur (celui-ci)
CMD ["uvicorn", "app:app", "--host", "127.0.0.1", "--port", "8000"]
