#!/bin/bash
set -e

echo "=========================================="
echo "Raspberry Pi Development Environment Setup"
echo "=========================================="

# Update system packages
echo "[1/5] Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential tools
echo "[2/5] Installing essential tools..."
sudo apt install -y curl git htop vim

# Configure Vim
echo "[3/5] Configuring Vim..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
if [ -f "$REPO_ROOT/.vimrc" ]; then
  cp "$REPO_ROOT/.vimrc" "$HOME/.vimrc"
  echo "  .vimrc copied to $HOME/.vimrc"
else
  echo "  Warning: .vimrc not found in repository"
fi

# Install Tailscale
echo "[4/5] Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

# Install Coolify
echo "[5/5] Installing Coolify..."
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

echo ""
echo "=========================================="
echo "Setup complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Run 'sudo tailscale up' manually to connect to your Tailscale network"
echo "  2. Access Coolify at http://localhost:8000"
echo ""
