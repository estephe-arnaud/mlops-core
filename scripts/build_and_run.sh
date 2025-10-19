#!/bin/bash

# Script de build et exécution Docker pour la semaine 1 MLOps
# Usage: ./scripts/build_and_run.sh

echo "🐳 Build et exécution de l'API Classification Iris"
echo "================================================="

# Build de l'image Docker
echo "🔨 Build de l'image Docker..."
docker build -t iris-api:latest .

if [ $? -eq 0 ]; then
    echo "✅ Build réussi !"
else
    echo "❌ Erreur lors du build"
    exit 1
fi

# Arrêt du conteneur existant s'il existe
echo "🛑 Arrêt du conteneur existant..."
docker stop iris-api 2>/dev/null || true
docker rm iris-api 2>/dev/null || true

# Lancement du nouveau conteneur
echo "🚀 Lancement du conteneur..."
docker run -d \
    --name iris-api \
    -p 8000:8000 \
    iris-api:latest

if [ $? -eq 0 ]; then
    echo "✅ Conteneur lancé avec succès !"
    echo "🌐 API disponible sur : http://localhost:8000"
    echo "📚 Documentation : http://localhost:8000/docs"
    echo "❤️  Santé : http://localhost:8000/health"
    
    # Attendre que l'API soit prête
    echo "⏳ Attente du démarrage de l'API..."
    sleep 5
    
    # Test de santé
    echo "🔍 Test de santé de l'API..."
    curl -f http://localhost:8000/health && echo "✅ API opérationnelle !" || echo "❌ API non accessible"
    
    echo ""
    echo "📋 Commandes utiles :"
    echo "   Voir les logs : docker logs iris-api"
    echo "   Arrêter : docker stop iris-api"
    echo "   Redémarrer : docker restart iris-api"
else
    echo "❌ Erreur lors du lancement du conteneur"
    exit 1
fi
