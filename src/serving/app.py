"""
API FastAPI pour le modèle de classification Iris
Semaine 1 - MLOps Formation
"""

import json
import logging
import os
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Dict, Optional

import joblib
import numpy as np
from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, ConfigDict, Field, field_validator
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from .security import get_remote_address as get_client_ip
from .security import verify_api_key

# Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("iris_api")

# Configuration du rate limiter
# Utilise l'adresse IP du client pour limiter les requêtes
limiter = Limiter(key_func=get_client_ip)


# Initialisation de l'application FastAPI (lifespan utilisée pour startup/shutdown)
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gestionnaire de cycle de vie de l'application.
    Charge le modèle et les métadonnées et les expose via app.state.
    """
    # Configuration : chemin vers le dossier contenant le modèle (modifiable via ENV)
    model_dir = Path(os.getenv("MODEL_DIR", "models"))
    model_path = model_dir / "iris_model.pkl"
    metadata_path = model_dir / "metadata.json"
    metrics_path = model_dir / "metrics.json"

    # Par défaut on met None (évite globals)
    app.state.model = None
    app.state.metadata = None
    app.state.metrics = None

    try:
        if not model_path.exists():
            raise FileNotFoundError(f"Modèle non trouvé : {model_path}")

        # Chargement du modèle (joblib.load est synchrone ; ok ici dans startup)
        app.state.model = joblib.load(model_path)
        logger.info("✅ Modèle chargé avec succès : %s", model_path)

        # Chargement des métadonnées si présentes
        if metadata_path.exists():
            with metadata_path.open("r", encoding="utf-8") as f:
                app.state.metadata = json.load(f)
            logger.info("✅ Métadonnées chargées : %s", metadata_path)
        else:
            logger.info("ℹ️ Pas de fichier metadata trouvé à %s", metadata_path)

        # Chargement des métriques si présentes
        if metrics_path.exists():
            with metrics_path.open("r", encoding="utf-8") as f:
                app.state.metrics = json.load(f)
            logger.info("✅ Métriques chargées : %s", metrics_path)
        else:
            logger.info("ℹ️ Pas de fichier metrics trouvé à %s", metrics_path)

    except Exception as exc:
        logger.exception("❌ Erreur lors du chargement du modèle/métadonnées : %s", exc)
        app.state.model = None
        app.state.metadata = None
        app.state.metrics = None

    yield  # l'app est maintenant prête

    # Shutdown (libérer ressources si nécessaire)
    # Ici rien de spécial à faire pour joblib/scikit-learn
    logger.info("Shutdown application")


app = FastAPI(
    title="API Classification Iris",
    description="API pour prédire la classe d'une fleur d'iris",
    version="1.0.0",
    lifespan=lifespan,
)

# Configuration du rate limiter sur l'application
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Configuration CORS
# En production, utilisez une variable d'environnement pour restreindre les origines
allowed_origins_raw = os.getenv("CORS_ORIGINS", "*")
environment = os.getenv("ENVIRONMENT", "development").lower()

# ⚠️ SÉCURITÉ : En production, rejeter si CORS_ORIGINS contient "*"
if environment == "production" and "*" in allowed_origins_raw:
    logger.critical(
        "❌ SÉCURITÉ CRITIQUE : CORS autorise toutes les origines en production. "
        "L'API ne peut pas démarrer. Configurez CORS_ORIGINS avec des origines spécifiques."
    )
    raise ValueError(
        "CORS_ORIGINS ne peut pas contenir '*' en production. "
        "Configurez des origines spécifiques (ex: 'https://example.com,https://app.example.com')"
    )

allowed_origins = allowed_origins_raw.split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


# Middleware pour ajouter les headers de sécurité HTTP
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


# --- Pydantic models ---
class IrisFeatures(BaseModel):
    """Modèle Pydantic pour les features Iris avec validation de plage"""

    sepal_length: float = Field(
        ..., ge=0.0, le=20.0, description="Longueur du sépale (0-20 cm)"
    )
    sepal_width: float = Field(
        ..., ge=0.0, le=20.0, description="Largeur du sépale (0-20 cm)"
    )
    petal_length: float = Field(
        ..., ge=0.0, le=20.0, description="Longueur du pétale (0-20 cm)"
    )
    petal_width: float = Field(
        ..., ge=0.0, le=20.0, description="Largeur du pétale (0-20 cm)"
    )

    @field_validator("sepal_length", "sepal_width", "petal_length", "petal_width")
    @classmethod
    def validate_not_nan_or_inf(cls, v: float) -> float:
        """Valide que la valeur n'est pas NaN ou infinie"""
        if not isinstance(v, (int, float)) or not (v == v):  # NaN check
            raise ValueError("La valeur ne peut pas être NaN")
        if abs(v) == float("inf"):
            raise ValueError("La valeur ne peut pas être infinie")
        return float(v)

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "sepal_length": 5.1,
                "sepal_width": 3.5,
                "petal_length": 1.4,
                "petal_width": 0.2,
            }
        }
    )


class PredictionResponse(BaseModel):
    prediction: str
    confidence: float
    probabilities: Dict[str, float]


class HealthResponse(BaseModel):
    status: str
    model_loaded: bool
    version: str


# --- Endpoints ---
@app.get("/", response_model=Dict[str, str])
async def root():
    """
    Endpoint racine de l'API.
    ⚠️ Note : Cet endpoint n'exige pas d'authentification (information publique).
    """
    return {
        "message": "API Classification Iris - Semaine 1 MLOps",
        "docs": "/docs",
        "health": "/health",
        "security": "Cette API utilise l'authentification par API key. Fournissez votre clé via le header X-API-Key",
    }


@app.get("/health", response_model=HealthResponse)
@limiter.limit("30/minute")  # Rate limiting plus permissif pour le health check
async def health_check(request: Request):
    """
    Vérifie si le modèle est chargé (via app.state).
    ⚠️ Note : Cet endpoint n'exige pas d'authentification pour permettre le monitoring.
    """
    model_loaded = getattr(request.app.state, "model", None) is not None
    return HealthResponse(
        status="healthy" if model_loaded else "unhealthy",
        model_loaded=model_loaded,
        version=app.version,
    )


@app.post("/predict", response_model=PredictionResponse)
@limiter.limit("10/minute")  # ⚠️ SÉCURITÉ : 10 requêtes par minute par IP
async def predict_iris(
    features: IrisFeatures,
    request: Request,
    api_key: str = Depends(verify_api_key),  # ⚠️ SÉCURITÉ : Authentification requise
):
    """
    Prédiction de la classe d'une fleur d'iris.
    Récupère le modèle depuis request.app.state (évite globals).

    ⚠️ SÉCURITÉ :
    - Authentification : Requiert une API key via le header X-API-Key
    - Rate limiting : 10 requêtes par minute par adresse IP
    - Validation : Les entrées sont validées par Pydantic (IrisFeatures)
    """
    model = getattr(request.app.state, "model", None)
    metadata = getattr(request.app.state, "metadata", None)

    if model is None:
        # 503 Service Unavailable — le modèle n'est pas présent
        raise HTTPException(status_code=503, detail="Modèle non chargé")

    # Préparer l'array
    features_array = np.array(
        [
            features.sepal_length,
            features.sepal_width,
            features.petal_length,
            features.petal_width,
        ],
        dtype=float,
    ).reshape(1, -1)

    try:
        # Vérifier si le modèle supporte predict_proba
        if hasattr(model, "predict_proba"):
            proba = model.predict_proba(features_array)[0]
        else:
            # fallback : one-hot sur la prédiction simple (confiance = 1.0)
            pred_idx = int(model.predict(features_array)[0])
            proba = np.zeros(len(getattr(model, "classes_", [0])))
            if pred_idx < proba.shape[0]:
                proba[pred_idx] = 1.0
            else:
                # Incohérence : on reconstruira un vecteur minimal
                proba = np.array([1.0])

        # Récupérer noms des classes depuis metadata si fourni, sinon depuis model.classes_
        if metadata and "target_names" in metadata:
            class_names = metadata["target_names"]
        elif hasattr(model, "classes_"):
            # si model.classes_ est un array de labels (ex: [0,1,2]) on convertit en str
            class_names = [str(c) for c in model.classes_]
        else:
            class_names = ["setosa", "versicolor", "virginica"]

        # S'assurer que la longueur correspond
        if len(class_names) != len(proba):
            # si mismatch, on aligne en prenant min des deux longueurs
            n = min(len(class_names), len(proba))
            class_names = class_names[:n]
            proba = proba[:n]

        probabilities = {
            class_names[i]: float(proba[i]) for i in range(len(class_names))
        }
        # prédiction (classe la plus probable)
        pred_index = int(np.argmax(proba))
        predicted_class = class_names[pred_index]
        confidence = float(max(proba)) if proba.size > 0 else 0.0

        return PredictionResponse(
            prediction=predicted_class,
            confidence=confidence,
            probabilities=probabilities,
        )

    except Exception as exc:
        logger.exception("Erreur lors de la prédiction : %s", exc)
        # ⚠️ SÉCURITÉ : Ne pas exposer les détails de l'exception à l'utilisateur
        raise HTTPException(
            status_code=400,
            detail="Erreur lors de la prédiction. Veuillez vérifier vos données d'entrée.",
        )


@app.get("/model/info")
@limiter.limit(
    "20/minute"
)  # ⚠️ SÉCURITÉ : 20 requêtes par minute par IP (endpoint moins coûteux)
async def model_info(
    request: Request,
    api_key: str = Depends(verify_api_key),  # ⚠️ SÉCURITÉ : Authentification requise
):
    """Renvoie les métadonnées et métriques du modèle si disponibles"""
    metadata = getattr(request.app.state, "metadata", None)
    metrics = getattr(request.app.state, "metrics", None)
    model = getattr(request.app.state, "model", None)

    if metadata is None and model is None:
        raise HTTPException(
            status_code=404, detail="Modèle et métadonnées non disponibles"
        )

    # Construction d'une réponse
    # Séparation claire : metrics.json = métriques, metadata.json = métadonnées
    return {
        # Métadonnées du modèle (depuis metadata.json)
        "model_type": metadata.get("model_type")
        if metadata
        else getattr(model, "__class__", "Unknown").__name__,
        "n_features": metadata.get("n_features") if metadata else "Unknown",
        "n_samples": metadata.get("n_samples") if metadata else "Unknown",
        "feature_names": metadata.get("feature_names", []) if metadata else [],
        "target_names": metadata.get("target_names", [])
        if metadata
        else getattr(model, "classes_", []),
        # Métriques de performance (depuis metrics.json uniquement)
        "accuracy": metrics.get("accuracy") if metrics else "Unknown",
        "precision": metrics.get("precision") if metrics else "Unknown",
        "recall": metrics.get("recall") if metrics else "Unknown",
        "f1_score": metrics.get("f1_score") if metrics else "Unknown",
    }
