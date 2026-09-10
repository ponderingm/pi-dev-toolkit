# Pi Dev Toolkit

**Raspberry Pi 4 の初期セットアップ専用シェルスクリプト集**

Coolify・Tailscale を含む、開発・デプロイワークフローの土台となる Pi 本体の環境構築を行います。

新規プロジェクトのひな形（Docker Compose / Nixpacks / Coolifyデプロイ / Claude Code連携）は
このリポジトリの範囲外。[vibe-dev-template-claude](https://github.com/ponderingm/vibe-dev-template-claude)
（別リポジトリ、private）を使ってください。

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

**オプション:**
- `-i`, `--interactive`: 対話モード（ステップごとに確認）
- `--no-tailscale`: Tailscale のインストールをスキップ（例）
- `--no-uv`: uv のインストールをスキップ
- `--ssh-keys "1,2"`: GitHub からインポートする公開鍵を指定
- その他のオプションは `bash setup/scripts/setup.sh --help` で確認できます。

セットアップスクリプトは以下を実行します：
- システムパッケージの更新
- 必須ツールのインストール（curl, git, vim, htop）
- Vim 設定ファイル (`.vimrc`) のホームディレクトリへのコピー
- GitHub CLI のインストールと認証
- Git の設定（GitHub から自動取得したユーザー名・メールアドレス）
- **SSH の設定**（鍵の生成、GitHub へのアップロード、クライアント公開鍵のインポート）
- Tailscale のインストール
- Coolify のインストール
- smee.io クライアントのインストールと Webhook プロキシの設定
- **uv のインストール**（Python パッケージ管理ツール）

### 2. 新規プロジェクトを作る

Pi本体のセットアップが終わったら、個々のプロジェクトは
[vibe-dev-template-claude](https://github.com/ponderingm/vibe-dev-template-claude) の
**Use this template** ボタンから作成してください（Docker Compose / Nixpacks / Coolifyデプロイ /
Claude Code連携がひな形として入っています）。

## プロジェクト構成

```
pi-dev-toolkit/
├── .github/                      # このリポジトリ自体の設定
│   ├── copilot-instructions.md   # 汎用的な開発ガイドライン
│   ├── local-instruction.md      # Pi Dev Toolkit の思想
│   └── workflows/
│       └── release.yml           # Continuous Release 設定
├── setup/                        # Raspberry Pi セットアップツール
│   ├── .vimrc                    # Vim 設定ファイル
│   ├── .vscode/                  # VS Code 設定
│   └── scripts/
│       └── setup.sh              # セットアップスクリプト
├── .editorconfig                 # エディタ設定
├── .gitignore                    # Git 除外ルール
└── README.md                     # このファイル
```

## 開発ワークフロー

1. `setup/scripts/setup.sh` で Pi 本体をセットアップ
2. [vibe-dev-template-claude](https://github.com/ponderingm/vibe-dev-template-claude) から新規プロジェクトを作成
3. Conventional Commits 形式でコミット
4. GitHub にプッシュ
5. Coolify が自動的に Raspberry Pi にデプロイ
6. Continuous Release ワークフローが自動的にバージョンタグ・GitHub Releaseを作成

## コミットメッセージのルール

このプロジェクトでは **Conventional Commits** 形式を採用しています：

- `feat:` - 新機能（Minor バージョンアップ）
- `fix:` - バグ修正（Patch バージョンアップ）
- `docs:` - ドキュメント変更
- `chore:` - 雑用・設定変更
- `BREAKING CHANGE:` - 破壊的変更（Major バージョンアップ）

詳細は `.github/copilot-instructions.md` を参照してください。

## 技術スタック

- **デプロイメント基盤**: Coolify
- **Python パッケージ管理**: uv
- **ネットワーク**: Tailscale
- **ホスティング**: Raspberry Pi 4 (ARM64)
- **CI/CD**: GitHub Actions + Continuous Release

## ライセンス

MIT
