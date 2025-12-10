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

# Configuration de l'API key header
API_KEY_HEADER_NAME = "X-API-Key"
api_key_header = APIKeyHeader(name=API_KEY_HEADER_NAME, auto_error=False)


def get_api_key_from_env() -> Optional[str]:
    """
    Récupère la clé API depuis les variables d'environnement.

    Returns:
        La clé API ou None si non configurée
    """
    return os.getenv("API_KEY")


def verify_api_key(
    request: Request, api_key: Optional[str] = Security(api_key_header)
) -> str:
    """
    Vérifie que la clé API fournie est valide.

    Args:
        request: La requête FastAPI
        api_key: La clé API extraite du header

    Returns:
        La clé API si valide

    Raises:
        HTTPException: Si la clé API est invalide ou manquante
    """
    # Récupérer la clé API configurée
    valid_api_key = get_api_key_from_env()
    environment = os.getenv("ENVIRONMENT", "development").lower()

    # En production, l'authentification est obligatoire
    if environment == "production":
        if not valid_api_key:
            logger.error(
                "❌ API_KEY non configurée en production. "
                "L'authentification est obligatoire en production !"
            )
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Configuration de sécurité invalide : API_KEY manquante en production",
            )

    # Si aucune clé API n'est configurée, désactiver l'authentification
    # (uniquement en développement)
    if not valid_api_key:
        if environment != "production":
            logger.warning(
                "⚠️ API_KEY non configurée dans les variables d'environnement. "
                "L'authentification est désactivée (mode développement uniquement). "
                "Configurez API_KEY en production !"
            )
            return "no-auth"  # Permet l'accès si pas de clé configurée (dev uniquement)
        else:
            # Ne devrait jamais arriver ici (déjà géré ci-dessus), mais sécurité supplémentaire
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Configuration de sécurité invalide",
            )

    # Si une clé est requise mais non fournie
    if not api_key:
        logger.warning(
            f"Tentative d'accès sans API key depuis {request.client.host if request.client else 'unknown'}"
        )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="API key manquante. Fournissez la clé via le header X-API-Key",
            headers={"WWW-Authenticate": "ApiKey"},
        )

    # Vérifier que la clé correspond
    if api_key != valid_api_key:
        logger.warning(
            f"Tentative d'accès avec une API key invalide depuis {request.client.host if request.client else 'unknown'}"
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="API key invalide",
            headers={"WWW-Authenticate": "ApiKey"},
        )

    logger.debug(
        f"Accès autorisé avec API key valide depuis {request.client.host if request.client else 'unknown'}"
    )
    return api_key


def get_remote_address(request: Request) -> str:
    """
    Récupère l'adresse IP du client pour le rate limiting.

    Args:
        request: La requête FastAPI

    Returns:
        L'adresse IP du client ou "unknown"
    """
    if request.client:
        # Vérifier les headers de proxy (X-Forwarded-For, X-Real-IP)
        forwarded_for = request.headers.get("X-Forwarded-For")
        if forwarded_for:
            # Prendre la première IP (le client réel)
            return forwarded_for.split(",")[0].strip()

        real_ip = request.headers.get("X-Real-IP")
        if real_ip:
            return real_ip.strip()

        return request.client.host

    return "unknown"
