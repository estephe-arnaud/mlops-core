"""
Tests unitaires pour le module de préparation des données (data/prepare.py)
"""

import os
import tempfile
from pathlib import Path

import pandas as pd
import pytest

from src.data.prepare import prepare_iris_data


class TestDataPrepare:
    """Tests pour le module de préparation des données"""

    def test_prepare_iris_data_default(self):
        """Test de préparation des données avec paramètres par défaut"""
        with tempfile.TemporaryDirectory() as temp_dir:
            original_dir = os.getcwd()
            try:
                os.chdir(temp_dir)
                os.makedirs("data/raw", exist_ok=True)
                os.makedirs("data/processed", exist_ok=True)

                train_path, test_path = prepare_iris_data()

                # Vérifier que les fichiers existent
                assert train_path.exists()
                assert test_path.exists()
                assert Path("data/raw/iris.csv").exists()

                # Vérifier le contenu
                train_df = pd.read_csv(train_path)
                test_df = pd.read_csv(test_path)

                assert len(train_df) > 0
                assert len(test_df) > 0
                assert len(train_df) + len(test_df) == 150  # Dataset Iris complet

                # Vérifier les colonnes
                assert "sepal length (cm)" in train_df.columns
                assert "sepal width (cm)" in train_df.columns
                assert "petal length (cm)" in train_df.columns
                assert "petal width (cm)" in train_df.columns
                assert "target" in train_df.columns
                assert "target_name" in train_df.columns

            finally:
                os.chdir(original_dir)

    def test_prepare_iris_data_custom_params(self):
        """Test avec des paramètres personnalisés"""
        with tempfile.TemporaryDirectory() as temp_dir:
            original_dir = os.getcwd()
            try:
                os.chdir(temp_dir)
                os.makedirs("data/raw", exist_ok=True)
                os.makedirs("data/processed", exist_ok=True)

                train_path, test_path = prepare_iris_data(
                    test_size=0.3, random_state=123
                )

                train_df = pd.read_csv(train_path)
                test_df = pd.read_csv(test_path)

                # Vérifier la proportion approximative (0.3 = 30% pour test)
                total = len(train_df) + len(test_df)
                test_ratio = len(test_df) / total
                assert 0.25 < test_ratio < 0.35  # Tolérance pour la stratification

            finally:
                os.chdir(original_dir)

    def test_prepare_iris_data_files_created(self):
        """Test que tous les fichiers nécessaires sont créés"""
        with tempfile.TemporaryDirectory() as temp_dir:
            original_dir = os.getcwd()
            try:
                os.chdir(temp_dir)
                os.makedirs("data/raw", exist_ok=True)
                os.makedirs("data/processed", exist_ok=True)

                prepare_iris_data()

                # Vérifier les fichiers
                assert Path("data/raw/iris.csv").exists()
                assert Path("data/processed/train.csv").exists()
                assert Path("data/processed/test.csv").exists()

            finally:
                os.chdir(original_dir)

    def test_prepare_iris_data_data_integrity(self):
        """Test de l'intégrité des données"""
        with tempfile.TemporaryDirectory() as temp_dir:
            original_dir = os.getcwd()
            try:
                os.chdir(temp_dir)
                os.makedirs("data/raw", exist_ok=True)
                os.makedirs("data/processed", exist_ok=True)

                prepare_iris_data()

                # Charger les données
                raw_df = pd.read_csv("data/raw/iris.csv")
                train_df = pd.read_csv("data/processed/train.csv")
                test_df = pd.read_csv("data/processed/test.csv")

                # Vérifier qu'il n'y a pas de doublons entre train et test
                # Utiliser les valeurs des features pour identifier les doublons
                # plutôt que les index (qui peuvent se chevaucher après sauvegarde/chargement)
                feature_cols = [
                    "sepal length (cm)",
                    "sepal width (cm)",
                    "petal length (cm)",
                    "petal width (cm)",
                ]

                # Créer des tuples de features pour identifier les lignes uniques
                train_tuples = set(
                    tuple(row[col] for col in feature_cols)
                    for _, row in train_df[feature_cols].iterrows()
                )
                test_tuples = set(
                    tuple(row[col] for col in feature_cols)
                    for _, row in test_df[feature_cols].iterrows()
                )

                # Vérifier qu'il n'y a pas d'intersection
                assert len(train_tuples.intersection(test_tuples)) == 0

                # Vérifier que toutes les classes sont présentes dans train
                assert len(train_df["target"].unique()) == 3

                # Vérifier que toutes les classes sont présentes dans test
                assert len(test_df["target"].unique()) == 3

            finally:
                os.chdir(original_dir)
