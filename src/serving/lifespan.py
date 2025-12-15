"""
Gestion du cycle de vie de l'application (startup/shutdown)
"""

import json
import logging
import os
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Optional

import mlflow
import mlflow.sklearn
from fastapi import FastAPI

from .metrics import model_loaded

logger = logging.getLogger("iris_api")


def _configure_mlflow_tracking() -> tuple[str, Optional[str]]:
    """Configure MLflow tracking et retourne:

    - tracking_uri: URI du tracking backend (ou chaîne vide si non utilisée)
    - artifact_base_uri: base URI pour les artefacts (ex: gs://bucket/mlruns) si applicable

    Cas gérés:
    - MLFLOW_TRACKING_URI commence par 'gs://': utilisé comme base GCS pour les artefacts,
      sans être configuré comme tracking URI (MLflow ne supporte pas gs:// pour le registry).
    - MLFLOW_TRACKING_URI est une URI supportée (file://, http(s)://, postgres://, ...):
      configurée comme tracking URI classique.
    - MLFLOW_TRACKING_URI non défini: tracking local file://mlruns.
    """
    raw_uri = os.getenv("MLFLOW_TRACKING_URI", "").strip()

    # Cas 1 : URI GCS → artifact store uniquement
    if raw_uri.startswith("gs://"):
        artifact_base_uri = raw_uri.rstrip("/")
        logger.info(f"MLflow artifact base (GCS): {artifact_base_uri}")
        # On ne configure PAS mlflow.set_tracking_uri avec gs:// (non supporté pour le registry)
        return "", artifact_base_uri

    # Cas 2 : URI explicite supportée (registry MLflow classique)
    if raw_uri:
        mlflow.set_tracking_uri(raw_uri)
        logger.info(f"MLflow Tracking URI configuré: {raw_uri}")
        return raw_uri, None

    # Cas 3 : défaut local - utiliser mlruns/ relatif (fonctionne avec/sans Docker)
    mlruns_path = Path("mlruns").absolute()
    local_uri = f"file://{mlruns_path}"
    mlflow.set_tracking_uri(local_uri)
    logger.info(f"MLflow Tracking URI (local): {local_uri}")
    return local_uri, None


def _build_model_uri(
    mlflow_run_id: str,
    mlflow_tracking_uri: str,
    metadata: dict,
    artifact_base_uri: Optional[str] = None,
) -> str:
    """Construit l'URI du modèle MLflow.

    - Si artifact_base_uri est fourni (ex: gs://bucket/mlruns), construit une URI artefact GCS.
    - Sinon, reproduit le comportement historique:
      - si tracking URI défini ou pas de chemin relatif → runs:/<run_id>/model
      - sinon, chemin de fichier local sous mlruns/.
    """
    mlflow_relative_path = metadata.get("mlflow_relative_path", "")

    # Cas 1 : on a une base d'artefacts explicite (ex: GCS)
    if artifact_base_uri:
        # Si on dispose d'un chemin relatif MLflow, on le réutilise
        if mlflow_relative_path:
            if mlflow_relative_path.startswith("mlruns/"):
                relative_path = mlflow_relative_path[7:]  # Retirer "mlruns/"
            else:
                relative_path = mlflow_relative_path
            return f"{artifact_base_uri.rstrip('/')}/{relative_path}/artifacts/model"

        # Fallback : chemin standard à partir du run_id
        return f"{artifact_base_uri.rstrip('/')}/{mlflow_run_id}/artifacts/model"

    # Cas 2 : comportement historique avec tracking URI (registry MLflow)
    if mlflow_tracking_uri or not mlflow_relative_path:
        return f"runs:/{mlflow_run_id}/model"

    # Cas 3 : en local avec chemin relatif, construire le chemin direct
    mlruns_path = Path("mlruns").absolute()

    # Extraire la partie après "mlruns/" si présent
    if mlflow_relative_path.startswith("mlruns/"):
        relative_path = mlflow_relative_path[7:]  # Retirer "mlruns/"
    else:
        relative_path = mlflow_relative_path

    model_path = mlruns_path / relative_path / "artifacts" / "model"
    return str(model_path)


def _load_metadata(model_dir: Path) -> dict:
    """Charge et valide les métadonnées du modèle."""
    metadata_path = model_dir / "metadata.json"

    if not metadata_path.exists():
        raise FileNotFoundError(f"Métadonnées non trouvées : {metadata_path}")

    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))

    if not metadata.get("mlflow_run_id"):
        raise ValueError(
            "mlflow_run_id non trouvé dans metadata.json. "
            "Le modèle doit être entraîné avec MLflow."
        )

    return metadata


def _load_metrics(model_dir: Path) -> Optional[dict]:
    """Charge les métriques du modèle si disponibles."""
    metrics_path = model_dir / "metrics.json"

    if not metrics_path.exists():
        logger.warning("Metrics not found", extra={"path": str(metrics_path)})
        return None

    metrics = json.loads(metrics_path.read_text(encoding="utf-8"))
    logger.info("Metrics loaded", extra={"path": str(metrics_path)})
    return metrics


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gestionnaire de cycle de vie de l'application.
    Charge le modèle depuis MLflow via l'URI dans metadata.json.
    Support GCS backend en production.
    """
    model_dir = Path(os.getenv("MODEL_DIR", "models"))

    # Initialiser l'état de l'application
    app.state.model = None
    app.state.metadata = None
    app.state.metrics = None

    try:
        # Charger et valider les métadonnées
        metadata = _load_metadata(model_dir)
        app.state.metadata = metadata

        # Configurer MLflow (tracking + éventuelle base d'artefacts GCS)
        mlflow_tracking_uri, artifact_base_uri = _configure_mlflow_tracking()

        # Construire l'URI du modèle
        mlflow_run_id = metadata["mlflow_run_id"]
        model_uri = _build_model_uri(
            mlflow_run_id,
            mlflow_tracking_uri,
            metadata,
            artifact_base_uri=artifact_base_uri,
        )

        logger.info(f"Loading model from: {model_uri}")

        # Charger le modèle
        app.state.model = mlflow.sklearn.load_model(model_uri)
        model_loaded.set(1)

        logger.info(
            "Model loaded successfully",
            extra={
                "run_id": mlflow_run_id,
                "tracking_uri": mlflow_tracking_uri or "local (mlruns/)",
                "model_uri": model_uri,
            },
        )

        # Charger les métriques (non bloquant)
        app.state.metrics = _load_metrics(model_dir)

    except FileNotFoundError as exc:
        model_loaded.set(0)
        logger.error(f"File not found: {exc}")
        # L'application démarre quand même mais sans modèle
    except ValueError as exc:
        model_loaded.set(0)
        logger.error(f"Invalid configuration: {exc}")
    except Exception as exc:
        model_loaded.set(0)
        logger.exception(
            "Failed to load model",
            extra={"error": str(exc), "error_type": type(exc).__name__},
        )

    yield  # l'app est maintenant prête

    # Cleanup au shutdown
    model_loaded.set(0)
