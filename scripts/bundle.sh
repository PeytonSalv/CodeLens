#!/bin/bash
# Full release build: compile Mojo engine → copy binary → build Tauri app.
#
# Usage: ./scripts/bundle.sh
#
# Prerequisites:
#   - pixi (for Mojo compilation)
#   - Node.js + npm (for frontend build)
#   - Rust toolchain (for Tauri backend)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== CodeLens Full Release Build ==="
echo "Project directory: $PROJECT_DIR"
echo

# Step 1: Build Mojo engine
echo "--- Step 1/4: Building Mojo engine ---"
"$SCRIPT_DIR/build-mojo.sh"
echo

# Step 2: Copy Mojo binary to Tauri sidecar location
echo "--- Step 2/4: Copying binary to sidecar location ---"
SIDECAR_DIR="$PROJECT_DIR/src-tauri/binaries"
mkdir -p "$SIDECAR_DIR"

# Determine target triple for sidecar naming
ARCH="$(uname -m)"
OS="$(uname -s)"
case "$OS-$ARCH" in
    Darwin-arm64)
        TARGET="aarch64-apple-darwin"
        ;;
    Darwin-x86_64)
        TARGET="x86_64-apple-darwin"
        ;;
    Linux-x86_64)
        TARGET="x86_64-unknown-linux-gnu"
        ;;
    Linux-aarch64)
        TARGET="aarch64-unknown-linux-gnu"
        ;;
    *)
        echo "[WARN] Unknown platform $OS-$ARCH, using generic name"
        TARGET=""
        ;;
esac

MOJO_BINARY="$PROJECT_DIR/mojo-engine/build/codelens-engine"
if [ -n "$TARGET" ]; then
    cp "$MOJO_BINARY" "$SIDECAR_DIR/codelens-engine-$TARGET"
    echo "[OK] Sidecar binary: $SIDECAR_DIR/codelens-engine-$TARGET"
else
    cp "$MOJO_BINARY" "$SIDECAR_DIR/codelens-engine"
    echo "[OK] Sidecar binary: $SIDECAR_DIR/codelens-engine"
fi
echo

# Step 3: Install npm dependencies
echo "--- Step 3/4: Installing npm dependencies ---"
cd "$PROJECT_DIR"
npm install
echo

# Step 4: Build Tauri app
echo "--- Step 4/4: Building Tauri application ---"
npm run tauri build

echo
echo "=== Bundle complete ==="
echo "Check src-tauri/target/release/bundle/ for the packaged app."
ls -la "$PROJECT_DIR/src-tauri/target/release/bundle/" 2>/dev/null || echo "(Bundle directory will be created by tauri build)"
