#!/usr/bin/env bash
# Posts a Discord webhook message when this laptop's battery gets low.
set -euo pipefail

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/battery-discord/config"
[[ -r "$CONFIG" ]] || exit 0
# shellcheck source=/dev/null
source "$CONFIG"
[[ -n "${WEBHOOK_URL:-}" ]] || exit 0

LOW="${LOW:-20}"
CRITICAL="${CRITICAL:-10}"
BAT="${BAT:-/sys/class/power_supply/BAT0}"
STATE="${XDG_RUNTIME_DIR:-/tmp}/battery-discord.state"

[[ -r "$BAT/capacity" && -r "$BAT/status" ]] || exit 0
capacity=$(<"$BAT/capacity")
status=$(<"$BAT/status")
last=$(cat "$STATE" 2>/dev/null || echo none)

notify() {
    local payload
    # printf %s keeps the message as a single JSON string field
    payload=$(printf '{"username":"%s","content":"%s"}' "$HOSTNAME" "$1")
    curl -fsS --max-time 10 -X POST \
        -H 'Content-Type: application/json' \
        -d "$payload" "$WEBHOOK_URL" >/dev/null
}

# Reset the alert state as soon as the charger is back
if [[ "$status" != "Discharging" ]]; then
    if [[ "$last" != none ]]; then
        printf 'none' > "$STATE"
    fi
    exit 0
fi

if (( capacity <= CRITICAL )) && [[ "$last" != critical ]]; then
    notify ":rotating_light: Batterie critique : ${capacity}% — branche le chargeur."
    printf 'critical' > "$STATE"
elif (( capacity <= LOW )) && [[ "$last" == none ]]; then
    notify ":warning: Batterie faible : ${capacity}%."
    printf 'low' > "$STATE"
fi
