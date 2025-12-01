#!/bin/bash
set -e

echo "=========================================="
echo "Raspberry Pi 開発環境セットアップ"
echo "=========================================="

# システムパッケージの更新
echo "[1/4] システムパッケージを更新中..."
sudo apt update && sudo apt upgrade -y

# 必須ツールのインストール
echo "[2/4] 必須ツールをインストール中..."
sudo apt install -y curl git htop

# Tailscale のインストール
echo "[3/4] Tailscale をインストール中..."
curl -fsSL https://tailscale.com/install.sh | sh

# Coolify のインストール
echo "[4/4] Coolify をインストール中..."
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
