"""
Module d'entraînement du modèle ML
Modèle de classification sur le dataset Iris
Intégration MLflow pour le tracking des expériences (Semaine 4)
Lit les paramètres depuis params.yaml avec validation Pydantic
"""

import json
import logging
from pathlib import Path
from typing import Optional, Tuple

import joblib
import mlflow
import mlflow.sklearn
import pandas as pd
from sklearn.datasets import load_iris
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split

from src.config import get_config
from src.evaluation.evaluate import evaluate_model

# Configuration du logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def load_data(
    test_size: float, random_state: int
) -> Tuple[pd.DataFrame, pd.DataFrame, dict]:
    """
    Charge les données depuis CSV (DVC pipeline) ou scikit-learn
    
    Returns:
        Tuple[train_df, test_df, iris_metadata]
    """
    train_path = Path("data/processed/train.csv")
    test_path = Path("data/processed/test.csv")
    
    if train_path.exists() and test_path.exists():
        logger.info("   📂 Chargement depuis les fichiers CSV (DVC pipeline)...")
        train_df = pd.read_csv(train_path)
        test_df = pd.read_csv(test_path)
        iris = load_iris()  # Pour les métadonnées
        return train_df, test_df, {
            "feature_names": iris.feature_names.tolist(),
            "target_names": iris.target_names.tolist(),
        }
    else:
        logger.info("   📦 Chargement depuis scikit-learn...")
        iris = load_iris()
        df = pd.DataFrame(iris.data, columns=iris.feature_names)
        df["target"] = iris.target
        
        train_df, test_df = train_test_split(
            df, test_size=test_size, random_state=random_state, stratify=df["target"]
        )
        
        return train_df, test_df, {
            "feature_names": iris.feature_names.tolist(),
            "target_names": iris.target_names.tolist(),
        }


def train_model(
    n_estimators: Optional[int] = None,
    max_depth: Optional[int] = None,
    random_state: Optional[int] = None,
    test_size: Optional[float] = None,
    use_mlflow: bool = True,
) -> Tuple[RandomForestClassifier, dict]:
    """
    Entraîne un modèle RandomForest sur le dataset Iris avec tracking MLflow
    Les paramètres sont lus depuis params.yaml avec validation Pydantic si non fournis

    Args:
        n_estimators: Nombre d'arbres dans la forêt (surcharge params.yaml si fourni)
        max_depth: Profondeur maximale des arbres (surcharge params.yaml si fourni)
        random_state: Graine aléatoire pour la reproductibilité (surcharge params.yaml si fourni)
        test_size: Proportion du dataset pour le test (surcharge params.yaml si fourni)
        use_mlflow: Activer le tracking MLflow

    Returns:
        Tuple[RandomForestClassifier, dict]: Modèle entraîné et métadonnées
    """
    config = get_config()
    n_estimators = n_estimators if n_estimators is not None else config.train.n_estimators
    max_depth = max_depth if max_depth is not None else config.train.max_depth
    random_state = random_state if random_state is not None else config.train.random_state
    test_size = test_size if test_size is not None else config.train.test_size

    # Configuration MLflow
    if use_mlflow:
        mlflow.set_experiment("iris-classification")
        mlflow.start_run()

    logger.info("🌱 Chargement du dataset Iris...")
    train_df, test_df, iris_metadata = load_data(test_size, random_state)
    
    # Séparer features et target
    feature_cols = ["sepal length (cm)", "sepal width (cm)", 
                   "petal length (cm)", "petal width (cm)"]
    X_train = train_df[feature_cols].values
    y_train = train_df["target"].values
    X_test = test_df[feature_cols].values
    y_test = test_df["target"].values

    # Hyperparamètres
    hyperparams = {
        "n_estimators": n_estimators,
        "max_depth": max_depth if max_depth else "None",
        "random_state": random_state,
        "test_size": test_size,
    }

    # Calculer les dimensions (pour MLflow et métadonnées)
    n_features = X_train.shape[1]
    n_samples = len(X_train) + len(X_test)

    # Logger les hyperparamètres dans MLflow
    if use_mlflow:
        mlflow.log_params(hyperparams)
        mlflow.log_param("algorithm", "RandomForestClassifier")
        mlflow.log_param("dataset", "Iris")
        mlflow.log_param("n_features", n_features)
        mlflow.log_param("n_samples", n_samples)
        mlflow.log_param("n_classes", len(iris_metadata["target_names"]))

    logger.info("🤖 Entraînement du modèle RandomForest...")
    logger.info(f"   Hyperparamètres: {hyperparams}")
    model = RandomForestClassifier(
        n_estimators=n_estimators, max_depth=max_depth, random_state=random_state
    )
    model.fit(X_train, y_train)

    # Évaluation
    metrics, metadata = evaluate_model(
        model, X_test, y_test, iris_metadata, use_mlflow=use_mlflow
    )

    # Sauvegarde du modèle (méthode classique)
    models_dir = Path("models")
    models_dir.mkdir(exist_ok=True)
    model_path = models_dir / "iris_model.pkl"
    joblib.dump(model, model_path)
    logger.info(f"💾 Modèle sauvegardé dans : {model_path}")

    # Sauvegarde via MLflow
    if use_mlflow:
        mlflow.sklearn.log_model(
            model, "model", registered_model_name="IrisClassifier"
        )
        logger.info("📊 Modèle enregistré dans MLflow")

    # Sauvegarde des métadonnées
    metadata.update({
        "model_type": "RandomForestClassifier",
        "n_estimators": n_estimators,
        "max_depth": max_depth,
        "random_state": random_state,
        "n_features": n_features,
        "n_samples": n_samples,
    })

    metadata_path = models_dir / "model_metadata.json"
    with open(metadata_path, "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2)

    # Logger les métadonnées dans MLflow
    if use_mlflow:
        mlflow.log_dict(metadata, "model_metadata.json")
        mlflow.end_run()
        logger.info(f"🔗 MLflow UI: mlflow ui (http://localhost:5000)")

    logger.info("✅ Entraînement terminé avec succès !")
    return model, metadata


if __name__ == "__main__":
    # Les paramètres seront automatiquement lus depuis params.yaml avec validation
    train_model()

