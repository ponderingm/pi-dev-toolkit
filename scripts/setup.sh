#!/bin/bash
set -e

echo "=========================================="
echo "Raspberry Pi Development Environment Setup"
echo "=========================================="

# Update system packages
echo "[1/4] Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential tools
echo "[2/4] Installing essential tools..."
sudo apt install -y curl git htop

# Install Tailscale
echo "[3/4] Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

# Install Coolify
echo "[4/4] Installing Coolify..."
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
