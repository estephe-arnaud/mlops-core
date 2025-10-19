"""
Exemple d'utilisation de l'API Classification Iris
Semaine 1 - MLOps Formation
"""

import requests
import json
import time

# Configuration
API_BASE_URL = "http://localhost:8000"

def test_api_health():
    """Test de santé de l'API"""
    print("❤️  Test de santé de l'API...")
    try:
        response = requests.get(f"{API_BASE_URL}/health")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ API en ligne - Status: {data['status']}")
            print(f"   Modèle chargé: {data['model_loaded']}")
            print(f"   Version: {data['version']}")
            return True
        else:
            print(f"❌ API non accessible - Status: {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print("❌ Impossible de se connecter à l'API")
        return False

def test_model_info():
    """Test des informations du modèle"""
    print("\n📊 Informations du modèle...")
    try:
        response = requests.get(f"{API_BASE_URL}/model/info")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Modèle: {data['model_type']}")
            print(f"   Précision: {data['accuracy']:.3f}")
            print(f"   Features: {data['feature_names']}")
            print(f"   Classes: {data['target_names']}")
        else:
            print(f"❌ Impossible de récupérer les infos du modèle - Status: {response.status_code}")
    except Exception as e:
        print(f"❌ Erreur: {e}")

def test_prediction(sepal_length, sepal_width, petal_length, petal_width, expected_class=None):
    """Test de prédiction"""
    print(f"\n🔮 Prédiction pour [{sepal_length}, {sepal_width}, {petal_length}, {petal_width}]...")
    
    data = {
        "sepal_length": sepal_length,
        "sepal_width": sepal_width,
        "petal_length": petal_length,
        "petal_width": petal_width
    }
    
    try:
        response = requests.post(f"{API_BASE_URL}/predict", json=data)
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Prédiction: {result['prediction']}")
            print(f"   Confiance: {result['confidence']:.3f}")
            print("   Probabilités:")
            for class_name, prob in result['probabilities'].items():
                print(f"     {class_name}: {prob:.3f}")
            
            if expected_class and result['prediction'] == expected_class:
                print(f"✅ Prédiction correcte ! (attendu: {expected_class})")
            elif expected_class:
                print(f"⚠️  Prédiction différente de l'attendu (attendu: {expected_class})")
            
            return result
        else:
            print(f"❌ Erreur de prédiction - Status: {response.status_code}")
            print(f"   Détails: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return None

def main():
    """Fonction principale de test"""
    print("🌸 Test de l'API Classification Iris")
    print("=" * 40)
    
    # Test de santé
    if not test_api_health():
        print("\n❌ L'API n'est pas accessible. Assurez-vous qu'elle est démarrée.")
        print("   Commandes pour démarrer l'API:")
        print("   - Avec Poetry: poetry run uvicorn app:app --reload")
        print("   - Avec Make: make run")
        print("   - Avec Docker: make run-docker")
        return
    
    # Informations du modèle
    test_model_info()
    
    # Tests de prédiction avec des exemples typiques
    print("\n🧪 Tests de prédiction...")
    
    # Iris setosa (typique)
    test_prediction(5.1, 3.5, 1.4, 0.2, "setosa")
    
    # Iris versicolor (typique)
    test_prediction(7.0, 3.2, 4.7, 1.4, "versicolor")
    
    # Iris virginica (typique)
    test_prediction(6.3, 3.3, 6.0, 2.5, "virginica")
    
    # Test avec des valeurs limites
    print("\n🔍 Tests avec des valeurs limites...")
    test_prediction(4.0, 2.0, 1.0, 0.1)  # Très petit
    test_prediction(8.0, 4.5, 7.0, 2.5)  # Très grand
    
    print("\n✅ Tests terminés !")
    print(f"\n📚 Documentation disponible sur: {API_BASE_URL}/docs")

if __name__ == "__main__":
    main()
