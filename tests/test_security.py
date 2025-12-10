"""
Tests unitaires pour le module de sécurité (security.py)
"""

import os

import pytest
from fastapi import HTTPException, Request
from fastapi.testclient import TestClient

from src.serving.security import (
    get_api_key_from_env,
    get_remote_address,
    verify_api_key,
)


class TestSecurity:
    """Tests pour le module de sécurité"""

    def test_get_api_key_from_env(self, monkeypatch):
        """Test de récupération de l'API key depuis l'environnement"""
        test_key = "test-api-key-12345"
        monkeypatch.setenv("API_KEY", test_key)
        result = get_api_key_from_env()
        assert result == test_key

    def test_get_api_key_from_env_not_set(self, monkeypatch):
        """Test quand API_KEY n'est pas définie"""
        monkeypatch.delenv("API_KEY", raising=False)
        result = get_api_key_from_env()
        assert result is None

    def test_get_remote_address_direct(self):
        """Test de récupération de l'adresse IP directe"""

        # Créer une requête mock
        class MockClient:
            host = "192.168.1.1"
            port = 8000

        class MockRequest:
            client = MockClient()
            headers = {}

        request = MockRequest()
        ip = get_remote_address(request)
        assert ip == "192.168.1.1"

    def test_get_remote_address_x_forwarded_for(self):
        """Test de récupération de l'adresse IP depuis X-Forwarded-For"""

        class MockClient:
            host = "192.168.1.1"
            port = 8000

        class MockRequest:
            client = MockClient()
            headers = {"X-Forwarded-For": "203.0.113.1, 198.51.100.1"}

        request = MockRequest()
        ip = get_remote_address(request)
        # Devrait prendre la première IP (le client réel)
        assert ip == "203.0.113.1"

    def test_get_remote_address_x_real_ip(self):
        """Test de récupération de l'adresse IP depuis X-Real-IP"""

        class MockClient:
            host = "192.168.1.1"
            port = 8000

        class MockRequest:
            client = MockClient()
            headers = {"X-Real-IP": "203.0.113.2"}

        request = MockRequest()
        ip = get_remote_address(request)
        assert ip == "203.0.113.2"

    def test_get_remote_address_no_client(self):
        """Test quand le client n'est pas disponible"""

        class MockRequest:
            client = None
            headers = {}

        request = MockRequest()
        ip = get_remote_address(request)
        assert ip == "unknown"

    def test_verify_api_key_valid(self, api_key):
        """Test de vérification avec une API key valide"""
        from src.serving.app import app

        class MockRequest:
            client = None
            headers = {"X-API-Key": api_key}

        request = MockRequest()
        result = verify_api_key(request, api_key)
        assert result == api_key

    def test_verify_api_key_missing(self, api_key):
        """Test de vérification sans API key"""
        from src.serving.app import app

        class MockRequest:
            client = None
            headers = {}

        request = MockRequest()
        with pytest.raises(HTTPException) as exc_info:
            verify_api_key(request, None)
        assert exc_info.value.status_code == 401

    def test_verify_api_key_invalid(self, api_key):
        """Test de vérification avec une API key invalide"""
        from src.serving.app import app

        class MockRequest:
            client = None
            headers = {"X-API-Key": "invalid-key"}

        request = MockRequest()
        with pytest.raises(HTTPException) as exc_info:
            verify_api_key(request, "invalid-key")
        assert exc_info.value.status_code == 403

    def test_verify_api_key_production_mode(self, monkeypatch):
        """Test en mode production (API key obligatoire)"""
        monkeypatch.setenv("ENVIRONMENT", "production")
        monkeypatch.setenv("API_KEY", "production-key")

        from src.serving.app import app

        class MockRequest:
            client = None
            headers = {}

        request = MockRequest()
        # En production sans API key, devrait lever une exception
        with pytest.raises(HTTPException) as exc_info:
            verify_api_key(request, None)
        assert exc_info.value.status_code == 401

    def test_verify_api_key_production_no_key_configured(self, monkeypatch):
        """Test en mode production sans API_KEY configurée (erreur serveur)"""
        monkeypatch.setenv("ENVIRONMENT", "production")
        monkeypatch.delenv("API_KEY", raising=False)

        from src.serving.app import app

        class MockRequest:
            client = None
            headers = {}

        request = MockRequest()
        # En production sans API_KEY configurée, devrait lever une erreur 500
        with pytest.raises(HTTPException) as exc_info:
            verify_api_key(request, None)
        assert exc_info.value.status_code == 500
