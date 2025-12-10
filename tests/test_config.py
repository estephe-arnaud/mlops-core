"""
Tests unitaires pour le module de configuration (config.py)
"""

import tempfile
from pathlib import Path

import pytest
import yaml
from pydantic import ValidationError

from src.config import Config, DataConfig, TrainConfig, get_config, load_config


class TestConfig:
    """Tests pour le module de configuration"""

    def test_data_config_defaults(self):
        """Test des valeurs par défaut de DataConfig"""
        config = DataConfig()
        assert config.test_size == 0.2
        assert config.random_state == 42

    def test_train_config_defaults(self):
        """Test des valeurs par défaut de TrainConfig"""
        config = TrainConfig()
        assert config.test_size == 0.2  # Hérité de BaseConfig
        assert config.random_state == 42  # Hérité de BaseConfig
        assert config.n_estimators == 100
        assert config.max_depth is None

    def test_train_config_custom_values(self):
        """Test avec des valeurs personnalisées"""
        config = TrainConfig(n_estimators=200, max_depth=10)
        assert config.n_estimators == 200
        assert config.max_depth == 10

    def test_config_validation_test_size(self):
        """Test de validation de test_size"""
        # test_size doit être entre 0 et 1
        with pytest.raises(ValidationError):
            DataConfig(test_size=-0.1)

        with pytest.raises(ValidationError):
            DataConfig(test_size=1.5)

        # Valeurs valides (test_size doit être > 0.0 selon la validation)
        config1 = DataConfig(test_size=0.01)  # Minimum valide (> 0.0)
        assert config1.test_size == 0.01

        config2 = DataConfig(test_size=0.99)
        assert config2.test_size == 0.99

    def test_config_validation_random_state(self):
        """Test de validation de random_state"""
        # random_state doit être >= 0
        with pytest.raises(ValidationError):
            DataConfig(random_state=-1)

        # Valeurs valides
        config = DataConfig(random_state=0)
        assert config.random_state == 0

        config = DataConfig(random_state=100)
        assert config.random_state == 100

    def test_config_validation_n_estimators(self):
        """Test de validation de n_estimators"""
        # n_estimators doit être > 0
        with pytest.raises(ValidationError):
            TrainConfig(n_estimators=0)

        with pytest.raises(ValidationError):
            TrainConfig(n_estimators=-10)

        # Valeurs valides
        config = TrainConfig(n_estimators=1)
        assert config.n_estimators == 1

        config = TrainConfig(n_estimators=1000)
        assert config.n_estimators == 1000

    def test_load_config_from_file(self):
        """Test de chargement de configuration depuis un fichier YAML"""
        # Créer un fichier YAML temporaire
        with tempfile.NamedTemporaryFile(mode="w", suffix=".yaml", delete=False) as f:
            config_data = {
                "data": {"test_size": 0.3, "random_state": 100},
                "train": {"n_estimators": 200, "max_depth": 10},
            }
            yaml.dump(config_data, f)
            temp_path = f.name

        try:
            config = load_config(temp_path)
            assert config.data.test_size == 0.3
            assert config.data.random_state == 100
            assert config.train.n_estimators == 200
            assert config.train.max_depth == 10
        finally:
            Path(temp_path).unlink()

    def test_load_config_invalid_yaml(self):
        """Test avec un fichier YAML invalide"""
        with tempfile.NamedTemporaryFile(mode="w", suffix=".yaml", delete=False) as f:
            f.write("invalid: yaml: content: [")
            temp_path = f.name

        try:
            with pytest.raises(yaml.YAMLError):
                load_config(temp_path)
        finally:
            Path(temp_path).unlink()

    def test_load_config_invalid_values(self):
        """Test avec des valeurs invalides dans le YAML"""
        with tempfile.NamedTemporaryFile(mode="w", suffix=".yaml", delete=False) as f:
            config_data = {
                "data": {"test_size": 2.0},  # Invalide (> 1.0)
            }
            yaml.dump(config_data, f)
            temp_path = f.name

        try:
            with pytest.raises(ValidationError):
                load_config(temp_path)
        finally:
            Path(temp_path).unlink()

    def test_load_config_nonexistent_file(self):
        """Test avec un fichier inexistant"""
        config = load_config("/nonexistent/path/params.yaml")
        # Devrait retourner une config avec valeurs par défaut
        assert isinstance(config, Config)
        assert config.data.test_size == 0.2

    def test_get_config_singleton(self):
        """Test que get_config retourne un singleton"""
        config1 = get_config()
        config2 = get_config()
        assert config1 is config2

    def test_get_config_reload(self):
        """Test du rechargement de la configuration"""
        config1 = get_config()
        config2 = get_config(reload=True)
        # Après reload, peut être la même instance ou une nouvelle
        assert isinstance(config2, Config)

    def test_config_inheritance(self):
        """Test que TrainConfig hérite bien de BaseConfig"""
        config = TrainConfig()
        # Vérifier que les attributs de BaseConfig sont présents
        assert hasattr(config, "test_size")
        assert hasattr(config, "random_state")
        assert hasattr(config, "n_estimators")
        assert hasattr(config, "max_depth")
