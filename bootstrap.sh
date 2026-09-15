#!/bin/bash
# bootstrap.sh - Rebuilds the workstation from a fresh Debian 13 install.
#
# Run it as the regular user (member of sudo), from a terminal inside the
# desktop session so that GNOME settings apply live:
#
#   curl -fsSL https://raw.githubusercontent.com/Enoal-Fauchille-Bolle/Dotfiles/main/bootstrap.sh | bash
#
# It installs git and Ansible, clones this repository into ~/Dotfiles when it
# is not there yet, then runs the playbook. Extra arguments are passed to
# ansible-playbook (for example: --tags desktop, or --skip-tags flatpak_apps).
set -euo pipefail

DOTFILES_DIR="$HOME/Dotfiles"
DOTFILES_REPO="https://github.com/Enoal-Fauchille-Bolle/Dotfiles.git"

if [ "$(id -u)" -eq 0 ]; then
    echo "❌ Run this script as your regular user, not as root." >&2
    exit 1
fi

echo "📦 Installing git and Ansible..."
sudo apt-get update
sudo apt-get install -y git ansible

if [ ! -d "$DOTFILES_DIR" ]; then
    echo "⬇️  Cloning the dotfiles into $DOTFILES_DIR..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

# Ask for the sudo password only when sudo actually needs one.
ASK_PASS=()
if ! sudo -n true 2>/dev/null; then
    ASK_PASS=(--ask-become-pass)
fi

echo "🚀 Running the playbook..."
cd "$DOTFILES_DIR/ansible"
ansible-playbook "${ASK_PASS[@]}" playbooks/all.yml "$@"

echo "✅ Done. Log out and back in so the shell, groups and GNOME extensions take effect."
