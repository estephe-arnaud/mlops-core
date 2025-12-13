"""
Tests unitaires pour le module d'évaluation (evaluation/evaluate.py)
"""

import os
import tempfile
from pathlib import Path

import mlflow
import numpy as np
import pytest
from sklearn.datasets import load_iris
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split

from src.evaluation.evaluate import evaluate_model


class TestEvaluation:
    """Tests pour le module d'évaluation"""

    @pytest.fixture(autouse=True)
    def setup_mlflow(self):
        """Fixture pour configurer MLflow pour tous les tests"""
        temp_dir = tempfile.mkdtemp()
        mlflow.set_tracking_uri(f"file://{temp_dir}/mlruns")
        # Créer un experiment par défaut pour que mlflow.start_run() fonctionne
        mlflow.set_experiment("test-experiment")
        yield
        # Nettoyage après les tests

    @pytest.fixture
    def trained_model_and_data(self):
        """Fixture pour un modèle entraîné et des données de test"""
        iris = load_iris()
        X_train, X_test, y_train, y_test = train_test_split(
            iris.data, iris.target, test_size=0.2, random_state=42, stratify=iris.target
        )

        model = RandomForestClassifier(n_estimators=100, random_state=42)
        model.fit(X_train, y_train)

        iris_metadata = {
            "feature_names": list(iris.feature_names),
            "target_names": list(iris.target_names),
        }

        return model, X_test, y_test, iris_metadata

    def test_evaluate_model_basic(self, trained_model_and_data):
        """Test d'évaluation basique du modèle"""
        model, X_test, y_test, iris_metadata = trained_model_and_data

        with mlflow.start_run():
            metrics, metadata = evaluate_model(model, X_test, y_test, iris_metadata)

        # Vérifier les métriques
        assert "accuracy" in metrics
        assert "precision" in metrics
        assert "recall" in metrics
        assert "f1_score" in metrics

        # Vérifier les types
        assert isinstance(metrics["accuracy"], float)
        assert isinstance(metrics["precision"], float)
        assert isinstance(metrics["recall"], float)
        assert isinstance(metrics["f1_score"], float)

        # Vérifier les valeurs (doivent être entre 0 et 1)
        assert 0 <= metrics["accuracy"] <= 1
        assert 0 <= metrics["precision"] <= 1
        assert 0 <= metrics["recall"] <= 1
        assert 0 <= metrics["f1_score"] <= 1

        # Vérifier les métadonnées
        assert "feature_names" in metadata
        assert "target_names" in metadata
        assert len(metadata["feature_names"]) == 4
        assert len(metadata["target_names"]) == 3

    def test_evaluate_model_accuracy_range(self, trained_model_and_data):
        """Test que l'accuracy est dans une plage raisonnable"""
        model, X_test, y_test, iris_metadata = trained_model_and_data

        with mlflow.start_run():
            metrics, _ = evaluate_model(model, X_test, y_test, iris_metadata)

        # Pour Iris avec RandomForest, l'accuracy devrait être > 0.8
        assert metrics["accuracy"] > 0.8

    def test_evaluate_model_metadata_structure(self, trained_model_and_data):
        """Test de la structure des métadonnées retournées"""
        model, X_test, y_test, iris_metadata = trained_model_and_data

        with mlflow.start_run():
            metrics, metadata = evaluate_model(model, X_test, y_test, iris_metadata)

        # Vérifier que metadata ne contient pas de métriques (séparation claire)
        assert "accuracy" not in metadata
        assert "precision" not in metadata
        assert "recall" not in metadata
        assert "f1_score" not in metadata

        # Vérifier que metadata contient les bonnes clés
        assert "feature_names" in metadata
        assert "target_names" in metadata

    def test_evaluate_model_with_mlflow(self, trained_model_and_data):
        """Test d'évaluation avec MLflow (toujours activé maintenant)"""
        model, X_test, y_test, iris_metadata = trained_model_and_data

        with mlflow.start_run():
            metrics, metadata = evaluate_model(model, X_test, y_test, iris_metadata)
        # Vérifier que les métriques sont loggées
        assert "accuracy" in metrics

    def test_evaluate_model_perfect_predictions(self):
        """Test avec des prédictions parfaites (accuracy = 1.0)"""
        iris = load_iris()
        X_train, X_test, y_train, y_test = train_test_split(
            iris.data, iris.target, test_size=0.2, random_state=42, stratify=iris.target
        )

        # Créer un modèle qui prédit parfaitement (sur les données d'entraînement)
        model = RandomForestClassifier(n_estimators=1000, random_state=42)
        model.fit(X_train, y_train)

        iris_metadata = {
            "feature_names": list(iris.feature_names),
            "target_names": list(iris.target_names),
        }

        with mlflow.start_run():
            metrics, _ = evaluate_model(model, X_test, y_test, iris_metadata)

        # L'accuracy devrait être élevée (pas forcément 1.0 car test set différent)
        assert metrics["accuracy"] > 0.8

    def test_evaluate_model_metrics_consistency(self, trained_model_and_data):
        """Test de cohérence des métriques"""
        model, X_test, y_test, iris_metadata = trained_model_and_data

        with mlflow.start_run():
            metrics1, _ = evaluate_model(model, X_test, y_test, iris_metadata)
        with mlflow.start_run():
            metrics2, _ = evaluate_model(model, X_test, y_test, iris_metadata)

        # Les métriques doivent être identiques pour les mêmes données
        assert abs(metrics1["accuracy"] - metrics2["accuracy"]) < 1e-6
        assert abs(metrics1["precision"] - metrics2["precision"]) < 1e-6
        assert abs(metrics1["recall"] - metrics2["recall"]) < 1e-6
        assert abs(metrics1["f1_score"] - metrics2["f1_score"]) < 1e-6
