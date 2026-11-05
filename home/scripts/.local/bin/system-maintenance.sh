#!/usr/bin/env bash
# Updates the system and the tools installed outside apt, cleans up, then checks
# whether a reboot is needed. Each section shows what is pending, applies the
# update without asking, and the run ends with a summary. A short log of the
# run goes to ~/.local/state/system-maintenance/.
#
# bun and ollama are pinned in the Ansible playbook (bun_version, ollama_version):
# updating them here moves them past the pinned versions until the playbook is bumped.
#
# No -e: a failing section is counted in the summary and the next one still runs.
set -uo pipefail

SECTIONS=(apt flatpak brew rust mise uv claude bun ollama firmware cleanup checks)

# Command each section needs; a section without an entry always runs.
declare -A NEEDS=(
    [apt]=apt-get [flatpak]=flatpak [brew]=brew [rust]=rustup [mise]=mise [uv]=uv
    [claude]=claude [bun]=bun [ollama]=ollama [firmware]=fwupdmgr
)

usage() {
    cat <<EOF
Usage: ${0##*/} [--dry-run] [--only SECTION,...] [--ask]

  -n, --dry-run   show what is pending, change nothing, ask no password
  --only LIST     run only these sections (comma separated)
  -a, --ask       ask before each section
  -h, --help      show this help

Sections: ${SECTIONS[*]}
EOF
}

if [[ -t 1 ]]; then
    RED=$'\033[31m' GREEN=$'\033[32m' YELLOW=$'\033[33m' BLUE=$'\033[34m' DIM=$'\033[2m' RESET=$'\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' DIM='' RESET=''
fi

DRY_RUN=0
ASK=0
ONLY=()
OK=0 WARN=0 ERR=0 SKIPPED=0
LOG=''
SUDO_KEEPALIVE=''

while (($#)); do
    case $1 in
        -n | --dry-run) DRY_RUN=1 ;;
        -a | --ask) ASK=1 ;;
        --only)
            shift
            [[ $# -gt 0 ]] || { usage >&2; exit 2; }
            IFS=, read -ra ONLY <<<"$1"
            ;;
        --only=*) IFS=, read -ra ONLY <<<"${1#--only=}" ;;
        -h | --help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
    shift
done

for name in "${ONLY[@]}"; do
    [[ " ${SECTIONS[*]} " == *" $name "* ]] || { echo "Unknown section: $name" >&2; usage >&2; exit 2; }
done

# Tools installed outside apt live in these folders; a non-interactive shell
# does not always have them in PATH.
for dir in "$HOME/.cargo/bin" "$HOME/.bun/bin" "$HOME/.local/bin" /home/linuxbrew/.linuxbrew/bin; do
    [[ -d $dir && :$PATH: != *":$dir:"* ]] && PATH="$PATH:$dir"
done

# brew would otherwise run its own update before any command, even a read-only one.
export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ENV_HINTS=1

log() {
    [[ -n $LOG ]] || return 0
    printf '%s %s\n' "$(date +%T)" "$*" >>"$LOG"
}

info() { printf '%s\n' "${BLUE}ℹ${RESET} $1"; log "info  $1"; }
warn() { WARN=$((WARN + 1)); printf '%s\n' "${YELLOW}⚠ $1${RESET}"; log "warn  $1"; }
good() { OK=$((OK + 1)); printf '%s\n' "${GREEN}✓ $1${RESET}"; log "ok    $1"; }
fail() { ERR=$((ERR + 1)); printf '%s\n' "${RED}✗ $1${RESET}"; log "error $1"; }

header() { printf '\n%s\n' "${BLUE}== $1 ==${RESET}"; }

# Runs a command that changes something; --dry-run only prints it.
run() {
    printf '%s\n' "${DIM}\$ $*${RESET}"
    ((DRY_RUN)) && return 0
    "$@"
}

confirm() {
    ((ASK)) || return 0
    local reply
    read -r -p "$1 [y/N] " reply || return 1
    [[ $reply == [yY]* ]]
}

selected() {
    ((${#ONLY[@]})) || return 0
    local name
    for name in "${ONLY[@]}"; do
        [[ $name == "$1" ]] && return 0
    done
    return 1
}

# sudo asks once; a background loop keeps the timestamp alive so a long
# upgrade does not ask again.
start_sudo() {
    ((DRY_RUN)) && return 0
    local name needed=0
    for name in apt flatpak ollama cleanup; do
        selected "$name" && needed=1
    done
    ((needed)) || return 0
    sudo -v || { fail "sudo is required"; exit 1; }
    while kill -0 "$$" 2>/dev/null; do
        sudo -n true 2>/dev/null
        sleep 50
    done &
    SUDO_KEEPALIVE=$!
}

sec_apt() {
    local rc=0 pending
    run sudo apt-get update || rc=1
    pending=$(apt list --upgradable 2>/dev/null | tail -n +2)
    if [[ -z $pending ]]; then
        info "No apt package to upgrade"
        return $rc
    fi
    info "Pending apt upgrades:"
    printf '%s\n' "$pending"
    ((DRY_RUN)) && info "The list comes from the last apt-get update"
    # --with-new-pkgs behaves like the apt upgrade alias: new packages (such as a
    # new kernel) are installed, nothing is ever removed.
    run sudo apt-get upgrade --with-new-pkgs -y || rc=1
    return $rc
}

sec_flatpak() {
    local rc=0
    info "Pending system Flatpak updates:"
    flatpak remote-ls --system --updates --columns=application,version 2>/dev/null
    run sudo flatpak update --system -y --noninteractive || rc=1
    # The user installation is empty today, but would be updated if it were not.
    if [[ -n $(flatpak list --user --columns=application 2>/dev/null) ]]; then
        run flatpak update --user -y --noninteractive || rc=1
    fi
    return $rc
}

sec_brew() {
    local rc=0
    run brew update || rc=1
    info "Outdated Homebrew formulae:"
    brew outdated
    run brew upgrade || rc=1
    return $rc
}

sec_rust() {
    local rc=0
    run rustup update || rc=1
    if command -v cargo-install-update >/dev/null; then
        info "Outdated cargo crates:"
        cargo install-update --list
        # --locked matches how the playbook installs them (cargo install --locked).
        run cargo install-update --all --locked || rc=1
    else
        warn "cargo-update is missing, so the cargo crates were not updated (cargo install --locked cargo-update)"
    fi
    return $rc
}

sec_mise() {
    local rc=0
    info "Outdated mise tools:"
    mise outdated
    # No --bump: it would rewrite the versions in the versioned mise config.
    run mise upgrade || rc=1
    return $rc
}

sec_uv() {
    info "Outdated uv tools:"
    # Without the grep, every executable of every tool is listed too.
    uv tool list --outdated | grep -v '^- ' || info "All uv tools are up to date"
    run uv tool upgrade --all
}

sec_claude() {
    info "Current version: $(claude --version)"
    run claude update
}

sec_bun() {
    info "Current version: $(bun --version)"
    run bun upgrade
}

sec_ollama() {
    local current latest
    current=$(ollama --version 2>&1 | grep -oE '[0-9]+(\.[0-9]+)+' | head -1)
    latest=$(curl -fsS --max-time 15 https://api.github.com/repos/ollama/ollama/releases/latest \
        | jq -r '.tag_name | ltrimstr("v")')
    if [[ -z $latest || $latest == null ]]; then
        warn "Could not read the latest Ollama version"
        return 0
    fi
    # The installer restarts the ollama service, which stops any running model,
    # so it only runs when a newer release exists.
    if [[ $(printf '%s\n%s\n' "$current" "$latest" | sort -V | tail -n 1) == "$current" ]]; then
        info "Ollama $current is up to date"
        return 0
    fi
    info "Ollama $current -> $latest (the installer restarts the ollama service)"
    run bash -c 'curl -fsSL https://ollama.com/install.sh | sh'
}

# Firmware is only checked: applying it is a decision to take by hand.
sec_firmware() {
    local code output
    fwupdmgr refresh >/dev/null 2>&1
    output=$(fwupdmgr get-updates 2>&1)
    code=$?
    # fwupdmgr exits with 2 when there is nothing to update; its output is long then.
    if ((code == 0)); then
        printf '%s\n' "$output"
        warn "Firmware updates are available: run fwupdmgr update"
    elif ((code == 2)); then
        info "No firmware update available"
    else
        printf '%s\n' "$output"
        return 1
    fi
}

sec_cleanup() {
    local rc=0 removable
    removable=$(apt-get -s autoremove 2>/dev/null | grep '^Remv' || true)
    if [[ -n $removable ]]; then
        info "apt packages no longer needed:"
        printf '%s\n' "$removable"
    fi
    run sudo apt-get autoremove -y || rc=1
    if command -v flatpak >/dev/null; then
        run sudo flatpak uninstall --system --unused -y --noninteractive || rc=1
    fi
    if command -v brew >/dev/null; then
        run brew cleanup || rc=1
    fi
    if command -v uv >/dev/null; then
        run uv cache prune || rc=1
    fi
    return $rc
}

sec_checks() {
    local running newest failed
    running=$(uname -r)
    newest=$(compgen -G '/boot/vmlinuz-*' | sed 's|.*/vmlinuz-||' | sort -V | tail -n 1)
    if [[ -n $newest && $newest != "$running" ]]; then
        warn "Running kernel $running, newest installed $newest: reboot to use it"
    elif [[ -e /var/run/reboot-required ]]; then
        warn "A reboot is required"
    else
        info "No reboot needed"
    fi
    failed=$({ systemctl --failed --no-legend; systemctl --user --failed --no-legend; } 2>/dev/null)
    if [[ -n $failed ]]; then
        warn "Failed systemd units:"
        printf '%s\n' "$failed"
    else
        info "No failed systemd unit"
    fi
}

run_section() {
    local name=$1 start rc
    selected "$name" || return 0
    if [[ -n ${NEEDS[$name]:-} ]] && ! command -v "${NEEDS[$name]}" >/dev/null; then
        if ((${#ONLY[@]})); then
            warn "$name: ${NEEDS[$name]} is not installed"
        else
            info "$name: ${NEEDS[$name]} is not installed, skipped"
            SKIPPED=$((SKIPPED + 1))
        fi
        return 0
    fi
    if ! confirm "Run $name?"; then
        info "$name: skipped"
        SKIPPED=$((SKIPPED + 1))
        return 0
    fi
    header "$name"
    start=$SECONDS
    "sec_$name"
    rc=$?
    if ((rc == 0)); then
        good "$name done in $((SECONDS - start))s"
    else
        fail "$name failed (exit $rc)"
    fi
}

print_summary() {
    header "Summary"
    printf '%s\n' "${GREEN}✓ $OK ok${RESET}  ${YELLOW}⚠ $WARN warnings${RESET}  ${RED}✗ $ERR errors${RESET}  skipped: $SKIPPED"
    [[ -n $LOG ]] && info "Log: $LOG"
}

main() {
    local state_dir
    if ((DRY_RUN)); then
        info "Dry run: nothing is changed and no password is asked"
    else
        state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/system-maintenance"
        mkdir -p "$state_dir"
        LOG="$state_dir/$(date +%F_%H%M%S).log"
        find "$state_dir" -name '*.log' -mtime +90 -delete
        log "start  ${ONLY[*]:-all sections}"
    fi
    trap '[[ -n $SUDO_KEEPALIVE ]] && kill "$SUDO_KEEPALIVE" 2>/dev/null' EXIT
    start_sudo

    local section
    for section in "${SECTIONS[@]}"; do
        run_section "$section"
    done

    print_summary
    ((ERR == 0))
}

main
