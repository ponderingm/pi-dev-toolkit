# pi-dev-toolkit

Template repository for Raspberry Pi development environment with Coolify and Tailscale.

## Overview

- **Target:** Raspberry Pi 4 (ARM64)
- **OS:** Raspberry Pi OS Lite (64-bit)
- **Infrastructure:** Coolify (PaaS), Tailscale (Mesh VPN)
- **Workflow:** Local PC (Docker Compose) → Git Push → Coolify Auto Deploy

## Quick Start

### 1. Use as Template

Click "Use this template" on GitHub to create a new repository based on this template.

### 2. Raspberry Pi Setup

Run the setup script on your Raspberry Pi:

```bash
curl -fsSL https://raw.githubusercontent.com/<your-username>/pi-dev-toolkit/main/scripts/setup.sh | bash
```

Or clone and run locally:

```bash
git clone https://github.com/<your-username>/pi-dev-toolkit.git
cd pi-dev-toolkit
chmod +x scripts/setup.sh
sudo ./scripts/setup.sh
```

### 3. Local Development

1. Copy the environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `compose.yaml` and uncomment the language configuration you need (Node.js, Python, or Go).

3. Start the development container:
   ```bash
   docker compose up
   ```

## Project Structure

```
pi-dev-toolkit/
├── .editorconfig        # Editor standardization
├── .env.example         # Environment variables template
├── .gitignore           # Git ignore rules
├── .vimrc               # Vim configuration
├── .vscode/             # VS Code settings
│   ├── extensions.json  # Recommended extensions
│   └── settings.json    # Editor settings
├── compose.yaml         # Docker Compose for local development
├── docs/
│   └── ai_instruction.md # AI assistant instructions
├── nixpacks.toml        # Coolify/Nixpacks configuration
├── README.md            # This file
└── scripts/
    └── setup.sh         # Raspberry Pi setup script
```

## Development Workflow

1. Develop locally using Docker Compose
2. Push to GitHub
3. Coolify automatically deploys to Raspberry Pi

## License

MIT
