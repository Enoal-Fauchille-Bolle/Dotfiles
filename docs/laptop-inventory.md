# Laptop inventory and rebuild decisions

Machine: HP EliteBook G9, hostname `hp-elitebook-g9`, Debian 13 (trixie) 13.7,
kernel 6.12, GNOME Shell 48 on Wayland, user `enoal` (uid 1000).

Inventory taken read-only on 2026-09-15. It drives the Ansible playbook under
`ansible/` and its bootstrap command. Personal data (Documents, Projects, ...)
is out of scope: `scripts/my_scripts/restore.sh` restores it from the external
disk. Secrets never enter this repository.

Method: `apt-mark showmanual` (282 packages) minus the installer log
`/var/log/installer/status` (277) and the priority required/important/standard
set (107), then `lib*`, `task-*` and installer tooling removed by hand.
Everything outside apt was found from `$HOME`, `/usr/local`, `/opt`,
`/etc`, dconf and systemd.

## 1. Included in the playbook

### apt, Debian repositories

Shell and CLI: `zsh zsh-syntax-highlighting fzf eza thefuck htop btop fastfetch
vim tree jq curl git rsync zip unzip zstd xclip wl-clipboard stow gnupg
netcat-traditional nmap usbutils lshw smartmontools gsmartcontrol evtest
acpica-tools adb mtp-tools rclone`

Development: `build-essential cmake valgrind gcovr libssl-dev python3-dev
python3-pip python3-venv python3-setuptools python3-evdev libxkbcommon-dev
libgl1-mesa-dev qt6-base-dev qt6-tools-dev qt6-tools-dev-tools qt6-wayland
gir1.2-gtk-4.0 python3-nautilus`

TeX: `texlive-base texlive-binaries texlive-latex-base texlive-latex-recommended
texlive-latex-extra texlive-fonts-recommended texlive-pictures
texlive-plain-generic texlive-bibtex-extra biber latexmk`

Desktop and system: `ptyxis gparted freerdp3-x11 flatpak
gnome-software-plugin-flatpak podman systemd-oomd systemd-zram-generator
firmware-sof-signed firmware-amd-graphics`

Notes: `btop`, `valgrind` and `gcovr` are not installed today but are aliased
in `.zshrc`; Enoal asked for them. `python3-evdev` is required by
`sniper-mouse.py`.

### apt, third-party repositories (source file plus signing key)

| Repository | Packages | Key identity |
|---|---|---|
| download.docker.com/linux/debian trixie stable | docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin | Docker Release (CE deb) |
| pkgs.tailscale.com/stable/debian trixie | tailscale (plus tailscale-archive-keyring) | Tailscale Inc. |
| packages.microsoft.com/repos/code stable | code | Microsoft (Release signing) |
| cli.github.com/packages stable | gh | GitHub CLI |
| downloads.claude.ai/claude-desktop/apt/stable | claude-desktop | Anthropic Claude Code Release Signing |

Local `.deb` files with no repository (reinstall from upstream releases):
`input-remapper` 2.2.1, `kdiskmark` 3.3.0.

### Toolchains outside apt

| Tool | Install method | Detail |
|---|---|---|
| rustup | rustup.rs script | stable toolchain only; components cargo clippy rustfmt rust-src rust-docs |
| cargo install | cargo | `atuin` 18.19, `git-delta` 0.19 (binary `delta`), `cargo-tarpaulin` 0.37 |
| nvm | nvm install script | Node 24 as default alias, no global npm packages |
| pnpm | pnpm standalone script | lives in `~/.local/share/pnpm`, no global packages |
| bun | bun.sh script | 1.3.x, no global packages |
| Homebrew (Linuxbrew) | brew install script | formulae `git`, `betterleaks`, `trufflehog`; symlinks `/usr/local/bin/git` and `/usr/local/bin/betterleaks` point into brew |
| pip --user | pip | `diff-cover`, `diff-quality`, `Pygments` (pygmentize) |
| kubectl 1.36, helm 4.2 | GitHub/Kubernetes release binaries in `/usr/local/bin` | |
| k9s 0.51 | GitHub release tarball in `~/.local/opt/k9s-<ver>`, symlink in `~/.local/bin` | |
| zoxide | Debian apt (`zoxide` 0.9.7) | today 0.10.0 from webi in `~/.local/bin`; apt version replaces it |
| sshm 1.11 | GitHub release binary in `/usr/local/bin` | two GNOME shortcuts call `sshm astra` and `sshm pulsar` |
| QDiskInfo | binary in `/usr/local/bin` | source to confirm in phase 2 |
| ollama 0.34 | ollama.com install script | creates user `ollama` and `/etc/systemd/system/ollama.service`; model `qwen3.5:0.8b` pulled by hand |
| GitKraken 11.1.1 | official tarball in `/opt/gitkraken`, `.desktop` in `~/.local/share/applications` | pinned to 11.1.1 on request; download URL to verify from a container, the laptop blocks GitKraken domains in `/etc/hosts` |
| Claude Code | native installer into `~/.local/share/claude/versions`, symlink `~/.local/bin/claude` | plugins below |
| Docker | apt (above) | user in group `docker` |

Claude Code plugins to reinstall (from `~/.claude/plugins/installed_plugins.json`):
`claude-code-wakatime@wakatime`, and from `claude-plugins-official`:
`code-review`, `code-simplifier`, `context7`, `explanatory-output-style`,
`feature-dev`, `frontend-design`, `github`, `gitlab`, `rust-analyzer-lsp`,
`superpowers`, `typescript-lsp`.

### Flatpak

Remotes: `flathub` (https://dl.flathub.org/repo/) and `flathub-beta`
(https://dl.flathub.org/beta-repo/). System installation.

`com.anydesk.Anydesk com.bitwarden.desktop com.brave.Browser
com.discordapp.Discord com.discordapp.DiscordCanary (flathub-beta)
com.github.ADBeveridge.Raider com.github.IsmaelMartinez.teams_for_linux
com.google.Chrome com.mattjakeman.ExtensionManager com.protonvpn.www
com.termius.Termius dev.vencord.Vesktop md.obsidian.Obsidian
net.nokyan.Resources nl.hjdskes.gcolor3 org.audacityteam.Audacity
org.gnome.Extensions org.gnome.World.PikaBackup org.kde.krita
org.libreoffice.LibreOffice org.localsend.localsend_app
org.prismlauncher.PrismLauncher org.videolan.VLC page.tesk.Refine`

Override: `com.google.Chrome` gets `filesystems=/home/enoal:ro`.

### GNOME

Extensions (all user-installed under `~/.local/share/gnome-shell/extensions`,
all enabled):
`monitor@astraext.github.io Bluetooth-Battery-Meter@maniacx.github.com
blur-my-shell@aunetx burn-my-windows@schneegans.github.com
claude-code-usage@haletran.com clipboard-indicator@tudmotu.com
dash-to-dock@micxgx.gmail.com emoji-copy@felipeftn
gsconnect@andyholmes.github.io IP-Finder@linxgem33.com
lan-ip-address@mrhuber.com nightthemeswitcher@romainvigier.fr
notification-configurator@exposedcat steal-my-focus-window@steal-my-focus-window
vscode-search-provider@mrmarble.github.com weatherornot@somepaulo.github.io
top-bar-organizer@julian.gse.jsts.xyz`

dconf settings to export and load: `org/gnome/desktop/interface`,
`org/gnome/desktop/wm/keybindings`, `org/gnome/desktop/wm/preferences`,
`org/gnome/settings-daemon/plugins/media-keys` and its nine custom
keybindings, `org/gnome/desktop/peripherals/*`,
`org/gnome/desktop/input-sources` (`fr+azerty`), `org/gnome/shell`
(favorite-apps, enabled-extensions), `org/gnome/mutter`,
`org/gnome/desktop/session` (idle-delay 0),
`org/gnome/settings-daemon/plugins/power` (no sleep), `org/gnome/Ptyxis`
(font `DroidSansM Nerd Font 11`), `org/gnome/nautilus/*`, `org/gtk/*`, and
`org/gnome/shell/extensions/*`.

Autostart: `input-remapper-autoload.desktop`.

Font: DroidSansM Nerd Font v3.4.0 into `~/.local/share/fonts/NerdFonts`
(same logic as `scripts/my_scripts/setup-nerd-font.sh`).

MIME defaults: the live `~/.config/mimeapps.list` replaces the stale copy in
`system/.config/mimeapps.list`, and `system` joins the stow list.

VS Code: only the `code` package. Extensions, settings and profiles come back
through Settings Sync with the GitHub account, so the playbook keeps no
extension list.

### Shell

`zsh` as login shell, oh-my-zsh cloned from GitHub, custom plugin
`zsh-autosuggestions`, theme `powerlevel10k`, `.zshrc` and `.p10k.zsh` from
this repository via `install.sh`. atuin config from this repository; the sync
login is manual. Empty `~/.zshrc.secrets` and `~/.wakatime.key` created as
`install.sh` does today.

### Services and system settings

| Item | Value |
|---|---|
| systemd user units | `sniper-mouse.service`, `battery-discord.service`, `battery-discord.timer` (files to add to this repository) |
| Stow package `input-remapper` | `~/.config/input-remapper-2` (config.json, xmodmap.json, presets for the keyboard and the BT5.0 mouse) |
| Personal scripts to bring into `scripts/my_scripts` | `~/.local/bin/battery-discord-notify.sh`, `~/.local/bin/moodledl-catch` plus `moodledl-catch.desktop` |
| Locale | `en_US.UTF-8` generated and default |
| Keyboard | console `fr` `latin9` (`/etc/default/keyboard`), GRUB keymap `fr` in `/etc/grub.d/40_custom` |
| Timezone | `Europe/Paris` |
| logind | `HandleLidSwitch=lock` |
| sysctl | `/etc/sysctl.d/90-inotify.conf`: `fs.inotify.max_user_instances = 1024` |
| udev | `/etc/udev/rules.d/51-oneplus-10t-mtp.rules` (MTP access for OnePlus 10T, vendor 22d9 product 2766) |
| GRUB | `GRUB_CMDLINE_LINUX_DEFAULT="quiet usb-storage.quirks=0bc2:231a:u,152d:0580:u"`, `GRUB_TERMINAL_INPUT=at_keyboard`, `GRUB_PRELOAD_MODULES="at_keyboard keylayouts"` |
| Groups for `enoal` | `sudo docker input plugdev netdev bluetooth lpadmin scanner` |
| Manual after install | Tailscale login, atuin login, `gh auth login`, GitKraken account, `ollama pull qwen3.5:0.8b`, VS Code sign-in for Settings Sync, SSH keys and Wi-Fi/WireGuard profiles |

## 2. Excluded, with reasons

| Item | Reason |
|---|---|
| Installer-provided packages (`lib*`, `task-*`, tasksel, busybox, initramfs-tools, lvm2, cryptsetup, grub, shim, linux-image, console-setup, wpasupplicant) | Present on every fresh Debian 13 |
| Nix (`nix/` stow package, `.nix-channels`) | Not installed, `.zshrc` line commented out |
| .NET leftover (`~/.dotnet/corefx`), Go PATH entry | Nothing installed |
| TeX Live 2026 in `/usr/local/texlive/2026` | Dormant, not on PATH; the apt TeX Live 2025 is the one in use |
| Rust toolchains nightly, 1.85, 1.87, 1.88; Node 14 | Projects pin their own toolchain (`rust-toolchain.toml`, `.nvmrc`) |
| `cargo install aic`, `tetris-tui` | `aic` is built from `~/Projects/aic`; `tetris-tui` dropped by decision |
| `tirith` local .deb | Its `.zshrc` line is commented out |
| kitty | Ptyxis is the terminal; `~/.config/kitty` is empty |
| webi | Installer tool only; the tools it placed are installed directly instead |
| Docker CLI plugin `docker-pussh` | Dropped by decision |
| `~/.config/sshm/config.json` | Not versioned, by decision |
| NetworkManager profiles (9 Wi-Fi, 2 WireGuard) | Contain keys and passwords |
| `/etc/hosts` entries blocking GitKraken licence domains | Licence-check circumvention, not automated |
| User `sbolle` and its subuid/subgid range | Another person's account |
| Dark wallpaper `~/Pictures/AstralRedshift/Desktop Wallpaper.png` | Personal data, restored by `restore.sh` |
| Autostart `remmina-applet.desktop` | Launches a flatpak that is no longer installed |
| Aliases to absent tools: cmatrix, asciiquarium, neofetch, procs, todo.sh, nvim, antigravity | Not installed, by decision; the aliases stay for a later cleanup |

## 3. Decisions on the open points (2026-09-15)

- Testing: Docker containers first; a throwaway Debian VM on the Proxmox
  homelab confirms the result at the end.
- input-remapper: the presets under `~/.config/input-remapper-2` are
  versioned as a stow package `input-remapper`.
- Layout: everything Ansible lives under `ansible/`; the playbook calls
  `install.sh` for the stow step (single list of stow packages, script still
  usable alone on servers).
- GitKraken 11.1.1: the pinned download URL was verified from a container.
- `install.sh` now runs `stow --no-folding`: on a fresh machine stow used to
  turn `~/.local`, `~/.claude` or `~/.config/systemd` into links pointing
  inside this repository, so installers then wrote their files (Claude
  credentials included) into the repository tree.
- Container tests (2026-09-15): full run then second run in a fresh Debian 13
  container with systemd, second run `changed=0 failed=0`. Flatpak was tested
  with a single small app; GRUB, udev and sysctl reloads are skipped in
  containers; GNOME itself needs the VM checklist in `ansible/README.md`.

## 4. Remarks noticed on the laptop, to handle later

Not part of the playbook. Listed so they are not forgotten.

- `.zshrc` dead lines: PATH entries `/usr/local/go/bin` and `~/.resend/bin`,
  `source ~/.config/envman/load.sh`, and `eval $(thefuck --alias)` present
  twice (lines 250 and 281); pyenv and tirith lines commented out.
- `.zshrc` `PNPM_HOME` is added to PATH but the binaries live in
  `$PNPM_HOME/bin`, so `pnpm` is not found.
- `.zshrc` aliases point to tools that are not installed: cmatrix,
  asciiquarium, neofetch (fastfetch is installed), procs, todo.sh, nvim
  (alias `vim`), antigravity.
- `scripts/my_scripts/system-maintenance.sh` runs `sudo dnf update`; the
  machine is Debian and Fedora is no longer used.
- `backup.sh` uses `/run/media/$USER/MyDisk`, `restore.sh` uses
  `/media/$USER/MyDisk`; one of the two paths is wrong.
- `README.md` still presents Fedora 43 as the primary environment and lists
  the `nix` package; `install.sh` keeps a Fedora branch.
- `system/` stow package is not in `install.sh` and its `mimeapps.list` has
  diverged from the live file.
- `~/.zshrc2` (4 KB) is an unused leftover in `$HOME`.
- `/usr/local/texlive/2026` (root-owned, installed 2026-09-05) is unused and
  takes disk space.
- `~/.dotnet/corefx` is an empty leftover.
- Autostart `remmina-applet.desktop` points to a removed flatpak.
- GitHub CLI apt signing key expires on 2026-09-27; `apt update` will start
  failing for that repository unless the keyring is refreshed.
- `/etc/default/grub.bak-2026-08-19-2341` is a leftover backup.
- Local `.deb` packages `input-remapper` and `kdiskmark` are newer than the
  Debian versions and will not receive updates.
- Some dotfile links on the laptop are folded directory links
  (`~/.config/atuin`, and possibly others); the next `install.sh` run, now
  with `--no-folding`, replaces them with per-file links.
- GitKraken 11.1.1 is pinned in the playbook, but the app updates itself in
  `/opt/gitkraken`, so a rebuilt machine starts at 11.1.1 and moves on.
