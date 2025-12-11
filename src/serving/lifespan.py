"""
Gestion du cycle de vie de l'application (startup/shutdown)
"""

import json
import logging
import os
from contextlib import asynccontextmanager
from pathlib import Path

import joblib
from fastapi import FastAPI

from .metrics import model_loaded

logger = logging.getLogger("iris_api")


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

    app.state.model = None
    app.state.metadata = None
    app.state.metrics = None

    try:
        if not model_path.exists():
            raise FileNotFoundError(f"Modèle non trouvé : {model_path}")

        app.state.model = joblib.load(model_path)
        model_loaded.set(1)
        logger.info("Model loaded", extra={"path": str(model_path)})

        # Chargement métadonnées et métriques
        for path, attr in [(metadata_path, "metadata"), (metrics_path, "metrics")]:
            if path.exists():
                setattr(app.state, attr, json.loads(path.read_text(encoding="utf-8")))
                logger.info(f"{attr.capitalize()} loaded", extra={"path": str(path)})
            else:
                setattr(app.state, attr, None)
                logger.warning(
                    f"{attr.capitalize()} not found", extra={"path": str(path)}
                )

    except Exception as exc:
        model_loaded.set(0)
        logger.exception("Error loading model", extra={"error": str(exc)})
        app.state.model = app.state.metadata = app.state.metrics = None

    yield  # l'app est maintenant prête

    model_loaded.set(0)

