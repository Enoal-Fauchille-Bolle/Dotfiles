# Dotfiles

Centralized development environment setup: automated installation via GNU Stow for Fedora, Zsh, and Git configurations.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Repository Structure](#repository-structure)
5. [Secrets Management](#secrets-management)
6. [Included Configurations](#included-configurations)
7. [Post-Installation](#post-installation)

## Overview

This repository contains my personal configuration files (dotfiles) for Linux environments. It is designed to be portable and modular, utilizing **GNU Stow** to manage symlinks. The primary environment is Fedora 43, but the setup is compatible with Debian-based systems (Ubuntu/Debian) for server or secondary machine usage.

The goal is to replicate a consistent development workflow across different machines instantly, covering shell configuration, version control settings, and development tools.

## Prerequisites

Before installing, ensure the following are available on your system:

* **Operating System:** Fedora (Recommended) or Debian/Ubuntu.
* **Git:** Required to clone this repository.
* **Internet Connection:** Required to fetch packages and plugins.

## Installation

The installation process is automated via a shell script that detects the distribution, installs GNU Stow if missing, and creates the necessary symlinks.

1. **Clone the repository** into your home directory:

    ```bash
    git clone git@github.com:Enoal-Fauchille-Bolle/Dotfiles.git ~/Dotfiles
    ```

2. **Navigate to the directory:**

    ```bash
    cd ~/Dotfiles
    ```

3. **Run the installation script:**

    ```bash
    ./install.sh
    ```

This script will:

* Install `stow` (via `dnf` or `apt`).
* Iterate through the package directories.
* Symlink configuration files to your `$HOME` directory.
* Initialize the local secrets configuration file.

## Repository Structure

This project uses GNU Stow to manage packages. Each top-level directory represents a "package" that will be symlinked to the target directory (usually `$HOME`).

```text
~/Dotfiles
├── clang-format    # Epitech C/C++ coding style
├── git             # Git global configuration and ignores
├── nix             # Nix package manager channels
├── npm             # NPM configuration and tokens
├── scripts         # Personal executables and utility scripts
├── ssh             # SSH configuration (config file only, no keys)
├── wakatime        # Wakatime configuration for time tracking
├── zsh             # Zsh, Oh My Zsh, and Powerlevel10k setup
├── install.sh      # Automation script
└── README.md       # Documentation
```

## Secrets Management

For security reasons, sensitive information (API tokens, private keys) is **not** committed to this repository.

The installation script creates a local file named `.zshrc.secrets` in your home directory. This file is sourced automatically by `.zshrc`.

To add your secrets, edit the file manually after installation:

```bash
nano ~/.zshrc.secrets
```

**Example content:**

```bash
export NPM_TOKEN="your-private-npm-token"
export WAKATIME_API_KEY="your-private-wakatime-api-key"
```

## Included Configurations

* **Shell:** Zsh with Oh My Zsh framework and Powerlevel10k theme.
* **Version Control:** Global Git configuration, standard ignores.
* **Development:**
  * VS Code settings (user preferences, keybindings).
  * NPM configuration (registry settings).
  * Clang-format (Epitech C/C++ coding style).
* **System:**
  * Custom utility scripts added to `PATH`.
  * Nix channels configuration.
  * MIME type associations.

## Post-Installation

After running the install script, perform the following steps to finalize the setup:

1. **Restart your shell** to apply Zsh changes:

    ```bash
    exec zsh
    ```

2. **SSH Keys:** Manually restore your private SSH keys (`id_rsa`) to `~/.ssh/` from a secure backup.
