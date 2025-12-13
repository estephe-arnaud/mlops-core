#!/bin/bash

set -e

EXPERIMENT="iris-classification"
PYTHON="poetry run python -m src.training.train"

run_exp() {
    local message="$1"
    shift  # Retire le premier argument (message) de $@
    echo "📊 $message"
    $PYTHON --experiment-name "$EXPERIMENT" "$@"
    echo ""
}

run_exp "Expérience 1: baseline" \
    --n-estimators 100 --max-depth 100 \
    --tag experiment_type baseline --tag status testing

run_exp "Expérience 2: hyperparameter tuning" \
    --n-estimators 200 --max-depth 10 \
    --tag experiment_type hyperparameter_tuning --tag status testing

run_exp "Expérience 3: hyperparameter tuning" \
    --n-estimators 150 --max-depth 5 \
    --tag experiment_type hyperparameter_tuning --tag status testing

run_exp "Expérience 4: test_size=0.3" \
    --n-estimators 100 --test-size 0.3 \
    --tag experiment_type data_split_testing --tag status testing

echo "✅ Toutes les expériences terminées !"
echo "🔗 Visualiser: poetry run mlflow ui"
