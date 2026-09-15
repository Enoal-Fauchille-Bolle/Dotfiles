# Workstation playbook

Rebuilds the laptop (Debian 13, GNOME) from a fresh install: apt repositories
and packages, system settings, Zsh and the stow-managed dotfiles, language
toolchains, Flatpak applications, GNOME extensions and settings, fonts, and
the services. The inventory it was built from, with what was left out and
why, is in `../docs/laptop-inventory.md`.

## Usage

On a fresh Debian 13 with the regular user in the `sudo` group, from a
terminal inside the desktop session:

```bash
curl -fsSL https://raw.githubusercontent.com/Enoal-Fauchille-Bolle/Dotfiles/main/bootstrap.sh | bash
```

`bootstrap.sh` installs git and Ansible, clones this repository into
`~/Dotfiles` if needed, and runs `playbooks/all.yml`, asking for the sudo
password once. Any extra argument goes to `ansible-playbook`:

```bash
~/Dotfiles/bootstrap.sh --tags desktop          # one domain only
~/Dotfiles/bootstrap.sh --skip-tags flatpak_apps # everything but the big downloads
~/Dotfiles/bootstrap.sh --check --diff           # preview
```

Running the playbook a second time changes nothing.

## Layout

```text
ansible/
├── ansible.cfg
├── inventory.ini          # localhost, local connection
├── group_vars/all.yml     # every list: packages, versions, apps, extensions
├── playbooks/
│   ├── all.yml            # imports the five below, in order
│   ├── base.yml           # repos, packages, system settings, user
│   ├── shell.yml          # zsh, oh-my-zsh, p10k, install.sh (stow)
│   ├── toolchains.yml     # rust, node, bun, homebrew, python, k8s, tools, claude, gitkraken
│   ├── desktop.yml        # flatpak, gnome extensions, fonts, dconf
│   └── services.yml       # ollama, user systemd units
└── roles/<domain>/<role>/ # tags: [domain, role]
```

The stow step is not duplicated here: the `shell/dotfiles` role runs
`../install.sh`, whose `PACKAGES` array stays the single list of stow
packages. The role only calls it when a dry run of stow reports a missing
link, so it stays idempotent.

Versions of tools installed outside apt are pinned in `group_vars/all.yml`
(rustup, nvm, Node, pnpm, bun, kubectl, helm, k9s, sshm, QDiskInfo,
GitKraken, Ollama, Nerd Fonts). Bump a version there and re-run; nothing is
uninstalled automatically.

## Manual steps after the playbook

Secrets never live in the repository. After the first run:

- `~/.zshrc.secrets`, `~/.wakatime.key` and `~/.config/battery-discord/config`
  are created empty: fill them.
- SSH keys: restore `~/.ssh/id_ed25519` and `.pub` (git commit signing uses
  the public key).
- Logins: `sudo tailscale up`, `gh auth login`, `atuin login`, VS Code
  (Settings Sync restores extensions and profiles), GitKraken, Claude Code
  and Claude Desktop, Discord, Bitwarden and the other Flatpak apps.
- `ollama pull qwen3.5:0.8b`.
- Wi-Fi and WireGuard profiles in NetworkManager.
- Personal data: `~/my_scripts/restore.sh` from the external disk.
- Log out and back in: the Zsh login shell, the new groups (docker, input)
  and the GNOME extensions only apply to a new session.

## What a container cannot test, and how to check it in a VM

The playbook is tested in a privileged Debian 13 container with systemd.
The points below need a VM (fresh Debian 13 with GNOME, user in `sudo`).
Run `bootstrap.sh` there, reboot, then check:

| Area | Check |
|---|---|
| GRUB | `cat /proc/cmdline` shows `usb-storage.quirks=...`; the GRUB menu accepts a French keyboard (type `a` on the `q` key) |
| udev, sysctl | `sysctl fs.inotify.max_user_instances` returns 1024; a phone on USB is visible in Files (needs the OnePlus) |
| Session | lid close locks the screen; no automatic suspend or dimming; 24h clock with seconds; battery percentage in the top bar |
| Keyboard | AZERTY in GNOME and in the console (`localectl status`) |
| Shortcuts | Super+T opens Ptyxis, Super+N the text editor, Super+Y the Downloads folder, Shift+Super+V toggles the VPN (after a WireGuard profile exists), Ctrl+Shift+Escape the system monitor |
| Extensions | all seventeen listed and enabled in the Extensions app; dock at the bottom, clipboard indicator, Astra Monitor in the top bar |
| Terminal | Ptyxis uses DroidSansM Nerd Font (p10k icons render) |
| Docker | `docker run --rm hello-world` works without sudo (group applied after re-login) |
| Ollama | `systemctl status ollama` active; `ollama list` works |
| User units | `systemctl --user status sniper-mouse.service battery-discord.timer` (the mouse daemon needs the Bluetooth mouse; it retries every 3 s until then) |
| input-remapper | the `Sniper` preset loads for the BT5.0 mouse at login |
| Flatpak | the 24 apps appear in the app grid; Chrome sees `~` read-only in its sandbox (`flatpak override --user --show com.google.Chrome`) |
| MIME | links open in Chrome, videos in VLC, `claude://` links in Claude Desktop |
| Idempotence | a second `bootstrap.sh` run ends with `changed=0` |
