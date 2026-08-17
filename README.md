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
├── atuin           # Shell history (SQLite backed, synced across machines)
├── clang-format    # Epitech C/C++ coding style
├── claude          # Claude Code configuration
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
* **History:** Atuin, bound to `ctrl-r`. The up arrow keeps its native Zsh behaviour, and the fzf `ctrl-t` / `alt-c` widgets are untouched.
* **Version Control:** Global Git configuration, standard ignores.
* **Development:**
  * VS Code settings (user preferences, keybindings).
  * NPM configuration (registry settings).
  * Clang-format (Epitech C/C++ coding style).
  * Claude Code: global instructions, status line, session budget guard, and the `/handoff` skill.
* **System:**
  * Custom utility scripts added to `PATH`.
  * Nix channels configuration.
  * MIME type associations.

### Claude Code session budget

Claude cannot see how full its own context window is — no hook receives that
number ([claude-code#27969](https://github.com/anthropics/claude-code/issues/27969)),
so a rule telling it to warn past a threshold would be pure guesswork. The two
files here close that gap by splitting the job in half:

* `statusline-command.sh` is the **sensor**. The status line is the only
  component handed live context, cost and rate-limit metrics, so it publishes
  them to `~/.claude/state/ctx-<session>.txt` on every redraw.
* `hooks/budget-guard.sh` is the **actuator**. It runs on `UserPromptSubmit` —
  the only event whose stdout becomes context Claude can act on — reads that
  state file, and falls back to summing the transcript's last assistant turn
  when the status line has gone stale. Below every threshold it prints nothing,
  so it costs no tokens on the vast majority of prompts.

The thresholds it reports are named, never explained: what to do about each one
lives in `CLAUDE.md`, which is re-injected from disk after every compaction.

## Post-Installation

After running the install script, perform the following steps to finalize the setup:

1. **Restart your shell** to apply Zsh changes:

    ```bash
    exec zsh
    ```

2. **SSH Keys:** Manually restore your private SSH keys (`id_rsa`) to `~/.ssh/` from a secure backup.

3. **Atuin:** Install the binary, then hook the machine up to the synced history:

    ```bash
    cargo install atuin     # same version on every machine, unlike the distro packages
    atuin import auto       # one-off, pulls in the existing ~/.zsh_history
    atuin login -u <USERNAME>
    atuin sync
    ```

    On a brand new machine, `atuin login` also asks for the encryption key. History is
    end-to-end encrypted, so without that key the server has nothing readable to hand back.
    Print it on an already-synced machine with `atuin key` and keep it in a password manager.
