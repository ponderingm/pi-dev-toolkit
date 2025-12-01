#!/bin/bash
set -e

echo "=========================================="
echo "Raspberry Pi 開発環境セットアップ"
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
SETUP_DIR="$(dirname "$SCRIPT_DIR")"
if [ -f "$SETUP_DIR/.vimrc" ]; then
  cp "$SETUP_DIR/.vimrc" "$HOME/.vimrc"
  echo "  .vimrc copied to $HOME/.vimrc"
else
  echo "  Warning: .vimrc not found in setup directory"
fi

# Install Tailscale
echo "[4/5] Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

# Install Coolify
echo "[5/5] Installing Coolify..."
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

echo ""
echo "=========================================="
echo "セットアップ完了！"
echo "=========================================="
echo ""
echo "次のステップ:"
echo "  1. 'sudo tailscale up' を手動で実行して Tailscale ネットワークに接続"
echo "  2. http://localhost:8000 で Coolify にアクセス"
echo ""
