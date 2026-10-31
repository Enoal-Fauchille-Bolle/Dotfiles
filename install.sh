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
    atuin
    claude
    input-remapper
    systemd
    desktop
)
SECRETS_FILE="$HOME/.zshrc.secrets"
WAKATIME_KEY_FILE="$HOME/.wakatime.key"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

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

# Moves a regular file standing where a link must go out of the way. stow
# --adopt would pull it into this repository instead, overwriting the tracked
# version. -ef skips a file that already is the repository one, reached through
# a folded directory link.
backup_conflicts() {
    local pkg="$1" file relative target
    while IFS= read -r -d '' file; do
        relative="${file#"$pkg"/}"
        target="$HOME/$relative"
        if [ -f "$target" ] && [ ! -L "$target" ] && [ ! "$target" -ef "$file" ]; then
            mkdir -p "$BACKUP_DIR/$(dirname "$relative")"
            mv "$target" "$BACKUP_DIR/$relative"
            echo "📦 Moved $target to $BACKUP_DIR"
        fi
    done < <(find "$pkg" -type f -print0)
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
        backup_conflicts "$pkg"
        # -R restows (refreshes links), --no-folding links files one by one so
        # directories such as ~/.local or ~/.claude stay real directories instead
        # of links into this repository.
        stow -R --no-folding "$pkg"
    else
        echo "⚠️  Warning: $pkg not found"
    fi
done

# 3. Setup Secrets File (Local only)
if [ ! -f "$SECRETS_FILE" ]; then
    echo "🔒 Creating empty secrets file at $SECRETS_FILE..."
    (umask 077 && touch "$SECRETS_FILE")
    echo "# Place your secrets here (API Keys, Tokens, etc.)" >> "$SECRETS_FILE"
    echo "# export NPM_TOKEN='...'" >> "$SECRETS_FILE"
    echo "📝 REMINDER: Don't forget to fill $SECRETS_FILE with your actual tokens manually!"
else
    echo "🔑 Secrets file already exists. Skipping."
fi
chmod 600 "$SECRETS_FILE"

# 4. Setup WakaTime Key File (Local only)
# .wakatime.cfg reads the key through api_key_vault_cmd, so the key itself never
# lands in this repository. The file must hold the key alone, without comments.
if [ ! -f "$WAKATIME_KEY_FILE" ]; then
    echo "🔒 Creating empty WakaTime key file at $WAKATIME_KEY_FILE..."
    (umask 077 && touch "$WAKATIME_KEY_FILE")
    echo "📝 REMINDER: Paste your WakaTime API key (the key alone) into $WAKATIME_KEY_FILE!"
else
    echo "🔑 WakaTime key file already exists. Skipping."
fi

echo "✅ Done! Restart your shell."
