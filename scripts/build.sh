#!/bin/bash
set -e

echo "Building CodeLens for production..."

# Build Mojo engine
if command -v pixi >/dev/null 2>&1; then
  echo "Building Mojo engine..."
  cd mojo-engine
  mkdir -p build
  pixi run mojo build src/main.mojo -o build/codelens-engine
  cd ..
fi

# Build Tauri app
echo "Building Tauri app..."
npm run tauri build

echo "Build complete."
