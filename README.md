# Pi Dev Toolkit

**汎用的な開発環境を立ち上げるための設定シェルスクリプトとテンプレート集**

Raspberry Pi 4 上の Coolify を使用した、シンプルで保守可能な開発・デプロイワークフローを実現します。

## 概要

このリポジトリは、以下の2つの要素で構成されています：

1. **初期セットアップツール** (`setup/`) - Raspberry Pi の環境構築用
2. **プロジェクトテンプレート** (`templates/`) - 新規プロジェクト作成用

### 対象環境

- **対象:** Raspberry Pi 4 (ARM64)
- **OS:** Raspberry Pi OS Lite (64-bit)
- **インフラ:** Coolify (PaaS), Tailscale (メッシュ VPN)
- **ワークフロー:** ローカル PC (Docker Compose) → Git Push → Coolify 自動デプロイ

## クイックスタート

### 1. Raspberry Pi の初期セットアップ

まず、このリポジトリをクローンしてセットアップスクリプトを実行します：

```bash
git clone https://github.com/ponderingm/pi-dev-toolkit.git
cd pi-dev-toolkit
bash setup/scripts/setup.sh
```

セットアップスクリプトは以下を実行します：
- システムパッケージの更新
- 必須ツールのインストール（curl, git, vim, htop）
- Vim 設定ファイル (`.vimrc`) のホームディレクトリへのコピー
- GitHub CLI のインストールと認証
- Git の設定（GitHub から自動取得したユーザー名・メールアドレス）
- Tailscale のインストール
- Coolify のインストール
- smee.io クライアントのインストールと Webhook プロキシの設定

### 2. 新規プロジェクトの作成

`templates/` ディレクトリを新しいプロジェクト名でコピーします：

```bash
# pi-dev-toolkit リポジトリの外で実行
cp -r pi-dev-toolkit/templates my-new-project
cd my-new-project
git init
```

### 3. ローカル開発

1. 環境ファイルをコピー：
   ```bash
   cp .env.example .env
   ```

2. `compose.yaml` を編集し、プロジェクトに必要な設定を追加します。

3. 開発コンテナを起動：
   ```bash
   docker compose up
   ```

### 4. GitHub にプッシュしてデプロイ

```bash
git add .
git commit -m "feat: 初期プロジェクト構成"
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin main
```

Coolify で GitHub リポジトリを登録すると、以降は `main` ブランチへのプッシュで自動デプロイされます。

## プロジェクト構成

```
pi-dev-toolkit/
├── .github/                      # このリポジトリ自体の設定
│   ├── copilot-instructions.md   # 汎用的な開発ガイドライン
│   ├── local-instruction.md      # Pi Dev Toolkit の思想
│   └── workflows/
│       └── release.yml           # Release Please 設定
├── setup/                        # Raspberry Pi セットアップツール
│   ├── .vimrc                    # Vim 設定ファイル
│   ├── .vscode/                  # VS Code 設定
│   └── scripts/
│       └── setup.sh              # セットアップスクリプト
├── templates/                    # 新規プロジェクト用テンプレート
│   ├── .env.example              # 環境変数テンプレート
│   ├── .github/
│   │   ├── copilot-instructions.md  # AI アシスタント向け指示
│   │   ├── local-instruction.md     # プロジェクト固有の指示
│   │   └── workflows/
│   │       └── release.yml       # 自動バージョン管理
│   ├── compose.yaml              # Docker Compose 設定
│   ├── instructions/             # 開発ガイドライン
│   │   ├── global.md             # 汎用的な指示書
│   │   └── local.md              # プロジェクト固有の指示書
│   └── nixpacks.toml             # Nixpacks ビルド設定
├── .editorconfig                 # エディタ設定
├── .gitignore                    # Git 除外ルール
└── README.md                     # このファイル
```

## 開発ワークフロー

1. `templates/` から新規プロジェクトを作成
2. ローカルで Docker Compose を使用して開発
3. Conventional Commits 形式でコミット
4. GitHub にプッシュ
5. Coolify が自動的に Raspberry Pi にデプロイ
6. Release Please が自動的にバージョン管理とCHANGELOG生成

## コミットメッセージのルール

このプロジェクトでは **Conventional Commits** 形式を採用しています：

- `feat:` - 新機能（Minor バージョンアップ）
- `fix:` - バグ修正（Patch バージョンアップ）
- `docs:` - ドキュメント変更
- `chore:` - 雑用・設定変更
- `BREAKING CHANGE:` - 破壊的変更（Major バージョンアップ）

詳細は `.github/copilot-instructions.md` を参照してください。

## 技術スタック

- **コンテナ化**: Docker / Docker Compose
- **ビルドツール**: Nixpacks（Dockerfile 不要）
- **デプロイメント**: Coolify
- **ネットワーク**: Tailscale
- **ホスティング**: Raspberry Pi 4 (ARM64)
- **CI/CD**: GitHub Actions + Release Please

## ライセンス

MIT
