# Dotfiles

Configuration of a Debian 13 GNOME workstation: dotfiles linked with GNU Stow, and an Ansible playbook that rebuilds the whole machine.

## Table of Contents

1. [Installation](#installation)
2. [Repository Structure](#repository-structure)
3. [Secrets](#secrets)
4. [Default Applications](#default-applications)
5. [Node and Project Variables](#node-and-project-variables)
6. [Claude Code Session Budget](#claude-code-session-budget)
7. [Post-Installation](#post-installation)
8. [License](#license)

## Installation

Two entry points exist, depending on how much of the machine needs setting up.

### Full rebuild

`bootstrap.sh` runs the Ansible playbook: apt packages, system settings, toolchains, Flatpak apps, GNOME extensions, fonts, services, and the dotfiles themselves.

```bash
curl -fsSL https://raw.githubusercontent.com/Enoal-Fauchille-Bolle/Dotfiles/main/bootstrap.sh | bash
# or, on a minimal install that ships wget but not curl:
wget -qO- https://raw.githubusercontent.com/Enoal-Fauchille-Bolle/Dotfiles/main/bootstrap.sh | bash
```

The script only runs on Debian 13 (Ubuntu and other derivatives are refused) and needs the regular user in the `sudo` group. [`ansible/README.md`](ansible/README.md) covers usage, layout, the manual steps after the playbook, and the VM checklist for what a container can't test.

### Dotfiles only

`install.sh` links the configuration files and installs nothing else apart from Stow, which it gets from `apt`. Zsh, Oh My Zsh, mise and the other tools these files expect have to be present already. The repository must be cloned into `~/Dotfiles`:

```bash
git clone https://github.com/Enoal-Fauchille-Bolle/Dotfiles.git ~/Dotfiles
cd ~/Dotfiles
./install.sh
```

The script:

- Moves any regular file standing where a link must go to `~/.dotfiles-backup/<date>/`.
- Links each package listed in its `PACKAGES` array into `$HOME`.
- Creates `~/.zshrc.secrets` and `~/.wakatime.key`, both empty and readable by their owner only.

## Repository Structure

```text
~/Dotfiles
├── home/           # Stow packages, one folder per tool
├── ansible/        # Debian workstation playbook
├── bootstrap.sh    # Entry point of the playbook
├── install.sh      # Links the packages, creates the local secret files
├── LICENSE
└── README.md
```

Each folder in `home/` mirrors `$HOME`, so `home/zsh/.zshrc` becomes a link at `~/.zshrc`. Stow runs with `--no-folding`: it links files one by one, and directories such as `~/.claude` or `~/.local` stay real directories.

| Package | Contents |
| --- | --- |
| `atuin` | Shell history settings. `.zshrc` binds it to `ctrl-r`, and the up arrow keeps its native Zsh behaviour. |
| `claude` | Claude Code global instructions, settings, status line, budget hook and `/handoff` skill. |
| `desktop` | Default applications, the Ptyxis launcher and icon, the `moodledl://` link handler. |
| `git` | Global Git configuration and ignores. |
| `input-remapper` | Keyboard and mouse presets, loaded at login. |
| `mise` | Global Node version and mise settings. |
| `scripts` | Executables for `~/.local/bin`: restic backup, snapshot browser, battery alert, VPN toggle, mouse daemon. |
| `ssh` | SSH client configuration, without keys or private hosts. |
| `systemd` | User units and timers for the backup, the battery alert and the mouse daemon. |
| `wakatime` | WakaTime settings. The API key is read from `~/.wakatime.key`. |
| `zsh` | `.zshrc`, `.zprofile` and the Powerlevel10k prompt. |

## Secrets

Tokens and private keys stay out of this repository. They live in local files:

- **`~/.zshrc.secrets`**: variables needed in every shell, sourced by `.zshrc`.
- **`~/.wakatime.key`**: the WakaTime API key alone, without comments.
- **`~/.config/restic/env`** and **`~/.config/battery-discord/config`**: created by the playbook, filled by hand.
- **`mise.local.toml`**: variables for a single project, ignored by the global Git ignores (see [Node and Project Variables](#node-and-project-variables)).
- **`~/.ssh/`**: the keys and the private host list in `config.d/`, which the tracked `config` includes. Both come back from the restic backup.

## Default Applications

Default applications are set in two layers, because the [freedesktop specification](https://specifications.freedesktop.org/mime-apps/latest/file.html) reads `~/.config/mimeapps.list` before `~/.local/share/applications/mimeapps.list`:

- **The base** is `home/desktop/.local/share/applications/mimeapps.list`, tracked here.
- **Changes made in GNOME** go to `~/.config/mimeapps.list`, which stays out of the repository and takes priority over the base.

To keep such a change on the next machine, copy its line into the tracked file by hand.

## Node and Project Variables

[mise](https://mise.jdx.dev/) installs Node and loads variables per project.

- **Node version**: set in `home/mise/.config/mise/config.toml`. A project can ask for another one with `.nvmrc` or `.node-version`, and `package.json` is ignored. Only `mise install` downloads a missing version, so cloning a repository never triggers a download.
- **Graphical programs**: they never read `.zshrc`, so `.zprofile` puts the mise shims on their `PATH`.
- **Project variables**: go in a `mise.local.toml` at the root of the project, under `[env]`. mise only loads these variables after `mise trust`, and that approval has to be given again after a restore because it is stored in `~/.local/state/mise`.

## Claude Code Session Budget

Claude cannot see how full its own context window is, because no hook receives that number ([claude-code#27969](https://github.com/anthropics/claude-code/issues/27969)). A rule telling it to warn past a threshold would be guesswork. Two files close that gap:

- **`statusline-command.sh`** is the sensor. The status line is the only component handed live context, cost and rate-limit metrics, so it publishes them to `~/.claude/state/ctx-<session>.txt` on every redraw.
- **`hooks/budget-guard.sh`** is the actuator. It runs on `UserPromptSubmit`, the only event whose stdout becomes context Claude can act on. It reads that state file and falls back to summing the transcript's last assistant turn when the status line has gone stale. Below every threshold it prints nothing, so most prompts cost no extra tokens.

The hook only names the threshold that was crossed. What to do about each one is in `CLAUDE.md`, which is re-injected from disk after every compaction.

## Post-Installation

1. **Shell**: restart it to apply the Zsh changes.

    ```bash
    exec zsh
    ```

2. **SSH keys**: restore `~/.ssh/id_ed25519` and its `.pub` from a secure backup. Git commit signing uses the public key.

3. **Atuin**: connect the machine to the synced history. The playbook installs the binary; otherwise, `cargo install atuin` gives the same version on every machine, unlike the distribution packages.

    ```bash
    atuin import auto       # one-off, pulls in the existing ~/.zsh_history
    atuin login -u <USERNAME>
    atuin sync
    ```

    On a new machine, `atuin login` also asks for the encryption key. History is end-to-end encrypted, so the server has nothing readable to hand back without it. `atuin key` prints it on a machine that is already synced.

After a full rebuild, the longer list in [`ansible/README.md`](ansible/README.md#manual-steps-after-the-playbook) applies.

## License

GNU General Public License v3, see [`LICENSE`](LICENSE).
