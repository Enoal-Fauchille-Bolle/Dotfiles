#!/bin/sh
# dconf-apply.sh <dconf path> <ini file>
# Loads the ini file into the dconf path only when at least one key in the
# file is missing or different in the live database. Prints "changed" or
# "unchanged" so Ansible can report the right state.
set -eu
path="$1"
file="$2"

if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    exec dbus-run-session -- "$0" "$@"
fi

current=$(dconf dump "$path")
section=""
needs_load=0
while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
        ''|'#'*) continue ;;
        '['*) section="$line"; continue ;;
    esac
    # Strings go through the environment: awk -v would interpret backslash
    # escapes inside long JSON values.
    if ! printf '%s\n' "$current" | section="$section" line="$line" awk '
        BEGIN { s = ENVIRON["section"]; l = ENVIRON["line"] }
        /^\[/ { in_section = ($0 == s) ; next }
        in_section && $0 == l { found = 1 }
        END { exit !found }'; then
        needs_load=1
        break
    fi
done < "$file"

if [ "$needs_load" -eq 0 ]; then
    echo unchanged
    exit 0
fi
dconf load "$path" < "$file"
echo changed
