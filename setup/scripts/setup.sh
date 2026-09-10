#!/bin/bash
set -e


# Default settings (true = install/configure)
INSTALL_UPDATE=true
INSTALL_TOOLS=true
INSTALL_VIM=true
INSTALL_GH=true
INSTALL_GIT=true
INSTALL_SSH=true
INSTALL_TAILSCALE=true
INSTALL_UV=true
INSTALL_NODEJS=true
INSTALL_CLAUDE_CODE=true
INSTALL_COPILOT_CLI=true
INSTALL_AGY_BOOTSTRAPPER=true
INTERACTIVE=false
SSH_KEYS_SELECTION="all"

# agy_bootstrapper / 非公開プロファイル関連の設定値
NODE_MAJOR_VERSION=22
AGY_BOOTSTRAPPER_REPO="ponderingm/agy_bootstrapper"
AGY_PROFILES_REPO="ponderingm/agy-profiles-private"
AGY_INSTALL_DIR="$HOME/agy_bootstrapper"
AGY_PROFILES_DIR="$HOME/agy-profiles-private"
AGY_ENGINES="claude,copilot"
AGY_YOLO_MODE=false

# Help message
usage() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -i, --interactive    Enable interactive mode (prompt for each step)"
  echo "  --no-update          Skip system update"
  echo "  --no-tools           Skip essential tools installation"
  echo "  --no-vim             Skip Vim configuration"
  echo "  --no-gh              Skip GitHub CLI installation"
  echo "  --no-git             Skip Git configuration"
  echo "  --no-ssh             Skip SSH configuration"
  echo "  --no-tailscale       Skip Tailscale installation"
  echo "  --no-uv              Skip uv (Python package manager) installation"
  echo "  --no-nodejs          Skip Node.js installation"
  echo "  --no-claude-code     Skip Claude Code installation"
  echo "  --no-copilot-cli     Skip GitHub Copilot CLI installation"
  echo "  --no-agy-bootstrapper Skip agy_bootstrapper (+ private profiles) setup"
  echo "  --ssh-keys <indices> Specify GitHub public key indices to import (e.g., '1,3' or 'all')"
  echo "  -h, --help           Show this help message"
  exit 1
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -i|--interactive) INTERACTIVE=true ;;
    --no-update) INSTALL_UPDATE=false ;;
    --no-tools) INSTALL_TOOLS=false ;;
    --no-vim) INSTALL_VIM=false ;;
    --no-gh) INSTALL_GH=false ;;
    --no-git) INSTALL_GIT=false ;;
    --no-ssh) INSTALL_SSH=false ;;
    --no-tailscale) INSTALL_TAILSCALE=false ;;
    --no-uv) INSTALL_UV=false ;;
    --no-nodejs) INSTALL_NODEJS=false ;;
    --no-claude-code) INSTALL_CLAUDE_CODE=false ;;
    --no-copilot-cli) INSTALL_COPILOT_CLI=false ;;
    --no-agy-bootstrapper) INSTALL_AGY_BOOTSTRAPPER=false ;;
    --ssh-keys) SSH_KEYS_SELECTION="$2"; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown parameter passed: $1"; usage ;;
  esac
  shift
done

# Function to prompt user
should_run() {
  local step_name="$1"
  local default_var="$2"
  
  # If explicitly disabled via flag, return false (1)
  if [ "$default_var" = false ]; then
    return 1
  fi
  
  # If interactive, prompt user
  if [ "$INTERACTIVE" = true ]; then
    read -p "Run step: $step_name? [Y/n] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]]; then
      return 1
    fi
  fi
  
  return 0
}

echo "=========================================="
echo "Raspberry Pi Dev Environment Setup"
echo "=========================================="

# Update system packages
if should_run "Update system packages" "$INSTALL_UPDATE"; then
  echo "[1/12] Updating system packages..."
  sudo apt update && sudo apt upgrade -y
else
  echo "[1/12] Skipping system packages update"
fi

# Install essential tools
if should_run "Install essential tools" "$INSTALL_TOOLS"; then
  echo "[2/12] Installing essential tools..."
  sudo apt install -y curl git htop vim
else
  echo "[2/12] Skipping essential tools installation"
fi

# Configure Vim
if should_run "Configure Vim" "$INSTALL_VIM"; then
  echo "[3/12] Configuring Vim..."
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  SETUP_DIR="$(dirname "$SCRIPT_DIR")"
  if [ -f "$SETUP_DIR/.vimrc" ]; then
    cp "$SETUP_DIR/.vimrc" "$HOME/.vimrc"
    echo "  .vimrc copied to $HOME/.vimrc"
  else
    echo "  Warning: .vimrc not found in setup directory"
  fi
else
  echo "[3/12] Skipping Vim configuration"
fi

# Install GitHub CLI
if should_run "Install GitHub CLI" "$INSTALL_GH"; then
  echo "[4/12] Installing GitHub CLI..."
  if ! command -v gh &> /dev/null; then
    # Add GitHub CLI official repository
    # Install wget if missing
    if ! type -p wget >/dev/null; then
      sudo apt update && sudo apt install wget -y
    fi
    
    # Create keyring directory
    sudo mkdir -p -m 755 /etc/apt/keyrings
    
    # Download and install GPG key
    out=$(mktemp)
    if wget -nv -O "$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg; then
      sudo cp "$out" /etc/apt/keyrings/githubcli-archive-keyring.gpg
      rm -f "$out"
      sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    else
      rm -f "$out"
      echo "  Error: Failed to download GitHub CLI keyring"
      exit 1
    fi
    
    # Add APT repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    
    # Install GitHub CLI
    sudo apt update
    sudo apt install gh -y
    echo "  GitHub CLI installed"
  else
    echo "  GitHub CLI already installed"
  fi
else
  echo "[4/12] Skipping GitHub CLI installation"
fi

# Configure Git using GitHub CLI
if should_run "Configure Git" "$INSTALL_GIT"; then
  echo "[5/12] Configuring Git..."

  # Check GitHub auth status
  if gh auth status &>/dev/null; then
    echo "  GitHub CLI already authenticated"
  else
    echo "  Authenticating with GitHub CLI..."
    gh auth login
  fi

  # Fetch user info from GitHub and configure Git
  if gh auth status &>/dev/null; then
    # Get and set username
    gh_username=$(gh api user --jq '.login' 2>/dev/null || echo "")
    if [ -n "$gh_username" ]; then
      current_name=$(git config --global user.name 2>/dev/null || echo "")
      if [ "$current_name" != "$gh_username" ]; then
        git config --global user.name "$gh_username"
        echo "  Set Git user.name to '$gh_username' (from GitHub)"
      else
        echo "  Git user.name already set to '$gh_username'"
      fi
    else
      # Default when username cannot be fetched from GitHub
      git config --global user.name "pi"
      echo "  Set Git user.name to 'pi' (default)"
    fi
    
    # Get and set email (avoid setting JSON error payload)
    # 1) Public email (/user.email)
    gh_public_email=$(gh api user --jq '.email' --silent 2>/dev/null || echo "")
    # 2) Primary email (/user/emails; requires user:email scope). Validate to avoid JSON
    gh_primary_email=$(gh api user/emails --jq '.[] | select(.primary == true) | .email' --silent 2>/dev/null || echo "")

    # Basic email format validation to reject JSON-like strings
    is_valid_email() {
      echo "$1" | grep -E '^[^@\s]+@[^@\s]+\.[^@\s]+$' >/dev/null 2>&1
    }

    gh_email=""
    # GitHubからユーザー名が取得できない場合はメールもデフォルト設定
    if [ -z "$gh_username" ]; then
      gh_email="raspberry@example.com"
    fi
    if [ -n "$gh_public_email" ] && is_valid_email "$gh_public_email"; then
      gh_email="$gh_public_email"
    elif [ -n "$gh_primary_email" ] && is_valid_email "$gh_primary_email"; then
      gh_email="$gh_primary_email"
    else
      # 3) Fallback: generate noreply address
      gh_id=$(gh api user --jq '.id' --silent 2>/dev/null || echo "")
      if [ -n "$gh_id" ] && [ -n "$gh_username" ]; then
        gh_email="${gh_id}+${gh_username}@users.noreply.github.com"
      fi
    fi

    if [ -n "$gh_email" ] && is_valid_email "$gh_email"; then
      current_email=$(git config --global user.email 2>/dev/null || echo "")
      if [ "$current_email" != "$gh_email" ]; then
        git config --global user.email "$gh_email"
        if [ "$gh_email" = "raspberry@example.com" ]; then
          echo "  Set Git user.email to 'raspberry@example.com' (default)"
        else
          echo "  Set Git user.email to '$gh_email' (from GitHub)"
        fi
      else
        if [ "$gh_email" = "raspberry@example.com" ]; then
          echo "  Git user.email already set to 'raspberry@example.com'"
        else
          echo "  Git user.email already set to '$gh_email'"
        fi
      fi
    else
      echo "  Warning: Failed to get a valid email from GitHub."
      echo "           If username was not fetched, default 'raspberry@example.com' will be used."
      if [ -z "$gh_email" ]; then
        gh_email="raspberry@example.com"
        git config --global user.email "$gh_email"
        echo "  Set Git user.email to 'raspberry@example.com' (default)"
      else
        echo "           Please set 'git config --global user.email <your-email>' manually"
      fi
    fi
  else
    echo "  Warning: GitHub CLI not authenticated; skipping Git configuration"
    echo "  Run 'gh auth login' and re-run this script later"
  fi
else
  echo "[5/12] Skipping Git configuration"
fi

# Configure SSH
if should_run "Configure SSH" "$INSTALL_SSH"; then
  echo "[6/12] Configuring SSH..."
  ssh_key_path="$HOME/.ssh/id_ed25519"
  if [ -f "$ssh_key_path" ]; then
    echo "  SSH key already exists: $ssh_key_path"
  else
    echo "  Generating new SSH key (Ed25519)..."
    # Use the email determined in the Git configuration step, or default
    if [ -z "$gh_email" ]; then
      gh_email="raspberry@example.com"
    fi
    ssh-keygen -t ed25519 -C "$gh_email" -f "$ssh_key_path" -N ""
    echo "  SSH key generated"
  fi

  # Import GitHub public keys to authorized_keys
  if [ -n "$gh_username" ]; then
    echo "  Importing public keys from GitHub for user '$gh_username'..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    
    # Fetch keys to temp file
    keys_tmp=$(mktemp)
    if curl -s "https://github.com/${gh_username}.keys" > "$keys_tmp"; then
      # Read keys into array (mapfile is bash 4.0+)
      mapfile -t keys < "$keys_tmp"
      rm -f "$keys_tmp"
      
      if [ ${#keys[@]} -eq 0 ]; then
        echo "  Warning: No public keys found for user '$gh_username'"
      else
        # Determine selection
        if [ "$INTERACTIVE" = true ] && [ "$SSH_KEYS_SELECTION" = "all" ]; then
          echo "  Available SSH keys for $gh_username:"
          for i in "${!keys[@]}"; do
            # Show first 50 chars of key for brevity
            key_preview=$(echo "${keys[$i]}" | cut -c 1-50)
            echo "    [$((i+1))] $key_preview..."
          done
          echo "    [a] All"
          echo "    [n] None"
          read -p "  Select keys to import (comma-separated indices, e.g., '1,3' or 'a'): " selection
          if [ "$selection" = "a" ] || [ "$selection" = "A" ] || [ -z "$selection" ]; then
            SSH_KEYS_SELECTION="all"
          elif [ "$selection" = "n" ] || [ "$selection" = "N" ]; then
             SSH_KEYS_SELECTION="none"
          else
            SSH_KEYS_SELECTION="$selection"
          fi
        fi
        
        # Process selection
        if [ "$SSH_KEYS_SELECTION" = "all" ]; then
          for key in "${keys[@]}"; do
            echo "$key" >> "$HOME/.ssh/authorized_keys"
          done
          echo "  Imported all ${#keys[@]} keys."
        elif [ "$SSH_KEYS_SELECTION" != "none" ]; then
          IFS=',' read -ra ADDR <<< "$SSH_KEYS_SELECTION"
          for i in "${ADDR[@]}"; do
            # Adjust 1-based index to 0-based
            idx=$((i-1))
            if [ -n "${keys[$idx]}" ]; then
              echo "${keys[$idx]}" >> "$HOME/.ssh/authorized_keys"
              echo "  Imported key #$i"
            else
              echo "  Warning: Invalid key index '$i'"
            fi
          done
        else
          echo "  Skipped importing keys."
        fi
        
        chmod 600 "$HOME/.ssh/authorized_keys"
      fi
    else
      echo "  Warning: Failed to fetch public keys from GitHub"
      rm -f "$keys_tmp"
    fi
  else
    echo "  Skipping GitHub public key import (username not found)"
  fi

  # Upload SSH key to GitHub
  if gh auth status &>/dev/null; then
    echo "  Uploading SSH key to GitHub..."
    # Check if key is already uploaded (simple check by title or key content is hard, so we just try add and ignore error if duplicate)
    if gh ssh-key add "$ssh_key_path.pub" --title "Pi Dev Toolkit ($(hostname))" 2>/dev/null; then
      echo "  SSH key uploaded to GitHub"
    else
      echo "  Warning: Failed to upload SSH key (it might already exist)"
    fi
  else
    echo "  Skipping GitHub SSH key upload (not authenticated)"
  fi
else
  echo "[6/12] Skipping SSH configuration"
fi

# Install Tailscale
if should_run "Install Tailscale" "$INSTALL_TAILSCALE"; then
  echo "[7/12] Installing Tailscale..."
  curl -fsSL https://tailscale.com/install.sh | sh
else
  echo "[7/12] Skipping Tailscale installation"
fi

# Install uv (Python package manager)
if should_run "Install uv" "$INSTALL_UV"; then
  echo "[8/12] Installing uv (Python package manager)..."
  if command -v uv &> /dev/null; then
    echo "  uv already installed: $(uv --version)"
  else
    curl -LsSf https://astral.sh/uv/install.sh | sh
    echo "  uv installed"
    echo "  Note: Restart your shell or run 'source $HOME/.local/bin/env' to use uv"
  fi
else
  echo "[8/12] Skipping uv installation"
fi

# Install Node.js (required by GitHub Copilot CLI)
if should_run "Install Node.js" "$INSTALL_NODEJS"; then
  echo "[9/12] Installing Node.js..."
  current_node_major=$(node -v 2>/dev/null | sed 's/^v//' | cut -d. -f1)
  if [ -n "$current_node_major" ] && [ "$current_node_major" -ge "$NODE_MAJOR_VERSION" ]; then
    echo "  Node.js already installed: $(node -v)"
  else
    curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR_VERSION}.x" | sudo -E bash -
    sudo apt install -y nodejs
    echo "  Node.js installed: $(node -v)"
  fi
else
  echo "[9/12] Skipping Node.js installation"
fi

# Install Claude Code
if should_run "Install Claude Code" "$INSTALL_CLAUDE_CODE"; then
  echo "[10/12] Installing Claude Code..."
  if command -v claude &> /dev/null; then
    echo "  Claude Code already installed"
  else
    curl -fsSL https://claude.ai/install.sh | bash
    echo "  Claude Code installed"
  fi
else
  echo "[10/12] Skipping Claude Code installation"
fi

# Install GitHub Copilot CLI
if should_run "Install GitHub Copilot CLI" "$INSTALL_COPILOT_CLI"; then
  echo "[11/12] Installing GitHub Copilot CLI..."
  if command -v copilot &> /dev/null; then
    echo "  GitHub Copilot CLI already installed"
  elif command -v npm &> /dev/null; then
    npm install -g @github/copilot
    echo "  GitHub Copilot CLI installed"
  else
    echo "  Warning: npm not found; skipping GitHub Copilot CLI installation"
  fi
else
  echo "[11/12] Skipping GitHub Copilot CLI installation"
fi

# Install agy_bootstrapper (+ private personas/roles from agy-profiles-private)
if should_run "Install agy_bootstrapper" "$INSTALL_AGY_BOOTSTRAPPER"; then
  echo "[12/12] Installing agy_bootstrapper..."

  if [ -d "$AGY_INSTALL_DIR/.git" ]; then
    echo "  agy_bootstrapper already cloned: $AGY_INSTALL_DIR"
  else
    git clone "https://github.com/${AGY_BOOTSTRAPPER_REPO}.git" "$AGY_INSTALL_DIR"
  fi

  if gh auth status &>/dev/null; then
    if [ -d "$AGY_PROFILES_DIR/.git" ]; then
      echo "  agy-profiles-private already cloned: $AGY_PROFILES_DIR"
    else
      gh repo clone "$AGY_PROFILES_REPO" "$AGY_PROFILES_DIR"
    fi

    # Link private personas/roles into the agy_bootstrapper checkout
    # (agy_bootstrapper's own personas/.gitignore and roles/.gitignore already
    # exclude these paths, so symlinking here never risks a public commit)
    for d in "$AGY_PROFILES_DIR"/personas/*/; do
      [ -d "$d" ] || continue
      persona_name="$(basename "$d")"
      ln -sfn "$d" "$AGY_INSTALL_DIR/personas/$persona_name"
      echo "  Linked persona: $persona_name"
    done
    for d in "$AGY_PROFILES_DIR"/roles/*/; do
      [ -d "$d" ] || continue
      role_name="$(basename "$d")"
      ln -sfn "$d" "$AGY_INSTALL_DIR/roles/$role_name"
      echo "  Linked role: $role_name"
    done

    # Register 'agysync' shell function: wraps sessions with pull-before/push-after
    # so personas/roles state (memories.md etc.) stays in sync across machines.
    if [ -f "$AGY_PROFILES_DIR/sync-and-run.sh" ] && [ -f "$HOME/.bashrc" ] \
      && ! grep -q "PI_DEV_TOOLKIT AGYSYNC START" "$HOME/.bashrc"; then
      {
        echo ""
        echo "# === PI_DEV_TOOLKIT AGYSYNC START ==="
        echo "agysync() {"
        echo "  \"$AGY_PROFILES_DIR/sync-and-run.sh\" \"\$@\""
        echo "}"
        echo "# === PI_DEV_TOOLKIT AGYSYNC END ==="
      } >> "$HOME/.bashrc"
      echo "  Registered 'agysync' shell function in ~/.bashrc"
    fi
  else
    echo "  Warning: GitHub CLI not authenticated; skipping private profiles ($AGY_PROFILES_REPO)"
  fi

  if [ -f "$AGY_INSTALL_DIR/install.sh" ]; then
    agy_yolo_flag="--no-yolo"
    if [ "$AGY_YOLO_MODE" = true ]; then
      agy_yolo_flag="--yolo"
    fi
    bash "$AGY_INSTALL_DIR/install.sh" "--engine=$AGY_ENGINES" "$agy_yolo_flag"
  fi
else
  echo "[12/12] Skipping agy_bootstrapper installation"
fi

echo ""
echo "=========================================="
echo "Setup complete!"
echo "=========================================="

# Generate setup log file
LOG_FILE="$HOME/pi-dev-toolkit-setup.log"
SETUP_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo ""
echo "Generating setup log file: $LOG_FILE"

{
  echo "=========================================="
  echo "Pi Dev Toolkit Setup Log"
  echo "=========================================="
  echo ""
  echo "Setup completed at: $SETUP_TIMESTAMP"
  echo ""
  echo "=========================================="
  echo "Important Configuration"
  echo "=========================================="
  echo ""
  echo "[Git Configuration]"
  echo "  user.name: $(git config --global user.name 2>/dev/null || echo 'not set')"
  echo "  user.email: $(git config --global user.email 2>/dev/null || echo 'not set')"
  echo ""
  echo "[SSH Configuration]"
  echo "  Key path: $ssh_key_path"
  echo "  Public key: $ssh_key_path.pub"
  echo "  Authorized keys: Imported from GitHub user '$gh_username'"
  echo ""
  echo "[Tailscale]"
  echo "  Run 'sudo tailscale up' to join the network"
  echo "  Run 'tailscale status' to check connection status"
  echo ""
  echo "[uv (Python package manager)]"
  echo "  Version: $(uv --version 2>/dev/null || echo 'not installed')"
  echo "  Install path: $HOME/.local/bin/uv"
  echo "  Shell env: source $HOME/.local/bin/env"
  echo ""
  echo "[AI CLIs]"
  echo "  Node.js: $(node -v 2>/dev/null || echo 'not installed')"
  echo "  Claude Code: $(command -v claude &>/dev/null && echo 'installed' || echo 'not installed')"
  echo "  GitHub Copilot CLI: $(command -v copilot &>/dev/null && echo 'installed' || echo 'not installed')"
  echo ""
  echo "[agy_bootstrapper]"
  echo "  Install dir: $AGY_INSTALL_DIR"
  echo "  Private profiles: $AGY_PROFILES_DIR"
  echo "  Engines: $AGY_ENGINES"
  echo "  Cross-machine sync: run sessions via 'agysync <command...>' (see agy-profiles-private/README.md)"
  echo ""
  echo "=========================================="
  echo "Next Steps"
  echo "=========================================="
  echo ""
  echo "1. Run 'sudo tailscale up' to join the Tailscale network"
  echo "2. Run 'source ~/.bashrc' to load agy_bootstrapper/agysync shortcut commands"
  echo "3. Run 'claude' / 'copilot' once each to complete their login"
  echo "4. Launch persona sessions via 'agysync <command...>', not the raw alias,"
  echo "   so memories.md etc. stay in sync across machines"
  echo ""
} > "$LOG_FILE"

echo "  Log file created: $LOG_FILE"
echo ""
echo "Next steps:"
echo "  1. Run 'sudo tailscale up' to join the Tailscale network"
echo "  2. Run 'source ~/.bashrc' to load agy_bootstrapper/agysync shortcut commands"
echo "  3. Run 'claude' / 'copilot' once each to complete their login"
echo "  4. Launch persona sessions via 'agysync <command...>', not the raw alias,"
echo "     so memories.md etc. stay in sync across machines"
echo ""
echo "Configuration saved to: $LOG_FILE"
echo ""
