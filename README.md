# Pi Dev Toolkit

**複数の Raspberry Pi を IoT ノードとして立ち上げるための、最小限の初期セットアップスクリプト**

システム更新・基本ツール・Tailscale（メッシュVPN）・GitHub連携（gh/git/SSH）・uv・
Claude Code / GitHub Copilot CLI・[agy_bootstrapper](https://github.com/ponderingm/agy_bootstrapper) など、
どのノードにも共通して必要な最低限の環境構築だけを行います。

個々のプロジェクトのひな形（Docker Compose / Coolifyデプロイ / Claude Code連携など）は
このリポジトリの範囲外。必要な場合は [vibe-dev-template-claude](https://github.com/ponderingm/vibe-dev-template-claude)
（別リポジトリ、private）を使ってください。

### 対象環境

- **対象:** Raspberry Pi 4 (ARM64)
- **OS:** Raspberry Pi OS Lite (64-bit)
- **ネットワーク:** Tailscale（メッシュVPNで複数ノードをプライベートに接続）

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
- `--no-nodejs` / `--no-claude-code` / `--no-copilot-cli`: 各AI CLIのインストールをスキップ
- `--no-agy-bootstrapper`: agy_bootstrapper（+ 非公開プロファイル）のセットアップをスキップ
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
- **uv のインストール**（Python パッケージ管理ツール）
- Node.js のインストール（Copilot CLI に必要）
- **Claude Code** のインストール
- **GitHub Copilot CLI** のインストール
- **agy_bootstrapper** のセットアップ（public な本体をclone し、
  `install.sh --profiles-repo=` 経由で非公開の
  [agy-profiles-private](https://github.com/ponderingm/agy-profiles-private) から
  本命のペルソナ・ロールをシンボリックリンクで差し込む）

セットアップ後は `cldp` 等のいつも通りのエイリアスでセッションを起動するだけでよい。
本命のペルソナ・ロールがシンボリックリンクされている場合、`run_partner.py` が
セッション前後で自動的にpull/pushするため、複数マシン間で `memories.md` 等の状態が
ズレる心配はない（agy_bootstrapper 側の機能。詳細は
[agy_bootstrapper の README](https://github.com/ponderingm/agy_bootstrapper/blob/main/README.md)
の「非公開プロファイル」を参照）。

### 2. 新規プロジェクトを作る（任意）

Pi本体のセットアップが終わったら、個々のプロジェクトは
[vibe-dev-template-claude](https://github.com/ponderingm/vibe-dev-template-claude) の
**Use this template** ボタンから作成できます（Docker Compose / Coolifyデプロイ（オプション）/
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

1. `setup/scripts/setup.sh` で Pi 本体（IoTノード）をセットアップ
2. 必要なら [vibe-dev-template-claude](https://github.com/ponderingm/vibe-dev-template-claude) から個々のプロジェクトを作成
3. このリポジトリ自体への変更は Conventional Commits 形式でコミット
4. `main` への push で Continuous Release ワークフローが自動的にバージョンタグ・GitHub Releaseを作成

## コミットメッセージのルール

このプロジェクトでは **Conventional Commits** 形式を採用しています：

- `feat:` - 新機能（Minor バージョンアップ）
- `fix:` - バグ修正（Patch バージョンアップ）
- `docs:` - ドキュメント変更
- `chore:` - 雑用・設定変更
- `BREAKING CHANGE:` - 破壊的変更（Major バージョンアップ）

詳細は `.github/copilot-instructions.md` を参照してください。

## 技術スタック

- **Python パッケージ管理**: uv
- **AI CLI**: Claude Code, GitHub Copilot CLI
- **AIパートナー起動基盤**: [agy_bootstrapper](https://github.com/ponderingm/agy_bootstrapper)
- **ネットワーク**: Tailscale
- **ホスティング**: Raspberry Pi 4 (ARM64)
- **CI/CD**: GitHub Actions + Continuous Release

## agy_bootstrapper の公開/非公開の分け方

[agy_bootstrapper](https://github.com/ponderingm/agy_bootstrapper) 本体は public。
`personas/*`（`sample/` を除く）と `roles/private_*/` は本体側の `.gitignore` で
保護されているが、それだけだと本命のペルソナ・ロールがどのマシンにも同期されない。

そこで [agy-profiles-private](https://github.com/ponderingm/agy-profiles-private)
（private、同じディレクトリ構造）に本命データだけを分離して置き、`setup.sh` が
agy_bootstrapper のチェックアウトへシンボリックリンクで差し込む。詳細は
[agy-profiles-private の README](https://github.com/ponderingm/agy-profiles-private/blob/main/README.md)
を参照。

## ライセンス

MIT
