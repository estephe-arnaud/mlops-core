"""
Module de configuration centralisé avec validation Pydantic
Lit et valide les paramètres depuis params.yaml
Approche recommandée en production MLOps
"""

import logging
from pathlib import Path
from typing import Optional

import yaml
from pydantic import BaseModel, Field, ValidationError

logger = logging.getLogger(__name__)


class BaseConfig(BaseModel):
    """Configuration de base avec paramètres communs"""

    test_size: float = Field(
        default=0.2, 
        gt=0.0, 
        lt=1.0, 
        description="Proportion du dataset pour le test"
    )
    random_state: int = Field(
        default=42, 
        ge=0, 
        description="Graine aléatoire pour la reproductibilité"
    )


class DataConfig(BaseConfig):
    """Configuration pour la préparation des données"""

    pass


class TrainConfig(BaseConfig):
    """Configuration pour l'entraînement du modèle"""

    n_estimators: int = Field(default=100, gt=0, description="Nombre d'arbres dans la forêt")
    max_depth: Optional[int] = Field(
        default=None,
        description="Profondeur maximale des arbres (None = illimitée)"
    )


class Config(BaseModel):
    """Configuration complète du pipeline"""

    data: DataConfig = Field(default_factory=DataConfig)
    train: TrainConfig = Field(default_factory=TrainConfig)


def load_config(config_path: Optional[str] = None) -> Config:
    """
    Charge et valide la configuration depuis params.yaml

    Args:
        config_path: Chemin vers le fichier de configuration (défaut: params.yaml à la racine)

    Returns:
        Config: Configuration validée

    Raises:
        FileNotFoundError: Si le fichier de configuration n'existe pas
        yaml.YAMLError: Si le fichier YAML est invalide
        ValidationError: Si la validation Pydantic échoue
    """
    if config_path is None:
        # Chercher params.yaml à la racine du projet
        project_root = Path(__file__).parent.parent
        config_path = project_root / "params.yaml"

    config_path = Path(config_path)

    if not config_path.exists():
        logger.warning(
            f"⚠️  Fichier de configuration non trouvé: {config_path}. "
            "Utilisation des valeurs par défaut."
        )
        return Config()

    try:
        with open(config_path, "r", encoding="utf-8") as f:
            raw_config = yaml.safe_load(f) or {}

        logger.info(f"📋 Configuration chargée depuis: {config_path}")

        # Construire la configuration avec validation Pydantic
        config = Config(**raw_config)
        logger.debug(f"Configuration chargée: {config.model_dump()}")

        return config

    except yaml.YAMLError as e:
        logger.error(f"Erreur de parsing YAML: {e}")
        raise
    except Exception as e:
        logger.warning(f"Erreur de validation, utilisation des valeurs par défaut: {e}")
        return Config()


# Instance globale de configuration (chargée au premier import)
_config: Optional[Config] = None


def get_config(reload: bool = False) -> Config:
    """
    Récupère la configuration (singleton pattern)

    Args:
        reload: Forcer le rechargement de la configuration

    Returns:
        Config: Configuration validée
    """
    global _config
    if _config is None or reload:
        _config = load_config()
    return _config

