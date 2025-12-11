"""
Module de sécurité pour l'API FastAPI
Gère l'authentification par API key et le rate limiting
"""

import logging
import os
from typing import Optional

from fastapi import HTTPException, Request, Security, status
from fastapi.security import APIKeyHeader

logger = logging.getLogger("iris_api")

API_KEY_HEADER_NAME = "X-API-Key"
api_key_header = APIKeyHeader(name=API_KEY_HEADER_NAME, auto_error=False)


def verify_api_key(
    request: Request, api_key: Optional[str] = Security(api_key_header)
) -> str:
    """Vérifie que la clé API fournie est valide"""
    environment = os.getenv("ENVIRONMENT", "development").lower()
    valid_key = os.getenv("API_KEY")

    # En production, l'authentification est obligatoire
    if environment == "production" and not valid_key:
        logger.error("❌ API_KEY manquante en production")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Configuration de sécurité invalide : API_KEY manquante en production",
        )

    # Validation de la longueur de l'API key (recommandation sécurité)
    if valid_key and len(valid_key) < 32:
        logger.warning(
            f"⚠️ API_KEY trop courte ({len(valid_key)} caractères). "
            "Minimum 32 caractères recommandé pour la sécurité."
        )

    # Si aucune clé, désactiver l'authentification (dev uniquement)
    if not valid_key:
        if environment != "production":
            logger.warning(
                "⚠️ API_KEY non configurée - authentification désactivée (dev)"
            )
            return "no-auth"
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Configuration de sécurité invalide",
        )

    # Si une clé est requise mais non fournie
    if not api_key:
        client_ip = request.client.host if request.client else "unknown"
        logger.warning(f"Tentative d'accès sans API key depuis {client_ip}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="API key manquante. Fournissez la clé via le header X-API-Key",
            headers={"WWW-Authenticate": "ApiKey"},
        )

    # Vérifier que la clé correspond
    if api_key != valid_key:
        client_ip = request.client.host if request.client else "unknown"
        logger.warning(
            f"Tentative d'accès avec une API key invalide depuis {client_ip}"
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="API key invalide",
            headers={"WWW-Authenticate": "ApiKey"},
        )

    return api_key


def get_remote_address(request: Request) -> str:
    """Récupère l'adresse IP du client pour le rate limiting (support proxy)"""
    if not request.client:
        return "unknown"
    # Headers de proxy (X-Forwarded-For, X-Real-IP)
    if forwarded := request.headers.get("X-Forwarded-For"):
        return forwarded.split(",")[0].strip()
    if real_ip := request.headers.get("X-Real-IP"):
        return real_ip.strip()
    return request.client.host
