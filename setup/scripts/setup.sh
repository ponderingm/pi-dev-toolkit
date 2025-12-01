#!/bin/bash
set -e

echo "=========================================="
echo "Raspberry Pi 開発環境セットアップ"
echo "=========================================="

# Update system packages
echo "[1/7] Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential tools
echo "[2/7] Installing essential tools..."
sudo apt install -y curl git htop vim

# Configure Vim
echo "[3/7] Configuring Vim..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DIR="$(dirname "$SCRIPT_DIR")"
if [ -f "$SETUP_DIR/.vimrc" ]; then
  cp "$SETUP_DIR/.vimrc" "$HOME/.vimrc"
  echo "  .vimrc copied to $HOME/.vimrc"
else
  echo "  Warning: .vimrc not found in setup directory"
fi

# Configure Git
echo "[4/7] Configuring Git..."
# Git ユーザー名の設定
current_name=$(git config --global user.name 2>/dev/null || echo "")
if [ -n "$current_name" ]; then
  echo "  現在の Git ユーザー名: $current_name"
  read -r -p "  新しいユーザー名を入力（変更しない場合は Enter）: " git_name
  if [ -n "$git_name" ]; then
    git config --global user.name "$git_name"
    echo "  Git ユーザー名を '$git_name' に設定しました"
  else
    echo "  Git ユーザー名は変更しませんでした"
  fi
else
  read -r -p "  Git ユーザー名を入力: " git_name
  if [ -n "$git_name" ]; then
    git config --global user.name "$git_name"
    echo "  Git ユーザー名を '$git_name' に設定しました"
  else
    echo "  Warning: Git ユーザー名が設定されていません"
  fi
fi

# Git メールアドレスの設定
current_email=$(git config --global user.email 2>/dev/null || echo "")
if [ -n "$current_email" ]; then
  echo "  現在の Git メールアドレス: $current_email"
  read -r -p "  新しいメールアドレスを入力（変更しない場合は Enter）: " git_email
  if [ -n "$git_email" ]; then
    git config --global user.email "$git_email"
    echo "  Git メールアドレスを '$git_email' に設定しました"
  else
    echo "  Git メールアドレスは変更しませんでした"
  fi
else
  read -r -p "  Git メールアドレスを入力: " git_email
  if [ -n "$git_email" ]; then
    git config --global user.email "$git_email"
    echo "  Git メールアドレスを '$git_email' に設定しました"
  else
    echo "  Warning: Git メールアドレスが設定されていません"
  fi
fi

# Install GitHub CLI
echo "[5/7] Installing GitHub CLI..."
if ! command -v gh &> /dev/null; then
  # GitHub CLI 公式リポジトリの追加
  (type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
    && sudo mkdir -p -m 755 /etc/apt/keyrings \
    && out=$(mktemp) && wget -nv -O "$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && sudo cp "$out" /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt update \
    && sudo apt install gh -y
  echo "  GitHub CLI をインストールしました"
else
  echo "  GitHub CLI は既にインストールされています"
fi

# Install Tailscale
echo "[6/7] Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

# Install Coolify
echo "[7/7] Installing Coolify..."
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

echo ""
echo "=========================================="
echo "セットアップ完了！"
echo "=========================================="
echo ""
echo "次のステップ:"
echo "  1. 'gh auth login' を実行して GitHub にログイン"
echo "  2. 'sudo tailscale up' を手動で実行して Tailscale ネットワークに接続"
echo "  3. http://localhost:8000 で Coolify にアクセス"
echo ""
