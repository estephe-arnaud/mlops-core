"""
Configuration des middlewares et sécurité HTTP
"""

import logging
import os

from fastapi import Request
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from .security import get_remote_address as get_client_ip

logger = logging.getLogger("iris_api")

# Configuration du rate limiter
limiter = Limiter(key_func=get_client_ip)


def setup_cors(app):
    """Configure le middleware CORS"""
    allowed_origins_raw = os.getenv("CORS_ORIGINS", "*")
    environment = os.getenv("ENVIRONMENT", "development").lower()

    if environment == "production" and "*" in allowed_origins_raw:
        logger.critical(
            "❌ SÉCURITÉ CRITIQUE : CORS autorise toutes les origines en production"
        )
        raise ValueError("CORS_ORIGINS ne peut pas contenir '*' en production")

    allowed_origins = allowed_origins_raw.split(",")

    app.add_middleware(
        CORSMiddleware,
        allow_origins=allowed_origins,
        allow_credentials=False,
        allow_methods=["GET", "POST"],
        allow_headers=["*"],
    )


def setup_security_headers(app):
    """Configure le middleware pour les headers de sécurité HTTP"""

    @app.middleware("http")
    async def add_security_headers(request: Request, call_next):
        """Ajoute les headers de sécurité HTTP à toutes les réponses"""
        response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers[
            "Strict-Transport-Security"
        ] = "max-age=31536000; includeSubDomains"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        return response


def setup_rate_limiting(app):
    """Configure le rate limiting"""
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

