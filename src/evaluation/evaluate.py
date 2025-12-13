"""
Module d'évaluation des modèles ML
Calcule les métriques et les log dans MLflow
"""

import logging
import tempfile
from pathlib import Path
from typing import Any, Dict, Tuple

import mlflow
import numpy as np
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
)

logger = logging.getLogger(__name__)


def evaluate_model(
    model: Any, X_test: Any, y_test: Any, iris_metadata: Dict
) -> Tuple[Dict, Dict]:
    """
    Évalue un modèle et retourne les métriques et métadonnées
    Les métriques sont automatiquement loggées dans MLflow

    Args:
        model: Modèle entraîné
        X_test: Features de test
        y_test: Labels de test
        iris_metadata: Métadonnées du dataset (feature_names, target_names)

    Returns:
        Tuple[Dict, Dict]: (métriques, métadonnées)
    """
    # Prédictions
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)

    # Métriques détaillées
    precision = precision_score(y_test, y_pred, average="weighted")
    recall = recall_score(y_test, y_pred, average="weighted")
    f1 = f1_score(y_test, y_pred, average="weighted")

    # Métriques par classe
    precision_per_class = precision_score(y_test, y_pred, average=None)
    recall_per_class = recall_score(y_test, y_pred, average=None)
    f1_per_class = f1_score(y_test, y_pred, average=None)

    logger.info(f"📊 Précision du modèle : {accuracy:.3f}")
    logger.info(f"   Precision (weighted): {precision:.3f}")
    logger.info(f"   Recall (weighted): {recall:.3f}")
    logger.info(f"   F1-Score (weighted): {f1:.3f}")
    logger.info("\n📋 Rapport de classification :")
    logger.info(
        classification_report(
            y_test, y_pred, target_names=iris_metadata["target_names"]
        )
    )

    # Logger les métriques dans MLflow
    # Métriques globales
    mlflow.log_metric("accuracy", accuracy)
    mlflow.log_metric("precision_weighted", precision)
    mlflow.log_metric("recall_weighted", recall)
    mlflow.log_metric("f1_score_weighted", f1)

    # Métriques par classe
    for i, class_name in enumerate(iris_metadata["target_names"]):
        mlflow.log_metric(f"precision_{class_name}", precision_per_class[i])
        mlflow.log_metric(f"recall_{class_name}", recall_per_class[i])
        mlflow.log_metric(f"f1_score_{class_name}", f1_per_class[i])

    # Confusion matrix
    cm = confusion_matrix(y_test, y_pred)
    # Créer un fichier temporaire pour la confusion matrix
    tmp_file_path = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".txt", delete=False
        ) as tmp_file:
            tmp_file_path = tmp_file.name
            np.savetxt(tmp_file_path, cm, fmt="%d")
        mlflow.log_artifact(tmp_file_path, "confusion_matrix")
    finally:
        # Nettoyer le fichier temporaire même en cas d'erreur
        if tmp_file_path and Path(tmp_file_path).exists():
            Path(tmp_file_path).unlink()

    # Métriques de performance (pour DVC tracking)
    metrics = {
        "accuracy": float(accuracy),
        "precision": float(precision),
        "recall": float(recall),
        "f1_score": float(f1),
    }

    # Métadonnées du dataset (sans métriques pour éviter redondance)
    metadata = {
        "feature_names": iris_metadata["feature_names"],
        "target_names": iris_metadata["target_names"],
    }

    return metrics, metadata
