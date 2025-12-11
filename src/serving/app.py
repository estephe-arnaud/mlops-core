"""
Point d'entrée de l'application FastAPI
Assemble tous les composants : routes, middleware, lifespan
"""

import logging
import os

from fastapi import FastAPI

from .lifespan import lifespan
from .middleware import setup_cors, setup_rate_limiting, setup_security_headers
from .routes import register_routes

# Configuration du logging
logging.basicConfig(
    level=getattr(logging, os.getenv("LOG_LEVEL", "INFO").upper(), logging.INFO),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)

# Création de l'application FastAPI
app = FastAPI(
    title="API Classification Iris",
    description="API pour prédire la classe d'une fleur d'iris",
    version="1.0.0",
    lifespan=lifespan,
)

# Configuration des middlewares
setup_cors(app)
setup_security_headers(app)
setup_rate_limiting(app)

# Enregistrement des routes
register_routes(app)
