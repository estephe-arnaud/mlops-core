"""
Configuration partagée pour les tests pytest
Fixtures et utilitaires communs
"""

import os
import tempfile
from pathlib import Path

import mlflow
import pytest
from fastapi.testclient import TestClient
from sklearn.datasets import load_iris

from src.serving.app import app
from src.training.train import train_model


@pytest.fixture(scope="session")
def trained_model():
    """
    Fixture pour un modèle entraîné (session scope pour éviter de réentraîner)
    """
    # Créer un répertoire temporaire pour les modèles et MLflow
    temp_dir = tempfile.mkdtemp()
    original_dir = os.getcwd()

    try:
        os.chdir(temp_dir)
        os.makedirs("models", exist_ok=True)

        # Configurer MLflow pour utiliser un répertoire temporaire
        mlflow.set_tracking_uri(f"file://{temp_dir}/mlruns")

        # Entraîner le modèle avec MLflow (toujours activé maintenant)
        model, metadata = train_model(experiment_name="test-experiment")

        yield model, metadata

    finally:
        os.chdir(original_dir)


@pytest.fixture(scope="function")
def api_client():
    """
    Fixture pour un client API de test
    """
    return TestClient(app)


@pytest.fixture(scope="function")
def api_client_with_model(trained_model):
    """
    Fixture pour un client API avec modèle chargé
    """
    model, metadata = trained_model

    # Charger le modèle dans app.state
    app.state.model = model
    app.state.metadata = metadata

    # Charger les métriques depuis le fichier si disponible
    metrics_path = Path("models/metrics.json")
    if metrics_path.exists():
        import json

        with open(metrics_path, "r") as f:
            app.state.metrics = json.load(f)
    else:
        app.state.metrics = None

    client = TestClient(app)

    yield client

    # Nettoyage
    app.state.model = None
    app.state.metadata = None
    app.state.metrics = None


@pytest.fixture
def valid_iris_data():
    """Données Iris valides pour les tests"""
    return {
        "sepal_length": 5.1,
        "sepal_width": 3.5,
        "petal_length": 1.4,
        "petal_width": 0.2,
    }


@pytest.fixture
def api_key(monkeypatch):
    """Fixture pour configurer une API key de test"""
    test_key = "test-api-key-12345"
    monkeypatch.setenv("API_KEY", test_key)
    monkeypatch.setenv("ENVIRONMENT", "development")
    return test_key


@pytest.fixture
def api_key_production(monkeypatch):
    """Fixture pour configurer une API key en mode production"""
    test_key = "production-api-key-12345"
    monkeypatch.setenv("API_KEY", test_key)
    monkeypatch.setenv("ENVIRONMENT", "production")
    return test_key


@pytest.fixture
def no_api_key(monkeypatch):
    """Fixture pour désactiver l'API key (mode développement)"""
    monkeypatch.delenv("API_KEY", raising=False)
    monkeypatch.setenv("ENVIRONMENT", "development")


@pytest.fixture
def iris_dataset():
    """Fixture pour le dataset Iris"""
    iris = load_iris()
    return iris.data, iris.target, iris.feature_names, iris.target_names
