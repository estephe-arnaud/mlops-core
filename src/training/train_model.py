"""
Script d'entraînement du modèle ML pour la semaine 1 MLOps
Modèle de classification sur le dataset Iris
"""

import os

import joblib
import pandas as pd
from sklearn.datasets import load_iris
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report
from sklearn.model_selection import train_test_split


def train_iris_model():
    """
    Entraîne un modèle RandomForest sur le dataset Iris
    """
    print("🌱 Chargement du dataset Iris...")
    iris = load_iris()
    X = iris.data
    y = iris.target

    # Division train/test
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    print("🤖 Entraînement du modèle RandomForest...")
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)

    # Évaluation
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)

    print(f"📊 Précision du modèle : {accuracy:.3f}")
    print("\n📋 Rapport de classification :")
    print(classification_report(y_test, y_pred, target_names=iris.target_names))

    # Sauvegarde du modèle
    os.makedirs("models", exist_ok=True)
    model_path = "models/iris_model.pkl"
    joblib.dump(model, model_path)
    print(f"💾 Modèle sauvegardé dans : {model_path}")

    # Sauvegarde des métadonnées
    metadata = {
        "model_type": "RandomForestClassifier",
        "n_estimators": 100,
        "accuracy": float(accuracy),
        "feature_names": iris.feature_names,
        "target_names": iris.target_names.tolist(),
        "n_features": X.shape[1],
        "n_samples": X.shape[0],
    }

    import json

    with open("models/model_metadata.json", "w") as f:
        json.dump(metadata, f, indent=2)

    print("✅ Entraînement terminé avec succès !")
    return model, metadata


if __name__ == "__main__":
    train_iris_model()
