"""
API FastAPI pour le modèle de classification Iris
Semaine 1 - MLOps Formation
"""

import json
import os
from contextlib import asynccontextmanager
from typing import Any, Dict, List

import joblib
import numpy as np
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, ConfigDict

# Chargement du modèle et des métadonnées
model = None
metadata = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gestionnaire de cycle de vie de l'application"""
    # Startup
    global model, metadata
    
    try:
        # Chargement du modèle
        model_path = "models/iris_model.pkl"
        if not os.path.exists(model_path):
            raise FileNotFoundError(f"Modèle non trouvé : {model_path}")
        
        model = joblib.load(model_path)
        
        # Chargement des métadonnées
        metadata_path = "models/model_metadata.json"
        if os.path.exists(metadata_path):
            with open(metadata_path, "r") as f:
                metadata = json.load(f)
        
        print("✅ Modèle chargé avec succès !")
        
    except Exception as e:
        print(f"❌ Erreur lors du chargement du modèle : {e}")
        model = None
        metadata = None
    
    yield
    
    # Shutdown (si nécessaire)
    pass

# Initialisation de l'application FastAPI
app = FastAPI(
    title="API Classification Iris",
    description="API pour prédire la classe d'une fleur d'iris",
    version="1.0.0",
    lifespan=lifespan
)

class IrisFeatures(BaseModel):
    """Modèle Pydantic pour la validation des données d'entrée"""
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
                "petal_width": 0.2
            }
        }
    )

class PredictionResponse(BaseModel):
    """Modèle Pydantic pour la réponse de prédiction"""
    prediction: str
    confidence: float
    probabilities: Dict[str, float]

class HealthResponse(BaseModel):
    """Modèle Pydantic pour la réponse de santé"""
    status: str
    model_loaded: bool
    version: str


@app.get("/", response_model=Dict[str, str])
async def root():
    """Endpoint racine avec informations sur l'API"""
    return {
        "message": "API Classification Iris - Semaine 1 MLOps",
        "docs": "/docs",
        "health": "/health"
    }

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Vérification de l'état de santé de l'API"""
    return HealthResponse(
        status="healthy" if model is not None else "unhealthy",
        model_loaded=model is not None,
        version="1.0.0"
    )

@app.post("/predict", response_model=PredictionResponse)
async def predict_iris(features: IrisFeatures):
    """
    Prédiction de la classe d'une fleur d'iris
    
    Args:
        features: Caractéristiques de la fleur (longueur/largeur sépale et pétale)
    
    Returns:
        Prédiction avec probabilités pour chaque classe
    """
    if model is None:
        raise HTTPException(status_code=503, detail="Modèle non chargé")
    
    try:
        # Conversion des features en array numpy
        features_array = np.array([
            features.sepal_length,
            features.sepal_width,
            features.petal_length,
            features.petal_width
        ]).reshape(1, -1)
        
        # Prédiction
        prediction_proba = model.predict_proba(features_array)[0]
        prediction_class = model.predict(features_array)[0]
        
        # Récupération des noms des classes
        if metadata and "target_names" in metadata:
            class_names = metadata["target_names"]
        else:
            class_names = ["setosa", "versicolor", "virginica"]
        
        # Création du dictionnaire des probabilités
        probabilities = {
            class_names[i]: float(prediction_proba[i]) 
            for i in range(len(class_names))
        }
        
        # Classe prédite
        predicted_class = class_names[prediction_class]
        confidence = float(max(prediction_proba))
        
        return PredictionResponse(
            prediction=predicted_class,
            confidence=confidence,
            probabilities=probabilities
        )
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Erreur lors de la prédiction : {str(e)}")

@app.get("/model/info")
async def model_info():
    """Informations sur le modèle chargé"""
    if metadata is None:
        raise HTTPException(status_code=404, detail="Métadonnées du modèle non disponibles")
    
    return {
        "model_type": metadata.get("model_type", "Unknown"),
        "accuracy": metadata.get("accuracy", "Unknown"),
        "n_features": metadata.get("n_features", "Unknown"),
        "n_samples": metadata.get("n_samples", "Unknown"),
        "feature_names": metadata.get("feature_names", []),
        "target_names": metadata.get("target_names", [])
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
