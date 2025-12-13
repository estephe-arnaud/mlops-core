"""
Tests unitaires pour le module de métriques Prometheus (metrics.py)
"""

import pytest
from fastapi import Response
from prometheus_client import generate_latest

from src.serving.metrics import (
    api_errors,
    get_metrics_response,
    model_confidence,
    model_loaded,
    model_predictions,
)


class TestMetrics:
    """Tests pour le module de métriques"""

    def test_get_metrics_response_type(self):
        """Test que get_metrics_response retourne une Response"""
        response = get_metrics_response()
        assert isinstance(response, Response)
        assert response.media_type == "text/plain"

    def test_get_metrics_response_content(self):
        """Test que get_metrics_response retourne du contenu Prometheus valide"""
        response = get_metrics_response()
        content = response.body.decode("utf-8")
        # Vérifier que c'est du format Prometheus
        assert "# HELP" in content or "# TYPE" in content
        # Vérifier la présence de métriques
        assert "model_loaded" in content

    def test_metrics_initialization(self):
        """Test que les métriques sont correctement initialisées"""
        # Vérifier que les métriques existent
        assert model_predictions is not None
        assert model_confidence is not None
        assert model_loaded is not None
        assert api_errors is not None

    def test_model_loaded_gauge(self):
        """Test de la métrique model_loaded"""
        # Tester la valeur initiale
        initial_value = model_loaded._value.get()
        assert initial_value in [0, 1]

        # Modifier la valeur
        model_loaded.set(1)
        assert model_loaded._value.get() == 1

        # Remettre à zéro
        model_loaded.set(0)
        assert model_loaded._value.get() == 0

    def test_model_predictions_counter(self):
        """Test du compteur model_predictions"""
        # Incrémenter le compteur
        model_predictions.labels(predicted_class="setosa").inc()
        model_predictions.labels(predicted_class="versicolor").inc()

        # Vérifier que les métriques sont enregistrées
        content = generate_latest().decode("utf-8")
        assert "model_predictions_total" in content

    def test_api_errors_counter(self):
        """Test du compteur api_errors"""
        # Incrémenter le compteur
        api_errors.labels(error_type="ValueError", endpoint="/predict").inc()

        # Vérifier que les métriques sont enregistrées
        content = generate_latest().decode("utf-8")
        assert "api_errors_total" in content
