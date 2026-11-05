# Workstation playbook

Rebuilds the laptop (Debian 13, GNOME) from a fresh install: apt repositories
and packages, system settings, Zsh and the stow-managed dotfiles, language
toolchains, Flatpak applications, GNOME extensions and settings, fonts, and
the services.

## Usage

On a fresh Debian 13 with the regular user in the `sudo` group, from a
terminal inside the desktop session:

```bash
curl -fsSL https://raw.githubusercontent.com/Enoal-Fauchille-Bolle/Dotfiles/main/bootstrap.sh | bash
# or, on a minimal install that ships wget but not curl:
wget -qO- https://raw.githubusercontent.com/Enoal-Fauchille-Bolle/Dotfiles/main/bootstrap.sh | bash
```

`bootstrap.sh` first checks `/etc/os-release` and stops unless the system is
Debian 13 (`ID=debian`, `VERSION_ID=13`; Ubuntu and testing/sid are refused),
and checks that `sudo` is installed with the current user in the `sudo` group
(the Debian installer skips both when a root password is set; the script
prints the commands to fix it). It then installs git and Ansible, clones this
repository into `~/Dotfiles` if needed, and runs `playbooks/all.yml`.

The sudo password is asked twice: once by `apt`, once by Ansible through
`--ask-become-pass`. The second prompt is always shown, even right after the
first: sudo caches its authorisation per terminal, and Ansible runs its
`become` commands in a child process that sudo does not tie to that terminal,
so a `sudo -n true` check in the script cannot predict whether Ansible will
get through. Any extra argument goes to `ansible-playbook`:

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
│   ├── toolchains.yml     # rust, homebrew, node, bun, python, k8s, tools, claude, gitkraken
│   ├── desktop.yml        # flatpak, gnome extensions, fonts, dconf
│   └── services.yml       # ollama, restic backup, user systemd units
└── roles/<domain>/<role>/ # tags: [domain, role]
```

The stow step is not duplicated here: the `shell/dotfiles` role runs
`../install.sh`, whose `PACKAGES` array stays the single list of stow
packages. The role only calls it when a dry run of stow reports a missing
link, so it stays idempotent.

Versions of tools installed outside apt are pinned in `group_vars/all.yml`
(rustup, pnpm, bun, kubectl, helm, k9s, sshm, QDiskInfo, GitKraken, Ollama,
Nerd Fonts). Bump a version there and re-run; nothing is uninstalled
automatically. Node is the exception: its version is in
`home/mise/.config/mise/config.toml`.

Direct downloads carry a SHA-256 checksum next to their version, and a mismatch
stops the run. Bumping one of them means updating both values. The install
scripts piped into a shell (rustup, Homebrew, uv, pnpm, bun, Ollama, Claude
Code) are not covered. Archives stay in
`~/.cache/dotfiles-downloads`, so the next run does not fetch them again.

## Manual steps after the playbook

Secrets never live in the repository. After the first run:

- `~/.zshrc.secrets`, `~/.wakatime.key` and `~/.config/battery-discord/config`
  are created empty: fill them.
- Backup: `~/.config/restic/env` is created with comments only. The bucket,
  key, `restic init` and Kuma monitor steps are in
  `roles/services/restic/README.md`.
- SSH keys: restore `~/.ssh/id_ed25519` and `.pub` (git commit signing uses
  the public key). The private host list in `~/.ssh/config.d/` comes back with
  the restic restore: the tracked `~/.ssh/config` only includes it.
- Logins: `gh auth login`, `atuin login`, VS Code
  (Settings Sync restores extensions and profiles), GitKraken, Claude Code
  and Claude Desktop, Discord, Bitwarden and the other Flatpak apps.
- `ollama pull qwen3.5:0.8b`.
- Wi-Fi and WireGuard profiles in NetworkManager.
- Personal data: `restic restore latest --target /`, once
  `~/.config/restic/env` is filled ("Restore" in
  `roles/services/restic/README.md`).
- Project secrets: the restore brings back each `mise.local.toml`, but not its
  approval, which stays in `~/.local/state/mise`. Run `mise trust` in each of
  those projects.
- Reboot. The Zsh login shell, the new groups (docker, input), the GNOME
  extensions and the Flatpak apps only apply to a fresh session, and logging
  out is not enough: `systemd --user` keeps running as long as any session of
  the user is open (an SSH connection counts), and it is the process that
  hands GNOME the application directories, including
  `/var/lib/flatpak/exports/share`. Started before the playbook installed
  flatpak, it never learns about that directory, so the Flatpak apps stay
  invisible in the app grid and the dock until it restarts.

## What a container cannot test, and how to check it in a VM

`ansible/tests/run-in-container.sh` runs the playbook on the committed tree in a
privileged Debian 13 container with systemd, twice, and fails unless the second
run changes nothing. Arguments go to `ansible-playbook`, `CONTAINER_ENGINE`
selects `podman` (the default) or `docker`, and `CARGO_BUILD_JOBS` limits the Rust
compilation on a machine short of memory. It takes all the CPU for a while, so a
VM suits it better than a laptop in use. GitHub Actions runs it too, when the CI
workflow is started by hand.

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
| Terminal | Ptyxis and GNOME Console use DroidSansM Nerd Font (p10k icons render); Ptyxis shows the custom icon and is named Terminal in the app grid |
| Docker | `docker run --rm hello-world` works without sudo (group applied after re-login) |
| Ollama | `systemctl status ollama` active; `ollama list` works |
| User units | `systemctl --user status sniper-mouse.service battery-discord.timer restic-backup.timer` (the mouse daemon needs the Bluetooth mouse; it retries every 3 s until then) |
| input-remapper | the `Sniper` preset loads for the BT5.0 mouse at login |
| Flatpak | the 25 apps appear in the app grid; Chrome sees `~` read-only in its sandbox (`flatpak override --user --show com.google.Chrome`) |
| MIME | links open in Chrome, videos in VLC, `claude://` links in Claude Desktop |
| Idempotence | a second `bootstrap.sh` run ends with `changed=0` |
