# 🟡 Semaine 4 : MLOps Local (MLflow + DVC)

## 🎯 Objectif de la Semaine

**Traquer et versionner les expériences ML localement pour la reproductibilité**

### ❓ Questions Clés
- Comment tracer les expériences (MLflow) ?
- Comment versionner le dataset et le pipeline (DVC) ?

### ⏱️ Répartition des Heures (20h)
- **7h** → Intégrer MLflow Tracking pour logguer les hyperparamètres, métriques et le modèle
- **7h** → Implémenter DVC pour versionner le dataset et le pipeline de pré-traitement
- **6h** → Finalisation Projet 1 : documentation + vidéo démo

## 📋 Tâches à Accomplir

### 1. 📊 MLflow Tracking
- Intégrer MLflow dans le script de training
- Logger les hyperparamètres et métriques
- Sauvegarder les modèles et artifacts
- Interface web MLflow UI

### 2. 🔄 DVC (Data Version Control)
- Initialiser DVC dans le projet
- Versionner le dataset Iris
- Créer un pipeline de pré-traitement
- Gérer les dépendances entre étapes

### 3. 📚 Documentation et Démo
- Rédiger un README complet
- Créer des schémas d'architecture
- Enregistrer une vidéo de démonstration
- Finaliser le Projet 1

## 📦 Livrables Attendus

### Structure MLflow
```
mlruns/                    # Dossier MLflow (généré)
├── 0/                    # Experiments
│   └── runs/             # Runs individuels
└── models/               # Modèles enregistrés
```

### Structure DVC
```
.dvc/                     # Configuration DVC
├── config               # Configuration
├── cache/               # Cache des données
└── tmp/                 # Fichiers temporaires

data/                    # Données versionnées
├── raw/                 # Données brutes
├── processed/           # Données traitées
└── .gitignore          # Ignorer les gros fichiers

dvc.yaml                 # Pipeline DVC
dvc.lock                 # Verrouillage des versions
```

### Documentation
- **README.md** : Documentation complète du projet
- **ARCHITECTURE.md** : Schémas et architecture
- **DEMO_VIDEO.mp4** : Vidéo de démonstration (3-5 min)

## 🚀 Implémentation Prévue

### MLflow Integration
```python
# train_model.py avec MLflow
import mlflow
import mlflow.sklearn

def train_model():
    with mlflow.start_run():
        # Log des paramètres
        mlflow.log_param("algorithm", "RandomForest")
        mlflow.log_param("n_estimators", 100)
        mlflow.log_param("max_depth", 10)
        
        # Entraînement du modèle
        model = RandomForestClassifier(n_estimators=100, max_depth=10)
        model.fit(X_train, y_train)
        
        # Évaluation
        accuracy = model.score(X_test, y_test)
        mlflow.log_metric("accuracy", accuracy)
        
        # Sauvegarde du modèle
        mlflow.sklearn.log_model(model, "model")
        
        return model
```

### DVC Pipeline
```yaml
# dvc.yaml
stages:
  prepare:
    cmd: python scripts/prepare_data.py
    deps:
    - data/raw/iris.csv
    outs:
    - data/processed/train.csv
    - data/processed/test.csv
    
  train:
    cmd: python train_model.py
    deps:
    - data/processed/train.csv
    - data/processed/test.csv
    - train_model.py
    outs:
    - models/iris_model.pkl
    - models/model_metadata.json
    metrics:
    - metrics/accuracy.json
```

## 🛠️ Outils à Utiliser

### MLflow
- **Tracking** : Logging des expériences
- **Models** : Gestion des modèles
- **UI** : Interface web pour visualisation
- **Storage** : Fichier local (puis cloud)

### DVC
- **Data Versioning** : Git-like pour les données
- **Pipeline** : Orchestration des étapes
- **Cache** : Stockage efficace
- **Remote** : Stockage distant (optionnel)

### Visualisation
- **MLflow UI** : Interface web des expériences
- **DVC Plots** : Visualisation des métriques
- **Draw.io** : Schémas d'architecture

## 📊 Métriques Attendues

| Composant | Objectif |
|-----------|----------|
| **MLflow Runs** | 5+ expériences loggées |
| **DVC Pipeline** | 2+ étapes (prepare, train) |
| **Data Versioning** | Dataset et modèles versionnés |
| **Reproductibilité** | Pipeline reproductible |

## 🔗 Ressources

- [MLflow Documentation](https://mlflow.org/docs/latest/index.html)
- [DVC Documentation](https://dvc.org/doc)
- [MLflow Quickstart](https://mlflow.org/docs/latest/getting-started/index.html)
- [DVC Tutorial](https://dvc.org/doc/start)

## 📈 Progression

### Phase 1 : MLflow (7h)
- [ ] Installation et configuration MLflow
- [ ] Intégration dans train_model.py
- [ ] Logging des paramètres et métriques
- [ ] Sauvegarde des modèles
- [ ] Interface web MLflow UI

### Phase 2 : DVC (7h)
- [ ] Installation et initialisation DVC
- [ ] Versioning du dataset
- [ ] Création du pipeline dvc.yaml
- [ ] Gestion des dépendances
- [ ] Tests de reproductibilité

### Phase 3 : Finalisation (6h)
- [ ] Documentation complète
- [ ] Schémas d'architecture
- [ ] Vidéo de démonstration
- [ ] Validation du Projet 1

## 🎯 Objectifs de Validation

- [ ] MLflow UI accessible et fonctionnel
- [ ] Expériences loggées avec paramètres/métriques
- [ ] DVC pipeline reproductible
- [ ] Dataset et modèles versionnés
- [ ] Documentation complète
- [ ] Vidéo de démonstration enregistrée

## 📊 Interface MLflow

### Fonctionnalités à Implémenter
- **Experiments** : Organisation des runs
- **Runs** : Détails de chaque expérience
- **Models** : Gestion des modèles
- **Artifacts** : Fichiers associés
- **Metrics** : Graphiques des métriques

### Métriques à Logger
- **Accuracy** : Précision du modèle
- **Precision** : Précision par classe
- **Recall** : Rappel par classe
- **F1-Score** : Score F1 par classe
- **Confusion Matrix** : Matrice de confusion

## 🔄 Pipeline DVC

### Étapes du Pipeline
1. **Prepare** : Préparation des données
2. **Train** : Entraînement du modèle
3. **Evaluate** : Évaluation et métriques
4. **Deploy** : Préparation du déploiement

### Gestion des Dépendances
- **Data** : Dataset → Train/Test
- **Model** : Train → Model + Metadata
- **Metrics** : Evaluate → Metrics JSON

## 🚀 Prochaines Étapes (Phase 2)

- ☁️ Déploiement cloud avec Vertex AI
- 🐳 Orchestration Kubernetes
- 📊 Monitoring et observabilité
- 🔐 Sécurité et conformité

## 📚 Documentation à Créer

### README Principal
- Vue d'ensemble du projet
- Instructions d'installation
- Guide d'utilisation
- Architecture et schémas

### Documentation Technique
- Configuration MLflow
- Pipeline DVC
- Procédures de déploiement
- Troubleshooting

### Vidéo de Démonstration
- **Durée** : 3-5 minutes
- **Contenu** : Installation, utilisation, résultats
- **Format** : Loom ou OBS Studio
- **Objectif** : Démonstration complète du Projet 1

---

**🔄 Semaine 4 en cours de planification**

Cette semaine finalise le Projet 1 avec le tracking des expériences et le versioning des données.
