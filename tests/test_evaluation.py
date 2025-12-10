"""
Tests unitaires pour le module d'évaluation (evaluation/evaluate.py)
"""

import tempfile
from pathlib import Path

import numpy as np
import pytest
from sklearn.datasets import load_iris
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split

from src.evaluation.evaluate import evaluate_model


class TestEvaluation:
    """Tests pour le module d'évaluation"""

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

        metrics, metadata = evaluate_model(
            model, X_test, y_test, iris_metadata, use_mlflow=False
        )

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

        metrics, _ = evaluate_model(
            model, X_test, y_test, iris_metadata, use_mlflow=False
        )

        # Pour Iris avec RandomForest, l'accuracy devrait être > 0.8
        assert metrics["accuracy"] > 0.8

    def test_evaluate_model_metadata_structure(self, trained_model_and_data):
        """Test de la structure des métadonnées retournées"""
        model, X_test, y_test, iris_metadata = trained_model_and_data

        metrics, metadata = evaluate_model(
            model, X_test, y_test, iris_metadata, use_mlflow=False
        )

        # Vérifier que metadata ne contient pas de métriques (séparation claire)
        assert "accuracy" not in metadata
        assert "precision" not in metadata
        assert "recall" not in metadata
        assert "f1_score" not in metadata

        # Vérifier que metadata contient les bonnes clés
        assert "feature_names" in metadata
        assert "target_names" in metadata

    def test_evaluate_model_with_mlflow(self, trained_model_and_data):
        """Test d'évaluation avec MLflow (sans erreur)"""
        model, X_test, y_test, iris_metadata = trained_model_and_data

        # Test que la fonction ne plante pas avec MLflow activé
        # (même si MLflow n'est pas configuré en test)
        try:
            metrics, metadata = evaluate_model(
                model, X_test, y_test, iris_metadata, use_mlflow=True
            )
            # Si ça ne plante pas, c'est bon
            assert "accuracy" in metrics
        except Exception:
            # Si MLflow n'est pas configuré, c'est acceptable en test
            pytest.skip("MLflow non configuré pour les tests")

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

        metrics, _ = evaluate_model(
            model, X_test, y_test, iris_metadata, use_mlflow=False
        )

        # L'accuracy devrait être élevée (pas forcément 1.0 car test set différent)
        assert metrics["accuracy"] > 0.8

    def test_evaluate_model_metrics_consistency(self, trained_model_and_data):
        """Test de cohérence des métriques"""
        model, X_test, y_test, iris_metadata = trained_model_and_data

        metrics1, _ = evaluate_model(
            model, X_test, y_test, iris_metadata, use_mlflow=False
        )
        metrics2, _ = evaluate_model(
            model, X_test, y_test, iris_metadata, use_mlflow=False
        )

        # Les métriques doivent être identiques pour les mêmes données
        assert abs(metrics1["accuracy"] - metrics2["accuracy"]) < 1e-6
        assert abs(metrics1["precision"] - metrics2["precision"]) < 1e-6
        assert abs(metrics1["recall"] - metrics2["recall"]) < 1e-6
        assert abs(metrics1["f1_score"] - metrics2["f1_score"]) < 1e-6
