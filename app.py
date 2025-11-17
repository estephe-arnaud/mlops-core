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
from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel, ConfigDict

# Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("iris_api")


# Initialisation de l'application FastAPI (lifespan utilisée pour startup/shutdown)
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gestionnaire de cycle de vie de l'application.
    Charge le modèle et les métadonnées et les expose via app.state.
    """
    # Configuration : chemin vers le dossier contenant le modèle (modifiable via ENV)
    model_dir = Path(os.getenv("MODEL_DIR", "models"))
    model_path = model_dir / "iris_model.pkl"
    metadata_path = model_dir / "model_metadata.json"

    # Par défaut on met None (évite globals)
    app.state.model = None
    app.state.metadata = None

    try:
        if not model_path.exists():
            raise FileNotFoundError(f"Modèle non trouvé : {model_path}")

        # Chargement du modèle (joblib.load est synchrone ; ok ici dans startup)
        app.state.model = joblib.load(model_path)
        logger.info("✅ Modèle chargé avec succès : %s", model_path)

        # Chargement des métadatas si présentes
        if metadata_path.exists():
            with metadata_path.open("r", encoding="utf-8") as f:
                app.state.metadata = json.load(f)
            logger.info("✅ Métadonnées chargées : %s", metadata_path)
        else:
            logger.info("ℹ️ Pas de fichier metadata trouvé à %s", metadata_path)

    except Exception as exc:
        logger.exception("❌ Erreur lors du chargement du modèle/métadonnées : %s", exc)
        app.state.model = None
        app.state.metadata = None

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


# --- Pydantic models ---
class IrisFeatures(BaseModel):
    sepal_length: float
    sepal_width: float
    petal_length: float
    petal_width: float

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
    return {
        "message": "API Classification Iris - Semaine 1 MLOps",
        "docs": "/docs",
        "health": "/health",
    }


@app.get("/health", response_model=HealthResponse)
async def health_check(request: Request):
    """Vérifie si le modèle est chargé (via app.state)"""
    model_loaded = getattr(request.app.state, "model", None) is not None
    return HealthResponse(
        status="healthy" if model_loaded else "unhealthy",
        model_loaded=model_loaded,
        version=app.version,
    )


@app.post("/predict", response_model=PredictionResponse)
async def predict_iris(features: IrisFeatures, request: Request):
    """
    Prédiction de la classe d'une fleur d'iris.
    Récupère le modèle depuis request.app.state (évite globals).
    
    ⚠️ SÉCURITÉ : Les entrées sont validées par Pydantic (IrisFeatures).
    En production, ajoutez :
    - Rate limiting pour éviter les abus
    - Authentification/autorisation si nécessaire
    - Validation des plages de valeurs (ex: valeurs négatives acceptées mais peuvent être suspectes)
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
        raise HTTPException(
            status_code=400, detail=f"Erreur lors de la prédiction : {exc}"
        )


@app.get("/model/info")
async def model_info(request: Request):
    """Renvoie les métadonnées du modèle si disponibles"""
    metadata = getattr(request.app.state, "metadata", None)
    model = getattr(request.app.state, "model", None)

    if metadata is None and model is None:
        raise HTTPException(
            status_code=404, detail="Modèle et métadonnées non disponibles"
        )

    # Construction d'une réponse prudente
    return {
        "model_type": metadata.get("model_type")
        if metadata
        else getattr(model, "__class__", "Unknown").__name__,
        "accuracy": metadata.get("accuracy") if metadata else "Unknown",
        "n_features": metadata.get("n_features") if metadata else "Unknown",
        "n_samples": metadata.get("n_samples") if metadata else "Unknown",
        "feature_names": metadata.get("feature_names", []) if metadata else [],
        "target_names": metadata.get("target_names", [])
        if metadata
        else getattr(model, "classes_", []),
    }
