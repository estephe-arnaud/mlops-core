"""
Tests unitaires pour l'API FastAPI
Semaine 1 - MLOps Formation
"""

import json

import pytest
from fastapi.testclient import TestClient

from src.serving.app import app

# Client de test
client = TestClient(app)


class TestAPI:
    """Tests pour l'API FastAPI"""

    def test_root_endpoint(self):
        """Test de l'endpoint racine"""
        response = client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        assert "API Classification Iris" in data["message"]

    def test_health_check(self):
        """Test de l'endpoint de santé"""
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert "status" in data
        assert "model_loaded" in data
        assert "version" in data
        assert data["version"] == "1.0.0"

    def test_model_info(self):
        """Test de l'endpoint d'informations du modèle"""
        response = client.get("/model/info")
        # Peut retourner 404 si le modèle n'est pas chargé
        if response.status_code == 200:
            data = response.json()
            assert "model_type" in data
            assert "accuracy" in data
            assert "feature_names" in data
            assert "target_names" in data

    def test_predict_valid_data(self):
        """Test de prédiction avec des données valides"""
        test_data = {
            "sepal_length": 5.1,
            "sepal_width": 3.5,
            "petal_length": 1.4,
            "petal_width": 0.2,
        }

        response = client.post("/predict", json=test_data)

        # Si le modèle est chargé, on s'attend à un succès
        if response.status_code == 200:
            data = response.json()
            assert "prediction" in data
            assert "confidence" in data
            assert "probabilities" in data
            assert isinstance(data["confidence"], float)
            assert 0 <= data["confidence"] <= 1
        else:
            # Si le modèle n'est pas chargé, on s'attend à une erreur 503
            assert response.status_code == 503

    def test_predict_invalid_data(self):
        """Test de prédiction avec des données invalides"""
        # Test avec des valeurs manquantes
        invalid_data = {
            "sepal_length": 5.1,
            "sepal_width": 3.5
            # petal_length et petal_width manquants
        }

        response = client.post("/predict", json=invalid_data)
        assert response.status_code == 422  # Validation error

    def test_predict_negative_values(self):
        """Test avec des valeurs négatives (devrait être rejeté par la validation Pydantic)"""
        test_data = {
            "sepal_length": -1.0,
            "sepal_width": 3.5,
            "petal_length": 1.4,
            "petal_width": 0.2,
        }

        response = client.post("/predict", json=test_data)
        # L'API devrait rejeter les valeurs négatives (validation Pydantic avec ge=0.0)
        assert response.status_code == 422  # Validation error

    def test_predict_string_values(self):
        """Test avec des valeurs string (devrait échouer)"""
        test_data = {
            "sepal_length": "invalid",
            "sepal_width": 3.5,
            "petal_length": 1.4,
            "petal_width": 0.2,
        }

        response = client.post("/predict", json=test_data)
        assert response.status_code == 422  # Validation error

    def test_predict_iris_setosa(self):
        """Test avec des caractéristiques typiques d'Iris setosa"""
        setosa_data = {
            "sepal_length": 5.1,
            "sepal_width": 3.5,
            "petal_length": 1.4,
            "petal_width": 0.2,
        }

        response = client.post("/predict", json=setosa_data)
        if response.status_code == 200:
            data = response.json()
            # Iris setosa devrait être prédite avec une bonne confiance
            assert data["prediction"] in ["setosa", "versicolor", "virginica"]
            assert data["confidence"] > 0.5

    def test_predict_iris_versicolor(self):
        """Test avec des caractéristiques typiques d'Iris versicolor"""
        versicolor_data = {
            "sepal_length": 7.0,
            "sepal_width": 3.2,
            "petal_length": 4.7,
            "petal_width": 1.4,
        }

        response = client.post("/predict", json=versicolor_data)
        if response.status_code == 200:
            data = response.json()
            assert data["prediction"] in ["setosa", "versicolor", "virginica"]
            assert data["confidence"] > 0.5

    def test_predict_iris_virginica(self):
        """Test avec des caractéristiques typiques d'Iris virginica"""
        virginica_data = {
            "sepal_length": 6.3,
            "sepal_width": 3.3,
            "petal_length": 6.0,
            "petal_width": 2.5,
        }

        response = client.post("/predict", json=virginica_data)
        if response.status_code == 200:
            data = response.json()
            assert data["prediction"] in ["setosa", "versicolor", "virginica"]
            assert data["confidence"] > 0.5
