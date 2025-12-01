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

# Install GitHub CLI
echo "[4/7] Installing GitHub CLI..."
if ! command -v gh &> /dev/null; then
  # GitHub CLI 公式リポジトリの追加
  # wget がインストールされていない場合はインストール
  if ! type -p wget >/dev/null; then
    sudo apt update && sudo apt install wget -y
  fi
  
  # キーリングディレクトリの作成
  sudo mkdir -p -m 755 /etc/apt/keyrings
  
  # GPG キーのダウンロードとインストール
  out=$(mktemp)
  if wget -nv -O "$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg; then
    sudo cp "$out" /etc/apt/keyrings/githubcli-archive-keyring.gpg
    rm -f "$out"
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  else
    rm -f "$out"
    echo "  Error: GitHub CLI のキーリングのダウンロードに失敗しました"
    exit 1
  fi
  
  # APT リポジトリの追加
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  
  # GitHub CLI のインストール
  sudo apt update
  sudo apt install gh -y
  echo "  GitHub CLI をインストールしました"
else
  echo "  GitHub CLI は既にインストールされています"
fi

# Configure Git using GitHub CLI
echo "[5/7] Configuring Git..."

# GitHub認証済みかチェック
if gh auth status &>/dev/null; then
  echo "  GitHub CLI は既に認証されています"
else
  echo "  GitHub CLI で認証を行います..."
  gh auth login
fi

# GitHubからユーザー情報を取得してGitを設定
if gh auth status &>/dev/null; then
  # ユーザー名の取得と設定
  gh_username=$(gh api user --jq '.login' 2>/dev/null || echo "")
  if [ -n "$gh_username" ]; then
    current_name=$(git config --global user.name 2>/dev/null || echo "")
    if [ "$current_name" != "$gh_username" ]; then
      git config --global user.name "$gh_username"
      echo "  Git ユーザー名を '$gh_username' に設定しました（GitHub から取得）"
    else
      echo "  Git ユーザー名は既に '$gh_username' に設定されています"
    fi
  fi
  
  # メールアドレスの取得と設定
  # プライマリメールを取得（プライベートメールの場合はnoreplyを使用）
  gh_email=$(gh api user/emails --jq '.[] | select(.primary == true) | .email' 2>/dev/null || echo "")
  if [ -z "$gh_email" ]; then
    # プライベートメールの場合、GitHub noreplyアドレスを使用
    gh_id=$(gh api user --jq '.id' 2>/dev/null || echo "")
    if [ -n "$gh_id" ] && [ -n "$gh_username" ]; then
      gh_email="${gh_id}+${gh_username}@users.noreply.github.com"
    fi
  fi
  
  if [ -n "$gh_email" ]; then
    current_email=$(git config --global user.email 2>/dev/null || echo "")
    if [ "$current_email" != "$gh_email" ]; then
      git config --global user.email "$gh_email"
      echo "  Git メールアドレスを '$gh_email' に設定しました（GitHub から取得）"
    else
      echo "  Git メールアドレスは既に '$gh_email' に設定されています"
    fi
  fi
else
  echo "  Warning: GitHub CLI が認証されていないため、Git の設定をスキップしました"
  echo "  後で 'gh auth login' を実行してから、再度このスクリプトを実行してください"
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
echo "  1. 'sudo tailscale up' を手動で実行して Tailscale ネットワークに接続"
echo "  2. http://localhost:8000 で Coolify にアクセス"
echo ""
