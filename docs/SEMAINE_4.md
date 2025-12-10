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
- Intégrer MLflow dans le script d'entraînement (src/training/train.py)
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
# src/training/train.py avec MLflow
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
    cmd: python -m src.data.prepare
    deps:
    - data/raw/iris.csv
    outs:
    - data/processed/train.csv
    - data/processed/test.csv
    
  train:
    cmd: python -m src.training.train
    deps:
    - data/processed/train.csv
    - data/processed/test.csv
    - src/training/train.py
    - src/evaluation/evaluate.py
    outs:
    - models/iris_model.pkl
    - models/metadata.json
    metrics:
    - models/metrics.json
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
- [ ] Intégration dans src/training/train.py
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

---

## ✅ Implémentation Complète

### Phase 1 : MLflow Tracking ✅

#### Installation
MLflow a été ajouté aux dépendances dans `pyproject.toml` :
```toml
mlflow = "^2.9.2"
```

#### Intégration dans training/train.py
Le script `src/training/train.py` a été modifié pour intégrer MLflow :

**Fonctionnalités implémentées** :
- ✅ Tracking des hyperparamètres (n_estimators, max_depth, random_state, test_size)
- ✅ Logging des métriques globales (accuracy, precision, recall, f1-score)
- ✅ Logging des métriques par classe (precision, recall, f1-score pour chaque classe)
- ✅ Sauvegarde de la confusion matrix comme artifact
- ✅ Enregistrement du modèle via `mlflow.sklearn.log_model()`
- ✅ Sauvegarde des métadonnées comme artifact JSON

**Utilisation** :
```python
from src.training.train import train_model

# Avec MLflow (par défaut)
model, metadata = train_model(n_estimators=100, max_depth=10)

# Sans MLflow
model, metadata = train_model(use_mlflow=False)
```

#### Interface MLflow UI
Lancer l'interface web :
```bash
make mlflow-ui
# Ou directement
poetry run mlflow ui --host 127.0.0.1 --port 5000
```

Accès : http://localhost:5000

**Fonctionnalités disponibles** :
- Visualisation des expériences
- Comparaison des runs
- Graphiques des métriques
- Téléchargement des modèles
- Visualisation des artifacts

### Phase 2 : DVC Pipeline ✅

#### Installation
DVC a été ajouté aux dépendances dans `pyproject.toml` :
```toml
dvc = {extras = ["gs", "s3", "azure", "oss", "ssh", "hdfs", "webdav", "gdrive"], version = "^3.41.0"}
```

#### Structure des données
```
data/
├── raw/              # Dataset brut (versionné avec DVC)
│   └── iris.csv
└── processed/        # Données traitées (générées)
    ├── train.csv
    └── test.csv
```

#### Script de préparation
Le script `src/data/prepare.py` :
- Charge le dataset Iris depuis scikit-learn
- Crée un DataFrame pandas
- Lit les paramètres depuis `params.yaml` via `src/config.py` (validation Pydantic)
- Divise en train/test avec les paramètres configurés
- Sauvegarde dans `data/raw/` et `data/processed/`

#### Configuration centralisée
Le module `src/config.py` :
- Lit et valide les paramètres depuis `params.yaml` avec Pydantic
- Validation type-safe des hyperparamètres et paramètres de données
- Valeurs par défaut si `params.yaml` est absent
- Pattern singleton pour éviter les rechargements multiples

#### Pipeline DVC
Le fichier `dvc.yaml` définit le pipeline :

**Étape 1 : Prepare**
- Commande : `poetry run python -m src.data.prepare`
- Dépendances : `src/data/prepare.py`, `src/config.py`
- Paramètres : `data.test_size`, `data.random_state` (depuis `params.yaml`)
- Sorties : `data/raw/iris.csv`, `data/processed/train.csv`, `data/processed/test.csv`

**Étape 2 : Train**
- Commande : `poetry run python -m src.training.train`
- Dépendances : `data/processed/train.csv`, `data/processed/test.csv`, `src/training/train.py`, `src/evaluation/evaluate.py`, `src/config.py`
- Paramètres : `train.n_estimators`, `train.max_depth`, `train.random_state`, `train.test_size` (depuis `params.yaml`)
- Sorties : `models/iris_model.pkl`, `models/metadata.json`
- Métriques : `models/metrics.json`

#### Commandes DVC

**Initialisation** :
```bash
make dvc-init
# Ou directement
poetry run dvc init
```

**Exécution du pipeline** :
```bash
make dvc-repro
# Ou directement
poetry run dvc repro
```

**Vérifier l'état** :
```bash
make dvc-status
# Ou directement
poetry run dvc status
```

**Visualiser le pipeline** :
```bash
make dvc-pipeline
# Ou directement
poetry run dvc dag
```

### Phase 3 : Intégration Complète ✅

#### Configuration centralisée avec Pydantic ✅
Le module `src/config.py` a été créé pour :
- ✅ Lire et valider les paramètres depuis `params.yaml`
- ✅ Validation type-safe avec Pydantic (contraintes, types)
- ✅ Gestion d'erreurs robuste avec valeurs par défaut
- ✅ Pattern singleton pour performance
- ✅ Factorisation des paramètres communs (DRY)

#### Scripts améliorés
Les scripts `prepare.py` et `train.py` :
- ✅ Utilisent `get_config()` pour lire les paramètres depuis `params.yaml`
- ✅ Paramètres surchargeables en arguments si nécessaire
- ✅ Logging structuré pour traçabilité
- ✅ Compatible avec MLflow et DVC simultanément

#### Commandes Makefile
Nouvelles commandes ajoutées :

**MLflow** :
- `make mlflow-ui` : Lancer l'interface MLflow
- `make mlflow-experiments` : Lister les expériences

**DVC** :
- `make dvc-init` : Initialiser DVC
- `make dvc-repro` : Réexécuter le pipeline
- `make dvc-status` : Vérifier l'état
- `make dvc-push` : Pousser les données (si remote configuré)
- `make dvc-pull` : Télécharger les données
- `make dvc-pipeline` : Afficher le pipeline

## 🚀 Guide d'Utilisation

### Workflow Complet

#### 1. Installation
```bash
# Installer les dépendances (inclut MLflow et DVC)
make install
```

#### 2. Préparer les données (DVC)
```bash
# Exécuter l'étape prepare du pipeline
poetry run dvc repro prepare

# Ou exécuter directement
poetry run python -m src.data.prepare
```

#### 3. Entraîner le modèle avec MLflow
```bash
# Entraîner avec tracking MLflow
make train

# Ou avec des hyperparamètres personnalisés
poetry run python -c "
from src.training.train import train_model
train_model(n_estimators=150, max_depth=15)
"
```

#### 4. Visualiser les résultats
```bash
# Lancer MLflow UI
make mlflow-ui

# Ouvrir http://localhost:5000 dans le navigateur
```

#### 5. Exécuter le pipeline complet (DVC)
```bash
# Exécuter toutes les étapes
make dvc-repro

# Vérifier l'état
make dvc-status
```

### Exemples d'Expériences MLflow

#### Expérience 1 : Modèle de base
```bash
poetry run python -c "
from src.training.train import train_model
train_model(n_estimators=100, max_depth=None)
"
```

#### Expérience 2 : Modèle avec profondeur limitée
```bash
poetry run python -c "
from src.training.train import train_model
train_model(n_estimators=100, max_depth=5)
"
```

#### Expérience 3 : Plus d'arbres
```bash
poetry run python -c "
from src.training.train import train_model
train_model(n_estimators=200, max_depth=10)
"
```

### Versioning des Données (DVC)

#### Ajouter des données au tracking
```bash
# Ajouter le dataset brut
poetry run dvc add data/raw/iris.csv

# Commit dans Git
git add data/raw/iris.csv.dvc .gitignore
git commit -m "Add iris dataset"
```

#### Changer de version de données
```bash
# Modifier les données
# ...

# Mettre à jour DVC
poetry run dvc add data/raw/iris.csv

# Commit
git add data/raw/iris.csv.dvc
git commit -m "Update dataset version"
```

## 📊 Résultats Attendus

### MLflow
- ✅ Expériences loggées dans `mlruns/`
- ✅ Modèles enregistrés et versionnés
- ✅ Métriques tracées et comparables
- ✅ Interface web fonctionnelle

### DVC
- ✅ Pipeline reproductible
- ✅ Données versionnées
- ✅ Dépendances gérées automatiquement
- ✅ Cache pour accélérer les réexécutions

## 🔍 Dépannage

### MLflow UI ne démarre pas
```bash
# Vérifier que MLflow est installé
poetry run mlflow --version

# Vérifier le port 5000
lsof -i :5000

# Utiliser un autre port
poetry run mlflow ui --port 5001
```

### DVC pipeline échoue
```bash
# Vérifier que les dépendances existent
poetry run dvc status

# Nettoyer et réexécuter
poetry run dvc repro --force
```

### Données non trouvées
```bash
# Vérifier que prepare a été exécuté
ls -la data/processed/

# Réexécuter prepare
poetry run dvc repro prepare
```

## ✅ Validation des Objectifs

| Objectif | Status | Détails |
|----------|--------|---------|
| **MLflow Tracking** | ✅ | Intégration complète avec logging paramètres/métriques |
| **MLflow UI** | ✅ | Interface web fonctionnelle |
| **DVC Pipeline** | ✅ | Pipeline à 2 étapes (prepare, train) |
| **Versioning Données** | ✅ | Dataset versionné avec DVC |
| **Reproductibilité** | ✅ | Pipeline reproductible |
| **Documentation** | ✅ | Guide complet dans ce fichier |

---

**🎉 Semaine 4 terminée avec succès !**

Le projet dispose maintenant de :
- ✅ Tracking complet des expériences ML avec MLflow
- ✅ Versioning des données et pipeline reproductible avec DVC
- ✅ Documentation complète et guide d'utilisation

Le Projet 1 est maintenant finalisé et prêt pour la démonstration !
