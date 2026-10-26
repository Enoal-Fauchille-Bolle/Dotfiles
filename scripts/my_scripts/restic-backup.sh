#!/usr/bin/env bash
# Backs up the paths listed in ~/.config/restic/include to the restic
# repository, applies the retention policy and reports the result to an
# Uptime Kuma push monitor. Run daily by restic-backup.timer.
# No -e: restic exit codes are handled one by one below.
set -uo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/restic"
ENV_FILE="$CONFIG_DIR/env"

# Kuma marks the monitor down at once on status=down, and after its heartbeat
# interval when no push arrives at all (the laptop stayed off, the timer died).
push() {
    [[ -n "${KUMA_PUSH_URL:-}" ]] || return 0
    # Drop the ?status=up&msg=OK&ping= that Kuma shows in the URL: a second
    # status parameter would turn it into a list and hide a status=down.
    curl -fsS --max-time 10 -G "${KUMA_PUSH_URL%%\?*}" \
        --data-urlencode "status=$1" --data-urlencode "msg=$2" >/dev/null \
        || echo "Uptime Kuma push failed" >&2
}

fail() {
    echo "$1" >&2
    push down "$1"
    exit 1
}

[[ -r "$ENV_FILE" ]] || fail "$ENV_FILE is missing"
# shellcheck source=/dev/null
source "$ENV_FILE"
for var in RESTIC_REPOSITORY RESTIC_PASSWORD AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY; do
    [[ -n "${!var:-}" ]] || fail "$var is not set in $ENV_FILE"
done

# restic only warns in the journal about a listed path that does not exist and
# still exits 0, so the Kuma message names it: a renamed folder would otherwise
# stop being backed up with the monitor still green.
missing=""
while IFS= read -r path; do
    [[ -z $path || $path == \#* || -e $path ]] || missing+="${missing:+, }$path"
done < "$CONFIG_DIR/include"

restic backup \
    --files-from "$CONFIG_DIR/include" \
    --exclude-file "$CONFIG_DIR/exclude"
status=$?

# 3 means a snapshot was saved without some unreadable files: the backup still
# happened, so it reports up with the reason in the message.
case $status in
    0) message="OK" ;;
    3) message="incomplete snapshot: some files could not be read, see journalctl --user -u restic-backup" ;;
    *) fail "restic backup failed (exit $status)" ;;
esac
[[ -n $missing ]] && message+="; not found, so not backed up: $missing"

# Grouping by host alone keeps one chain of snapshots when the include list
# changes; the default (host and paths) would start a new chain that the
# retention policy never trims. Pruning rewrites packs on B2, so only on Sundays.
forget_args=(--group-by host --keep-daily 7 --keep-weekly 4 --keep-monthly 12)
[[ $(date +%u) == 7 ]] && forget_args+=(--prune)
restic forget "${forget_args[@]}" || fail "restic forget failed (exit $?)"

push up "$message"
