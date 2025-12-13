"""
Gestion du cycle de vie de l'application (startup/shutdown)
"""

import json
import logging
import os
from contextlib import asynccontextmanager
from pathlib import Path

import mlflow
import mlflow.sklearn
from fastapi import FastAPI

from .metrics import model_loaded

logger = logging.getLogger("iris_api")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gestionnaire de cycle de vie de l'application.
    Charge le modèle depuis MLflow via l'URI dans metadata.json.
    Support GCS backend en production.
    """
    # Configuration : chemin vers le dossier contenant les métadonnées (modifiable via ENV)
    model_dir = Path(os.getenv("MODEL_DIR", "models"))
    metadata_path = model_dir / "metadata.json"
    metrics_path = model_dir / "metrics.json"

    app.state.model = None
    app.state.metadata = None
    app.state.metrics = None

    try:
        # Charger les métadonnées d'abord
        if not metadata_path.exists():
            raise FileNotFoundError(f"Métadonnées non trouvées : {metadata_path}")

        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        app.state.metadata = metadata

        # Configurer MLflow tracking URI si fourni (pour GCS backend en production)
        mlflow_tracking_uri = os.getenv("MLFLOW_TRACKING_URI")
        if mlflow_tracking_uri:
            mlflow.set_tracking_uri(mlflow_tracking_uri)
            logger.info(f"MLflow Tracking URI configuré: {mlflow_tracking_uri}")

        # Charger le modèle depuis MLflow
        mlflow_run_id = metadata.get("mlflow_run_id")

        if not mlflow_run_id:
            raise ValueError(
                "mlflow_run_id non trouvé dans metadata.json. Le modèle doit être entraîné avec MLflow."
            )

        # Charger le modèle via runs:/<run_id>/model (fonctionne avec GCS/local)
        # MLflow résout automatiquement l'URI selon MLFLOW_TRACKING_URI
        try:
            model_uri = f"runs:/{mlflow_run_id}/model"
            app.state.model = mlflow.sklearn.load_model(model_uri)
            model_loaded.set(1)
            logger.info(
                "Model loaded from MLflow",
                extra={
                    "run_id": mlflow_run_id,
                    "tracking_uri": mlflow_tracking_uri or "local (mlruns/)",
                },
            )
        except Exception as exc:
            raise FileNotFoundError(
                f"Impossible de charger le modèle depuis MLflow (run_id: {mlflow_run_id}, tracking_uri: {mlflow_tracking_uri or 'local'}): {exc}"
            ) from exc

        # Charger les métriques
        if metrics_path.exists():
            app.state.metrics = json.loads(metrics_path.read_text(encoding="utf-8"))
            logger.info("Metrics loaded", extra={"path": str(metrics_path)})
        else:
            app.state.metrics = None
            logger.warning("Metrics not found", extra={"path": str(metrics_path)})

    except Exception as exc:
        model_loaded.set(0)
        logger.exception("Error loading model", extra={"error": str(exc)})
        app.state.model = app.state.metadata = app.state.metrics = None

    yield  # l'app est maintenant prête

    model_loaded.set(0)
