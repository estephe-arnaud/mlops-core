"""Métriques Prometheus pour l'API"""

from fastapi import Response
from prometheus_client import Counter, Gauge, Histogram, generate_latest

model_predictions = Counter(
    "model_predictions_total", "Total predictions", ["predicted_class"]
)
model_confidence = Histogram(
    "model_confidence",
    "Prediction confidence",
    ["predicted_class"],
    buckets=[0.0, 0.5, 0.7, 0.8, 0.9, 0.95, 1.0],
)
model_loaded = Gauge("model_loaded", "Model loaded (1) or not (0)")
api_errors = Counter("api_errors_total", "Total errors", ["error_type", "endpoint"])


def get_metrics_response() -> Response:
    return Response(content=generate_latest(), media_type="text/plain")
