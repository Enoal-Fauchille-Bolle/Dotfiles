#!/bin/bash
# bootstrap.sh - Rebuilds the workstation from a fresh Debian 13 install.
#
# Run it as the regular user (member of sudo), from a terminal inside the
# desktop session so that GNOME settings apply live:
#
#   curl -fsSL https://raw.githubusercontent.com/Enoal-Fauchille-Bolle/Dotfiles/main/bootstrap.sh | bash
#   wget -qO- https://raw.githubusercontent.com/Enoal-Fauchille-Bolle/Dotfiles/main/bootstrap.sh | bash
#
# It refuses anything that is not Debian 13 with a working sudo, installs git
# and Ansible, clones this repository into ~/Dotfiles when it is not there yet,
# then runs the playbook. The sudo password is asked twice: once by apt, once
# by Ansible (its become step runs outside the terminal's sudo ticket). Extra
# arguments are passed to ansible-playbook (for example: --tags desktop, or
# --skip-tags flatpak_apps).
set -euo pipefail

DOTFILES_DIR="$HOME/Dotfiles"
DOTFILES_REPO="https://github.com/Enoal-Fauchille-Bolle/Dotfiles.git"

if [ "$(id -u)" -eq 0 ]; then
    echo "❌ Run this script as your regular user, not as root." >&2
    exit 1
fi

if [ ! -r /etc/os-release ]; then
    echo "❌ Cannot read /etc/os-release: this script only supports Debian 13." >&2
    exit 1
fi
. /etc/os-release
if [ "${ID:-}" != "debian" ]; then
    echo "❌ This script only supports Debian, not ${PRETTY_NAME:-this system}." >&2
    exit 1
fi
if [ "${VERSION_ID:-}" != "13" ]; then
    echo "❌ This script only supports Debian 13, not ${PRETTY_NAME:-this version}." >&2
    exit 1
fi

CURRENT_USER="$(id -un)"
if ! command -v sudo >/dev/null 2>&1 || ! id -nG | grep -qw sudo; then
    cat >&2 <<EOF
❌ sudo is missing or $CURRENT_USER is not in the sudo group. As root, run:
    apt install sudo
    usermod -aG sudo $CURRENT_USER
then log out, log back in and run this script again.
EOF
    exit 1
fi

echo "📦 Installing git and Ansible..."
sudo apt-get update
sudo apt-get install -y git ansible

if [ ! -d "$DOTFILES_DIR" ]; then
    echo "⬇️  Cloning the dotfiles into $DOTFILES_DIR..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

echo "🚀 Running the playbook..."
cd "$DOTFILES_DIR/ansible"
ansible-playbook --ask-become-pass playbooks/all.yml "$@"

echo "✅ Done. Reboot now: the shell, groups, GNOME extensions and Flatpak apps only apply to a fresh session, and logging out is not enough (see ansible/README.md)."
