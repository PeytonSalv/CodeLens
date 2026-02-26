#!/bin/bash
set -e

echo "Setting up CodeLens..."

# Check prerequisites
command -v node >/dev/null 2>&1 || { echo "Node.js is required. Install via: nvm install 20"; exit 1; }
command -v cargo >/dev/null 2>&1 || { echo "Rust is required. Install via: https://rustup.rs"; exit 1; }

# Install Node dependencies
echo "Installing Node dependencies..."
npm install

# Install Tauri CLI if missing
if ! cargo tauri --version >/dev/null 2>&1; then
  echo "Installing Tauri CLI..."
  cargo install tauri-cli --version "^2"
fi

# Set up Mojo engine
if command -v pixi >/dev/null 2>&1; then
  echo "Setting up Mojo engine..."
  cd mojo-engine
  pixi install
  cd ..
else
  echo "Pixi not found. Install via: curl -fsSL https://pixi.sh/install.sh | sh"
  echo "Then run: cd mojo-engine && pixi install"
fi

# Create .env if it doesn't exist
if [ ! -f .env ]; then
  cp .env.example .env
  echo "Created .env file. Add your ANTHROPIC_API_KEY to it."
fi

echo "Setup complete."
