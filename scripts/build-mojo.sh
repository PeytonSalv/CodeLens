#!/bin/bash
# Build the Mojo engine binary.
# Requires pixi and Mojo toolchain to be installed.
#
# Usage: ./scripts/build-mojo.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
MOJO_DIR="$PROJECT_DIR/mojo-engine"

echo "=== Building CodeLens Mojo Engine ==="
echo "Mojo directory: $MOJO_DIR"
echo

cd "$MOJO_DIR"

# Ensure pixi is available
if ! command -v pixi &>/dev/null; then
    echo "[ERROR] pixi is not installed. Install it from: https://pixi.sh"
    exit 1
fi

# Build using pixi
echo "[BUILD] Compiling Mojo engine..."
pixi run build

if [ -f "build/codelens-engine" ]; then
    echo "[OK] Binary built at: $MOJO_DIR/build/codelens-engine"
    ls -la build/codelens-engine
else
    echo "[ERROR] Build failed — binary not found"
    exit 1
fi

echo
echo "=== Build complete ==="
