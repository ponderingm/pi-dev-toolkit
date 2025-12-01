# pi-dev-toolkit

Raspberry Pi 開発環境のテンプレートリポジトリ（Coolify と Tailscale を使用）

## 概要

- **対象:** Raspberry Pi 4 (ARM64)
- **OS:** Raspberry Pi OS Lite (64-bit)
- **インフラ:** Coolify (PaaS), Tailscale (メッシュ VPN)
- **ワークフロー:** ローカル PC (Docker Compose) → Git Push → Coolify 自動デプロイ

## クイックスタート

### 1. テンプレートとして使用

GitHub で「Use this template」をクリックして、このテンプレートに基づいた新しいリポジトリを作成してください。

### 2. Raspberry Pi のセットアップ

Raspberry Pi でセットアップスクリプトを実行します（`<your-username>` を自分の GitHub ユーザー名に置き換えてください）：

```bash
curl -fsSL https://raw.githubusercontent.com/<your-username>/pi-dev-toolkit/main/scripts/setup.sh | bash
```

または、クローンしてローカルで実行（`<your-username>` を自分の GitHub ユーザー名に置き換えてください）：

```bash
git clone https://github.com/<your-username>/pi-dev-toolkit.git
cd pi-dev-toolkit
chmod +x scripts/setup.sh
sudo ./scripts/setup.sh
```

### 3. ローカル開発

1. 環境ファイルをコピー：
   ```bash
   cp .env.example .env
   ```

2. `compose.yaml` を編集し、必要な言語設定（Node.js、Python、または Go）のコメントを解除します。

3. 開発コンテナを起動：
   ```bash
   docker compose up
   ```

## プロジェクト構成

```
pi-dev-toolkit/
├── .editorconfig        # エディタ設定の標準化
├── .env.example         # 環境変数テンプレート
├── .gitignore           # Git 除外ルール
├── .vscode/             # VS Code 設定
│   ├── extensions.json  # 推奨拡張機能
│   └── settings.json    # エディタ設定
├── .vimrc               # Vim configuration
├── compose.yaml         # ローカル開発用 Docker Compose
├── docs/
│   └── ai_instruction.md # AI アシスタント向け指示
├── nixpacks.toml        # Coolify/Nixpacks 設定
├── README.md            # このファイル
└── scripts/
    └── setup.sh         # Raspberry Pi セットアップスクリプト
```

## 開発ワークフロー

1. Docker Compose を使用してローカルで開発
2. GitHub にプッシュ
3. Coolify が自動的に Raspberry Pi にデプロイ

## ライセンス

MIT
