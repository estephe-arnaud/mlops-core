"""
Tests unitaires pour le modèle ML
Semaine 1 - MLOps Formation
"""

import json
import os

import joblib
import numpy as np
import pytest
from sklearn.datasets import load_iris

from src.training.train import train_model as train_iris_model


class TestModel:
    """Tests pour le modèle ML"""

    def test_model_training(self):
        """Test de l'entraînement du modèle"""
        # Entraînement du modèle
        model, metadata = train_iris_model()

        # Vérifications
        assert model is not None
        assert metadata is not None
        assert "accuracy" in metadata
        assert metadata["accuracy"] > 0.8  # Le modèle devrait avoir une bonne précision
        assert metadata["model_type"] == "RandomForestClassifier"
        assert len(metadata["feature_names"]) == 4
        assert len(metadata["target_names"]) == 3

    def test_model_save_load(self):
        """Test de sauvegarde et chargement du modèle"""
        # Entraînement et sauvegarde
        model, metadata = train_iris_model()

        # Vérification que les fichiers existent
        assert os.path.exists("models/iris_model.pkl")
        assert os.path.exists("models/model_metadata.json")

        # Chargement du modèle
        loaded_model = joblib.load("models/iris_model.pkl")
        assert loaded_model is not None

        # Chargement des métadonnées
        with open("models/model_metadata.json", "r") as f:
            loaded_metadata = json.load(f)

        assert loaded_metadata["model_type"] == metadata["model_type"]
        assert loaded_metadata["accuracy"] == metadata["accuracy"]

    def test_model_prediction(self):
        """Test des prédictions du modèle"""
        # Chargement du dataset
        iris = load_iris()
        X = iris.data
        y = iris.target

        # Entraînement du modèle
        model, metadata = train_iris_model()

        # Test sur quelques échantillons
        test_samples = X[:5]
        predictions = model.predict(test_samples)
        probabilities = model.predict_proba(test_samples)

        # Vérifications
        assert len(predictions) == 5
        assert predictions.shape[0] == test_samples.shape[0]
        assert probabilities.shape[0] == test_samples.shape[0]
        assert probabilities.shape[1] == 3  # 3 classes

        # Vérification que les probabilités somment à 1
        for prob_row in probabilities:
            assert abs(np.sum(prob_row) - 1.0) < 1e-6

    def test_model_accuracy(self):
        """Test de la précision du modèle"""
        from sklearn.metrics import accuracy_score
        from sklearn.model_selection import train_test_split

        # Chargement du dataset
        iris = load_iris()
        X = iris.data
        y = iris.target

        # Division train/test
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42, stratify=y
        )

        # Entraînement
        model, metadata = train_iris_model()

        # Prédiction sur le test set
        y_pred = model.predict(X_test)
        accuracy = accuracy_score(y_test, y_pred)

        # Vérification que la précision est raisonnable
        assert accuracy > 0.8
        assert metadata["accuracy"] == accuracy

    def test_model_feature_importance(self):
        """Test de l'importance des features"""
        model, metadata = train_iris_model()

        # Vérification que le modèle a des feature importances
        assert hasattr(model, "feature_importances_")
        assert len(model.feature_importances_) == 4  # 4 features

        # Vérification que les importances sont positives et somment à 1
        importances = model.feature_importances_
        assert all(imp >= 0 for imp in importances)
        assert abs(np.sum(importances) - 1.0) < 1e-6

    def test_model_metadata_structure(self):
        """Test de la structure des métadonnées"""
        model, metadata = train_iris_model()

        # Vérification des clés requises
        required_keys = [
            "model_type",
            "n_estimators",
            "accuracy",
            "feature_names",
            "target_names",
            "n_features",
            "n_samples",
        ]

        for key in required_keys:
            assert key in metadata, f"Clé manquante : {key}"

        # Vérification des types
        assert isinstance(metadata["model_type"], str)
        assert isinstance(metadata["accuracy"], float)
        assert isinstance(metadata["n_features"], int)
        assert isinstance(metadata["n_samples"], int)
        assert isinstance(metadata["feature_names"], list)
        assert isinstance(metadata["target_names"], list)

        # Vérification des valeurs
        assert metadata["accuracy"] > 0
        assert metadata["n_features"] == 4
        assert metadata["n_samples"] == 150
        assert len(metadata["feature_names"]) == 4
        assert len(metadata["target_names"]) == 3
