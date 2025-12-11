"""
Modèles Pydantic pour l'API
"""

from typing import Dict

from pydantic import BaseModel, ConfigDict, Field, field_validator


class IrisFeatures(BaseModel):
    """Modèle Pydantic pour les features Iris avec validation de plage"""

    sepal_length: float = Field(
        ..., ge=0.0, le=20.0, description="Longueur du sépale (0-20 cm)"
    )
    sepal_width: float = Field(
        ..., ge=0.0, le=20.0, description="Largeur du sépale (0-20 cm)"
    )
    petal_length: float = Field(
        ..., ge=0.0, le=20.0, description="Longueur du pétale (0-20 cm)"
    )
    petal_width: float = Field(
        ..., ge=0.0, le=20.0, description="Largeur du pétale (0-20 cm)"
    )

    @field_validator("sepal_length", "sepal_width", "petal_length", "petal_width")
    @classmethod
    def validate_not_nan_or_inf(cls, v: float) -> float:
        """Valide que la valeur n'est pas NaN ou infinie"""
        if not isinstance(v, (int, float)) or not (v == v):  # NaN check
            raise ValueError("La valeur ne peut pas être NaN")
        if abs(v) == float("inf"):
            raise ValueError("La valeur ne peut pas être infinie")
        return float(v)

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "sepal_length": 5.1,
                "sepal_width": 3.5,
                "petal_length": 1.4,
                "petal_width": 0.2,
            }
        }
    )


class PredictionResponse(BaseModel):
    prediction: str
    confidence: float
    probabilities: Dict[str, float]


class HealthResponse(BaseModel):
    status: str
    model_loaded: bool
    version: str

