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
INSTALL_COOLIFY=true
INSTALL_SMEE=true
INTERACTIVE=false
SSH_KEYS_SELECTION="all"

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
  echo "  --no-coolify         Skip Coolify installation"
  echo "  --no-smee            Skip Smee.io webhook proxy setup"
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
    --no-coolify) INSTALL_COOLIFY=false ;;
    --no-smee) INSTALL_SMEE=false ;;
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
  echo "[1/9] Updating system packages..."
  sudo apt update && sudo apt upgrade -y
else
  echo "[1/9] Skipping system packages update"
fi

# Install essential tools
if should_run "Install essential tools" "$INSTALL_TOOLS"; then
  echo "[2/9] Installing essential tools..."
  sudo apt install -y curl git htop vim
else
  echo "[2/9] Skipping essential tools installation"
fi

# Configure Vim
if should_run "Configure Vim" "$INSTALL_VIM"; then
  echo "[3/9] Configuring Vim..."
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  SETUP_DIR="$(dirname "$SCRIPT_DIR")"
  if [ -f "$SETUP_DIR/.vimrc" ]; then
    cp "$SETUP_DIR/.vimrc" "$HOME/.vimrc"
    echo "  .vimrc copied to $HOME/.vimrc"
  else
    echo "  Warning: .vimrc not found in setup directory"
  fi
else
  echo "[3/9] Skipping Vim configuration"
fi

# Install GitHub CLI
if should_run "Install GitHub CLI" "$INSTALL_GH"; then
  echo "[4/9] Installing GitHub CLI..."
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
  echo "[4/9] Skipping GitHub CLI installation"
fi

# Configure Git using GitHub CLI
if should_run "Configure Git" "$INSTALL_GIT"; then
  echo "[5/9] Configuring Git..."

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
  echo "[5/9] Skipping Git configuration"
fi

# Configure SSH
if should_run "Configure SSH" "$INSTALL_SSH"; then
  echo "[6/9] Configuring SSH..."
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
  echo "[6/9] Skipping SSH configuration"
fi

# Install Tailscale
if should_run "Install Tailscale" "$INSTALL_TAILSCALE"; then
  echo "[7/9] Installing Tailscale..."
  curl -fsSL https://tailscale.com/install.sh | sh
else
  echo "[7/9] Skipping Tailscale installation"
fi

# Install Coolify
if should_run "Install Coolify" "$INSTALL_COOLIFY"; then
  echo "[8/9] Installing Coolify..."
  curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
else
  echo "[8/9] Skipping Coolify installation"
fi

# Install smee.io client
if should_run "Install Smee.io client" "$INSTALL_SMEE"; then
  echo "[9/9] Setting up smee.io webhook proxy..."

  # Check if Node.js/npm is available
  if ! command -v npm &> /dev/null; then
    echo "  Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs
  fi

  # Install smee-client
  echo "  Installing smee-client..."
  sudo npm install --global smee-client

  # Get the actual path to the smee binary
  SMEE_BIN=$(which smee 2>/dev/null || echo "/usr/local/bin/smee")
  if [ ! -x "$SMEE_BIN" ]; then
    NPM_PREFIX=$(npm prefix -g 2>/dev/null || echo "/usr/local")
    SMEE_BIN="$NPM_PREFIX/bin/smee"
  fi
  echo "  Smee binary: $SMEE_BIN"

  # Generate new smee.io channel URL
  echo "  Generating smee.io channel URL..."
  SMEE_URL=$(curl -w "%{redirect_url}" -s -o /dev/null https://smee.io/new 2>/dev/null || echo "")
  # Validate the URL format
  if [ -z "$SMEE_URL" ] || ! echo "$SMEE_URL" | grep -qE '^https://smee\.io/[A-Za-z0-9]+$'; then
    echo "  Warning: Failed to generate smee.io URL"
    echo "  Please manually generate a URL at https://smee.io/new"
    SMEE_URL="https://smee.io/YOUR_CHANNEL_URL"
  fi
  echo "  Smee URL: $SMEE_URL"

  # Create systemd service file
  # Note: Port 8000 is where Coolify runs - smee forwards webhooks there
  # Note: Running as root per original specification; consider using a less privileged user
  echo "  Creating systemd service..."
  sudo tee /etc/systemd/system/smee.service > /dev/null << EOF
[Unit]
Description=Smee Client
After=network.target

[Service]
Type=simple
User=root
Restart=always
ExecStart=$SMEE_BIN --url $SMEE_URL --path /webhooks/source/github/events --port 8000

[Install]
WantedBy=multi-user.target
EOF

  # Enable and start the service
  sudo systemctl daemon-reload
  sudo systemctl enable smee
  echo "  Smee service enabled (not started - update URL first if placeholder)"
else
  echo "[9/9] Skipping Smee.io setup"
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
  echo "[Smee.io Webhook Proxy]"
  echo "  URL: $SMEE_URL"
  echo "  Service file: /etc/systemd/system/smee.service"
  echo "  Target: localhost:8000/webhooks/source/github/events"
  echo ""
  echo "[Coolify]"
  echo "  URL: http://localhost:8000"
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
  echo "=========================================="
  echo "Next Steps"
  echo "=========================================="
  echo ""
  echo "1. Run 'sudo tailscale up' to join the Tailscale network"
  echo "2. Access Coolify at http://localhost:8000"
  echo "3. If smee.io URL is a placeholder, update /etc/systemd/system/smee.service"
  echo "   with a valid URL from https://smee.io/new, then run:"
  echo "     sudo systemctl daemon-reload && sudo systemctl restart smee"
  echo "4. In Coolify, configure the GitHub webhook to use the smee.io URL above"
  echo ""
} > "$LOG_FILE"

echo "  Log file created: $LOG_FILE"
echo ""
echo "Next steps:"
echo "  1. Run 'sudo tailscale up' to join the Tailscale network"
echo "  2. Access Coolify at http://localhost:8000"
echo "  3. If smee.io URL is a placeholder, update /etc/systemd/system/smee.service"
echo "     with a valid URL from https://smee.io/new, then run:"
echo "       sudo systemctl daemon-reload && sudo systemctl restart smee"
echo ""
echo "Configuration saved to: $LOG_FILE"
echo ""
