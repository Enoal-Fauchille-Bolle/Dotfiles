#!/usr/bin/env bash
# Claude Code status line: RGB gradient, dynamic emoji, cost, code velocity

input=$(cat)

# ── Colors ──
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
MAGENTA='\033[35m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Truecolor helper ──
rgb() { printf '\033[38;2;%d;%d;%dm' "$1" "$2" "$3"; }

# ── Fixed-width green→red gradient progress bar for a 0-100 percentage ──
# Usage: make_bar <percent> <width>. Emits full blocks for the filled part and
# dim blocks for the rest. Mixes real ESC bytes (from rgb) with literal \033
# escapes; both are resolved by the final `printf '%b'`.
make_bar() {
  local pct=$1 width=$2 i pos r g b adj filled out=""
  filled=$(( (pct * width + 50) / 100 ))
  for (( i=0; i<width; i++ )); do
    pos=$(( i * 100 / (width - 1) ))
    if [ "$pos" -le 50 ]; then
      r=$(( 0 + 220 * pos / 50 )); g=200; b=$(( 80 - 80 * pos / 50 ))
    else
      adj=$(( pos - 50 )); r=220; g=$(( 200 - 160 * adj / 50 )); b=$(( 0 + 20 * adj / 50 ))
    fi
    if [ "$i" -lt "$filled" ]; then
      out="${out}$(rgb $r $g $b)█"
    else
      out="${out}\033[38;2;60;60;60m░"
    fi
  done
  printf '%s' "${out}${RESET}"
}

# ── Compact token count: 511441 -> 511k, 1240000 -> 1.2M ──
fmt_tokens() {
  local n=$1
  if [ "$n" -ge 1000000 ]; then
    printf '%d.%dM' $(( n / 1000000 )) $(( (n % 1000000) / 100000 ))
  elif [ "$n" -ge 1000 ]; then
    printf '%dk' $(( n / 1000 ))
  else
    printf '%d' "$n"
  fi
}

# ── Compact human-readable time-until-reset from a number of seconds ──
fmt_remaining() {
  local secs=$1 d h m
  if [ "$secs" -le 0 ]; then printf 'resetting'; return; fi
  d=$(( secs / 86400 )); h=$(( (secs % 86400) / 3600 )); m=$(( (secs % 3600) / 60 ))
  if [ "$d" -gt 0 ]; then printf '%dd %dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then printf '%dh %dm' "$h" "$m"
  else printf '%dm' "$m"; fi
}

# ── Absolute clock time for an epoch, dated only as much as it needs to be ──
# Every countdown on this line is frozen at the last render: the status line only
# re-runs when Claude Code redraws, so an idle pane keeps showing a stale "42m".
# An absolute time survives that -- it is the wall clock that moves, not the text.
# Three widths, cheapest first: today needs no date at all, the coming week is
# named by its weekday, and anything beyond gets a real date -- a weekday alone
# wraps around, so a cache that died last Monday would read as tonight.
fmt_at() {
  local epoch=$1 away
  # On its own line on purpose: `local` expands every argument before assigning
  # any of them, so `local epoch=$1 away=$(( epoch - now ))` would read epoch as 0.
  away=$(( epoch - now ))
  if [ "$(date -d "@$epoch" +%F)" = "$(date -d "@$now" +%F)" ]; then
    LC_ALL=C date -d "@$epoch" +%H:%M
  elif [ "${away#-}" -le 518400 ]; then
    LC_ALL=C date -d "@$epoch" +'%a %H:%M'
  else
    LC_ALL=C date -d "@$epoch" +'%d %b %H:%M'
  fi
}

# ── Parse JSON fields ──
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
effort=$(echo "$input" | jq -r '.effort.level // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
# Absolute size of the context actually sent on the last request. The three
# input buckets are disjoint, so their sum is the real prompt size; falls back
# to used_percentage * window when current_usage is missing.
ctx_tokens=$(echo "$input" | jq -r '
  (.context_window.current_usage // {}) as $u
  | (($u.input_tokens // 0) + ($u.cache_creation_input_tokens // 0) + ($u.cache_read_input_tokens // 0)) as $sum
  | if $sum > 0 then $sum
    else ((.context_window.context_window_size // 0) * (.context_window.used_percentage // 0) / 100 | floor)
    end')
window_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
lines_add=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_del=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
transcript=$(echo "$input" | jq -r '.transcript_path // empty')

# ── The instant of this render, read once ──
# Every countdown and every absolute time below subtracts from the same value, so
# the "last updated" stamp is exactly the instant the arithmetic used.
now=$(date +%s)

# ── Prompt-cache countdown ──
# The cache holds for one hour on a subscription (five minutes once you are
# drawing on usage credits, or on an API key). Past that, the next request
# rewrites the whole context at cache-write price instead of reading it at 0.1x
# -- on a 500k conversation that is several dollars for zero work. There is no
# cache field in the payload, so derive it from the last line the transcript
# wrote: tail a fixed slice rather than parsing a file that grows to megabytes.
CACHE_TTL=${CLAUDE_CACHE_TTL:-3600}
cache_left=""
cache_expiry=""
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  last_ts=$(tail -c 65536 "$transcript" 2>/dev/null \
            | grep -oE '"timestamp":"[^"]+"' | tail -1 | cut -d'"' -f4)
  if [ -n "$last_ts" ]; then
    last_epoch=$(date -d "$last_ts" +%s 2>/dev/null)
    if [ -n "$last_epoch" ]; then
      cache_expiry=$(( last_epoch + CACHE_TTL ))
      cache_left=$(( cache_expiry - now ))
    fi
  fi
fi

# ── Git info ──
branch=""
repo=""
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
  repo=$(basename "$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null)
fi

# ── Context bar: RGB gradient, full blocks only ──
BAR_WIDTH=20

if [ -n "$used" ]; then
  used_int=$(printf '%.0f' "$used")

  # Round to nearest block
  filled=$(( (used_int * BAR_WIDTH + 50) / 100 ))

  bar=""
  for (( i=0; i<BAR_WIDTH; i++ )); do
    pos=$(( i * 100 / (BAR_WIDTH - 1) ))

    if [ "$pos" -le 50 ]; then
      r=$(( 0 + 220 * pos / 50 ))
      g=200
      b=$(( 80 - 80 * pos / 50 ))
    else
      adj=$(( pos - 50 ))
      r=220
      g=$(( 200 - 160 * adj / 50 ))
      b=$(( 0 + 20 * adj / 50 ))
    fi

    if [ "$i" -lt "$filled" ]; then
      bar="${bar}$(rgb $r $g $b)█"
    else
      bar="${bar}\033[38;2;60;60;60m░"
    fi
  done
  bar="${bar}${RESET}"

  if [ "$used_int" -ge 90 ]; then status_emoji="🚨"
  elif [ "$used_int" -ge 70 ]; then status_emoji="🔥"
  elif [ "$used_int" -ge 20 ]; then status_emoji="⚡"
  else status_emoji="🟢"; fi

  if [ "$used_int" -ge 90 ]; then pct_color="$RED"
  elif [ "$used_int" -ge 70 ]; then pct_color="$YELLOW"
  else pct_color="$GREEN"; fi

  tok_part=""
  [ -n "$ctx_tokens" ] && [ "$ctx_tokens" -gt 0 ] 2>/dev/null &&
    tok_part=" ${DIM}$(fmt_tokens "$ctx_tokens")${RESET}"

  ctx_part="📄${status_emoji} ${bar} ${pct_color}${used_int}%${RESET}${tok_part}"
else
  ctx_part="📄🟢 \033[38;2;60;60;60m░░░░░░░░░░░░░░░░░░░░${RESET} --%"
fi

# ── Cache tail on the context segment: how long that context stays cheap ──
# Deliberately glued to the token count with no "|" separator: the two numbers are
# one thought -- this much context, cheap to resume until that time. The word
# "cache" is dropped for the same reason, the position carries it. Built here, and
# not next to the rate limits it used to sit with, because line 1 is assembled
# first: bash reads an unset variable as the empty string without complaining.
cache_part=""
if [ -n "$cache_left" ]; then
  cache_at=$(fmt_at "$cache_expiry")
  if [ "$cache_left" -le 0 ]; then
    cache_part=" ${RED}❄ cold (${cache_at})${RESET}"
  elif [ "$cache_left" -le 300 ]; then
    cache_part=" ${YELLOW}🔥 $(fmt_remaining "$cache_left") → ${cache_at}${RESET}"
  else
    cache_part=" ${DIM}🔥 $(fmt_remaining "$cache_left") → ${cache_at}${RESET}"
  fi
fi

# ── Effort level: shown right after the model name, colored by intensity ──
effort_part=""
if [ -n "$effort" ]; then
  case "$effort" in
    low) effort_color="$GREEN" ;;
    medium) effort_color="$CYAN" ;;
    high) effort_color="$YELLOW" ;;
    xhigh|max) effort_color="$RED" ;;
    *) effort_color="$DIM" ;;
  esac
  effort_part=" ${DIM}${RESET}${effort_color}${effort}${RESET}"
fi

# ── Cost ──
cost_part="${YELLOW}$(printf '$%.2f' "$cost")${RESET}"

# ── Code velocity ──
velocity="${GREEN}+${lines_add}${RESET} ${RED}-${lines_del}${RESET}"

# ── Single line ──
out=""
[ -n "$repo" ] && out="${BOLD}${YELLOW}${repo}${RESET}"
[ -n "$branch" ] && out="${out:+$out }${BOLD}${CYAN}(${branch})${RESET}"
out="${out} ${DIM}|${RESET} ${MAGENTA}🤖 ${model}${RESET}${effort_part}"
out="${out:+$out ${DIM}|${RESET} }${ctx_part}${cache_part}"
out="${out} ${DIM}|${RESET} ${cost_part}"
out="${out} ${DIM}|${RESET} ${velocity}"

# ── Line 2: official plan usage limits (from the payload's rate_limits) ──
# Claude Code >= 2.1 provides the real 5-hour and 7-day rate-limit usage
# percentages plus their reset timestamps — the same figures as `/usage`.
# No external tool, no network, no dollars: read straight from stdin JSON.

# Render one limit segment: <emoji> <label> <percent> <resets_at_epoch>.
# Falls back to a dim placeholder when the percentage is absent.
build_limit() {
  local emoji=$1 label=$2 pct=$3 reset=$4 pi col bar left=""
  if [ -z "$pct" ]; then
    printf '%s' "${DIM}${emoji} ${label}: --${RESET}"
    return
  fi
  pi=$(printf '%.0f' "$pct")
  if [ "$pi" -ge 90 ]; then col="$RED"
  elif [ "$pi" -ge 70 ]; then col="$YELLOW"
  else col="$GREEN"; fi
  bar=$(make_bar "$pi" 20)
  if [ -n "$reset" ] && [ "$reset" != "null" ]; then
    left=" ${DIM}$(fmt_remaining $(( reset - now ))) left → $(fmt_at "$reset")${RESET}"
  fi
  printf '%s' "${emoji} ${label} ${bar} ${col}${pi}%${RESET}${left}"
}

five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

five_part=$(build_limit "⏳" "5h" "$five_pct" "$five_reset")
week_part=$(build_limit "📅" "7d" "$week_pct" "$week_reset")

# ── Render timestamp: the honest reference for every countdown above ──
# Nothing on this line refreshes on its own, so print when it was last drawn:
# compared against the real clock, it says how stale the percentages are.
updated_part=" ${DIM}|${RESET} ${DIM}⟳ $(date -d "@$now" +%H:%M:%S)${RESET}"

line2="${five_part} ${DIM}|${RESET} ${week_part}${updated_part}"

# ── Sensor: publish these numbers for the budget hook ──
# The status line is the only mechanism Claude Code hands live context and
# rate-limit metrics to; hooks receive neither (anthropics/claude-code#27969).
# Dropping them in a per-session state file is what lets budget-guard.sh warn
# *before* a request is sent instead of after the money is spent. Keyed by the
# transcript's basename, which is the session id, so two panes never collide.
# Runs on every redraw, so it stays a single printf into a fixed path.
if [ -n "$transcript" ]; then
  state_dir="$HOME/.claude/state"
  if mkdir -p "$state_dir" 2>/dev/null; then
    printf 'pct=%s\ntokens=%s\nwindow=%s\ncost=%s\nfive=%s\nseven=%s\ncache_expiry=%s\n' \
      "${used_int:-}" "${ctx_tokens:-0}" "${window_size:-0}" "${cost:-0}" \
      "${five_pct%%.*}" "${week_pct%%.*}" "${cache_expiry:-0}" \
      > "$state_dir/ctx-$(basename "$transcript" .jsonl).txt" 2>/dev/null
  fi
fi

printf '%b' "${out}\n${line2}"