#!/bin/bash
set -e

MODELS_DIR="$(dirname "$0")/../src/models"
mkdir -p "$MODELS_DIR"

echo "Downloading ML models..."

# CodeBERT ONNX model
if [ ! -f "$MODELS_DIR/codebert.onnx" ]; then
  echo "Downloading CodeBERT ONNX model..."
  echo "TODO: Add model download URL once ONNX export is prepared"
  echo "Placeholder: touch $MODELS_DIR/codebert.onnx"
  # curl -L -o "$MODELS_DIR/codebert.onnx" "https://..."
else
  echo "CodeBERT model already exists, skipping."
fi

# Change classifier model
if [ ! -f "$MODELS_DIR/classifier.onnx" ]; then
  echo "Downloading change classifier model..."
  echo "TODO: Add model download URL once fine-tuned model is prepared"
  echo "Placeholder: touch $MODELS_DIR/classifier.onnx"
  # curl -L -o "$MODELS_DIR/classifier.onnx" "https://..."
else
  echo "Classifier model already exists, skipping."
fi

echo "Model download complete."
