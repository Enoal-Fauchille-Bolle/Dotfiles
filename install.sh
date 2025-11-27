#!/bin/bash
# install.sh - Automates dotfiles installation with GNU Stow

# Variables
DOTFILES_DIR="$HOME/Dotfiles"
PACKAGES=(
    zsh
    git
    clang-format
    npm
    wakatime
    ssh
    scripts
    nix
)
SECRETS_FILE="$HOME/.zshrc.secrets"

# Function to detect OS and install stow
install_stow() {
    if [ -f /etc/fedora-release ]; then
        echo "📦 Fedora detected. Installing stow..."
        sudo dnf install -y stow
    elif [ -f /etc/debian_version ]; then
        echo "📦 Debian/Ubuntu detected. Installing stow..."
        sudo apt-get update && sudo apt-get install -y stow
    fi
}

# Main execution
echo "🚀 Starting dotfiles setup..."

# 1. Install Stow if missing
if ! command -v stow &> /dev/null; then
    install_stow
fi

# 2. Run Stow for each package
cd "$DOTFILES_DIR" || exit
for pkg in "${PACKAGES[@]}"; do
    if [ -d "$pkg" ]; then
        echo "🔗 Stowing $pkg..."
        stow -R "$pkg" --adopt # -R ensures restow (refresh links), --adopt takes over existing files
    else
        echo "⚠️  Warning: $pkg not found"
    fi
done

# 3. Setup Secrets File (Local only)
if [ ! -f "$SECRETS_FILE" ]; then
    echo "🔒 Creating empty secrets file at $SECRETS_FILE..."
    touch "$SECRETS_FILE"
    echo "# Place your secrets here (API Keys, Tokens, etc.)" >> "$SECRETS_FILE"
    echo "# export NPM_TOKEN='...'" >> "$SECRETS_FILE"
    echo "📝 REMINDER: Don't forget to fill $SECRETS_FILE with your actual tokens manually!"
else
    echo "🔑 Secrets file already exists. Skipping."
fi

echo "✅ Done! Restart your shell."
