#!/bin/bash
# Download CodeBERT ONNX model and classifier weights for CodeLens ML pipeline.
# Models are stored in mojo-engine/src/models/ (gitignored).
#
# Usage: ./scripts/download_models.sh [--models-dir <path>]

set -euo pipefail

MODELS_DIR="${1:-$(dirname "$0")/../src/models}"

mkdir -p "$MODELS_DIR"

echo "=== CodeLens Model Downloader ==="
echo "Models directory: $MODELS_DIR"
echo

# 1. Download CodeBERT ONNX model
CODEBERT_ONNX="$MODELS_DIR/codebert.onnx"
if [ -f "$CODEBERT_ONNX" ]; then
    echo "[OK] CodeBERT ONNX already exists: $CODEBERT_ONNX"
else
    echo "[DOWNLOAD] Exporting CodeBERT to ONNX format..."

    python3 -c "
import sys
try:
    from transformers import AutoTokenizer, AutoModel
    from optimum.onnxruntime import ORTModelForFeatureExtraction
    import os

    model_name = 'microsoft/codebert-base'
    output_dir = '$MODELS_DIR/codebert_temp'

    print(f'Downloading and converting {model_name} to ONNX...')

    # Use optimum for direct ONNX export
    model = ORTModelForFeatureExtraction.from_pretrained(model_name, export=True)
    model.save_pretrained(output_dir)

    # Move the ONNX file
    import shutil
    onnx_file = os.path.join(output_dir, 'model.onnx')
    if os.path.exists(onnx_file):
        shutil.move(onnx_file, '$CODEBERT_ONNX')
        print(f'[OK] CodeBERT ONNX saved to: $CODEBERT_ONNX')

    # Cleanup temp dir
    shutil.rmtree(output_dir, ignore_errors=True)

except ImportError as e:
    print(f'[WARN] Missing dependencies: {e}')
    print('Install with: pip install transformers optimum onnxruntime')
    sys.exit(1)
except Exception as e:
    print(f'[ERROR] Failed to export CodeBERT: {e}')
    sys.exit(1)
"
fi

# 2. Download/initialize classifier weights
CLASSIFIER_WEIGHTS="$MODELS_DIR/classifier_weights.npz"
if [ -f "$CLASSIFIER_WEIGHTS" ]; then
    echo "[OK] Classifier weights already exist: $CLASSIFIER_WEIGHTS"
else
    echo "[INIT] Initializing random classifier weights (to be fine-tuned)..."

    python3 -c "
import numpy as np

# Initialize with small random weights
# 7 classes x 768 embedding dims
weights = np.random.randn(7, 768).astype(np.float32) * 0.01
biases = np.zeros(7, dtype=np.float32)

# Slight bias toward 'new_feature' (class 0) as default
biases[0] = 0.1

np.savez('$CLASSIFIER_WEIGHTS', weights=weights, biases=biases)
print('[OK] Classifier weights initialized: $CLASSIFIER_WEIGHTS')
print('     Note: These are random weights. Fine-tune on labeled data for accuracy.')
"
fi

# 3. Download tokenizer config (needed for offline use)
TOKENIZER_DIR="$MODELS_DIR/tokenizer"
if [ -d "$TOKENIZER_DIR" ]; then
    echo "[OK] Tokenizer config already exists: $TOKENIZER_DIR"
else
    echo "[DOWNLOAD] Downloading CodeBERT tokenizer..."

    python3 -c "
from transformers import AutoTokenizer

tokenizer = AutoTokenizer.from_pretrained('microsoft/codebert-base')
tokenizer.save_pretrained('$TOKENIZER_DIR')
print('[OK] Tokenizer saved to: $TOKENIZER_DIR')
" 2>/dev/null || echo "[WARN] Could not download tokenizer. Will use online version."
fi

echo
echo "=== Download complete ==="
echo "Models in: $MODELS_DIR"
ls -la "$MODELS_DIR/" 2>/dev/null || true
