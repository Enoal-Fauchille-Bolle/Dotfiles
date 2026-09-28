#!/usr/bin/env bash
# UserPromptSubmit hook: inject a budget line, but only when a threshold is crossed.
#
# Why this exists. Claude cannot see how full its own context window is: no hook
# receives that number, and the request to expose it is still open upstream
# (anthropics/claude-code#27969). A rule in CLAUDE.md saying "warn me past 30%"
# is therefore unenforceable — Claude would be guessing. This hook supplies the
# measurement so the rule becomes real.
#
# Why UserPromptSubmit and nothing else. It is the only event whose stdout is
# "added as context Claude sees and can act on"; every other event's output goes
# to the debug log. It also fires at the right instant — before the expensive
# request, not after it.
#
# Silence is the design. Below every threshold the hook prints nothing at all,
# so it costs zero tokens on the vast majority of prompts. A warning that fires
# constantly is a warning that gets ignored.
#
# One fact, one home: this file reports *which* thresholds tripped and never what
# to do about it. The policy lives in ~/.claude/CLAUDE.md, which is re-injected
# from disk after every compaction and costs nothing to keep there.

set -uo pipefail

# ── Thresholds. Overridable from the environment; defaults are Enoal's measured
# ── ones (see CLAUDE-CHEATSHEET.md §2), not round numbers.
CTX_DECISION=${BUDGET_CTX_DECISION:-150000}   # decide: same task -> /compact, new task -> /clear
CTX_STOP=${BUDGET_CTX_STOP:-300000}           # 32% of spend, zero return
COST_WARN=${BUDGET_COST_WARN:-15}             # ~1/3 of a 5h window in one conversation
PACE_GAP=${BUDGET_PACE_GAP:-10}               # points ahead of the pace: the status line's red
QUOTA_HARD=${BUDGET_QUOTA_HARD:-90}           # past this, the pace no longer matters
FIVE_WARN=${BUDGET_FIVE_WARN:-70}             # fallback when no reset time is known
SEVEN_WARN=${BUDGET_SEVEN_WARN:-80}           # fallback when no reset time is known
CACHE_MIN=${BUDGET_CACHE_MIN:-100000}         # a cold cache only matters on a big context
CACHE_TTL=${CLAUDE_CACHE_TTL:-3600}           # 1h on a subscription, 5min on credits
STATE_MAX_AGE=${BUDGET_STATE_MAX_AGE:-900}    # status line output older than this is stale

STATE_DIR="$HOME/.claude/state"

input=$(cat)
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$transcript" ] || exit 0

now=$(date +%s)
pct= tokens=0 window=0 cost=0 five= seven= five_reset= seven_reset= cache_expiry=0

# ── Preferred sensor: whatever the status line last published ──────────────────
# These are the payload's own figures, and they are the only source for the 5h
# and 7d quotas — those exist nowhere else on this machine.
state="$STATE_DIR/ctx-$(basename "$transcript" .jsonl).txt"
if [ -f "$state" ]; then
  age=$(( now - $(stat -c %Y "$state" 2>/dev/null || echo 0) ))
  if [ "$age" -le "$STATE_MAX_AGE" ]; then
    # Trusted input we wrote ourselves, but still parsed key by key rather than
    # sourced, so a mangled file cannot execute anything.
    while IFS='=' read -r k v; do
      case "$k" in
        pct) pct=$v ;; tokens) tokens=${v:-0} ;; window) window=${v:-0} ;;
        cost) cost=${v:-0} ;; five) five=$v ;; seven) seven=$v ;;
        five_reset) five_reset=$v ;; seven_reset) seven_reset=$v ;;
        cache_expiry) cache_expiry=${v:-0} ;;
      esac
    done < "$state"
  fi
fi

# ── Fallback sensor: the transcript itself ─────────────────────────────────────
# The status line only redraws when Claude Code repaints, so an idle pane
# publishes stale numbers. The last assistant turn's three input buckets are
# disjoint, so their sum is the exact prompt size that the next request resends.
# Sidechain turns are a subagent's context, not this one's, hence the filter.
if [ "${tokens:-0}" -eq 0 ] 2>/dev/null && [ -f "$transcript" ]; then
  last=$(tail -c 1000000 "$transcript" 2>/dev/null \
         | grep '"type":"assistant"' | grep -v '"isSidechain":true' | tail -1)
  if [ -n "$last" ]; then
    tokens=$(printf '%s' "$last" | jq -r '
      [.message.usage.input_tokens,
       .message.usage.cache_creation_input_tokens,
       .message.usage.cache_read_input_tokens] | map(. // 0) | add' 2>/dev/null)
  fi
fi
[ -n "${tokens:-}" ] && [ "$tokens" -gt 0 ] 2>/dev/null || exit 0

# Same derivation as the status line's cache countdown: no cache field exists in
# any payload, so it is the age of the last thing written to the transcript.
if [ "${cache_expiry:-0}" -eq 0 ] 2>/dev/null && [ -f "$transcript" ]; then
  ts=$(tail -c 65536 "$transcript" 2>/dev/null \
       | grep -oE '"timestamp":"[^"]+"' | tail -1 | cut -d'"' -f4)
  [ -n "$ts" ] && cache_expiry=$(( $(date -d "$ts" +%s 2>/dev/null || echo 0) + CACHE_TTL ))
fi

[ "${window:-0}" -gt 0 ] 2>/dev/null || window=1000000
[ -n "$pct" ] || pct=$(( tokens * 100 / window ))

# ── Which thresholds tripped ───────────────────────────────────────────────────
tripped=()
[ "$tokens" -ge "$CTX_STOP" ] && tripped+=("CONTEXTE_STOP") \
  || { [ "$tokens" -ge "$CTX_DECISION" ] && tripped+=("CONTEXTE_DECISION"); }
awk -v c="$cost" -v t="$COST_WARN" 'BEGIN{exit !(c+0>=t+0)}' && tripped+=("COUT")

# Pace: the share of the window already elapsed, i.e. where usage would sit if
# the quota were spent evenly until the reset -- the status line's blue marker,
# recomputed here at prompt time. A raw 73% is fine three hours into a 5h
# window; what matters is the gap to the pace. So a quota trips when usage runs
# more than PACE_GAP points ahead of it (the status line's red), or past
# QUOTA_HARD whatever the pace, since one large request can then hit the limit.
# Without a reset time there is no pace, and the old fixed threshold applies.
# Usage: quota_gap <pct> <reset_epoch> <window_secs>; prints "pace gap", or
# nothing when the pace is unknown.
quota_gap() {
  local pct=$1 reset=$2 win=$3 pace
  [ -n "$reset" ] && [ "$reset" -gt 0 ] 2>/dev/null || return 0
  pace=$(( (win - (reset - now)) * 100 / win ))
  [ "$pace" -lt 0 ] && pace=0
  [ "$pace" -gt 100 ] && pace=100
  echo "$pace $(( pct - pace ))"
}
# Usage: quota_trips <pct> <gap_or_empty> <fallback_threshold>
quota_trips() {
  local pct=$1 gap=$2 fallback=$3
  [ -n "$pct" ] && [ "$pct" -ge 0 ] 2>/dev/null || return 1
  [ "$pct" -ge "$QUOTA_HARD" ] && return 0
  if [ -n "$gap" ]; then [ "$gap" -gt "$PACE_GAP" ]
  else [ "$pct" -ge "$fallback" ]; fi
}
five_pace= five_gap= seven_pace= seven_gap=
[ -n "$five" ]  && read -r five_pace five_gap   < <(quota_gap "$five"  "$five_reset"  18000)
[ -n "$seven" ] && read -r seven_pace seven_gap < <(quota_gap "$seven" "$seven_reset" 604800)
quota_trips "$five"  "$five_gap"  "$FIVE_WARN"  && tripped+=("QUOTA_5H")
quota_trips "$seven" "$seven_gap" "$SEVEN_WARN" && tripped+=("QUOTA_7D")
cold=0
[ "$cache_expiry" -gt 0 ] && [ "$now" -ge "$cache_expiry" ] \
  && [ "$tokens" -ge "$CACHE_MIN" ] && { cold=1; tripped+=("CACHE_FROID"); }

[ ${#tripped[@]} -gt 0 ] || exit 0

# ── Report. Data only; the obligations attached to each name are in CLAUDE.md ──
line="contexte $(( tokens / 1000 ))k (${pct}%)"
awk -v c="$cost" 'BEGIN{exit !(c+0>0)}' && line="$line · \$$(printf '%.2f' "$cost")"
# The gap is printed signed, like the status line: -4 is margin, +12 is ahead.
fmt_quota() {
  local label=$1 pct=$2 pace=$3 gap=$4 s
  [ -n "$pct" ] || return 0
  if [ -n "$gap" ]; then
    s=$gap; [ "$gap" -gt 0 ] && s="+$gap"; [ "$gap" -eq 0 ] && s="±0"
    printf ' · %s %s%% (rythme %s%%, %s)' "$label" "$pct" "$pace" "$s"
  else
    printf ' · %s %s%%' "$label" "$pct"
  fi
}
line="$line$(fmt_quota 5h "$five" "$five_pace" "$five_gap")"
line="$line$(fmt_quota 7d "$seven" "$seven_pace" "$seven_gap")"
[ "$cold" -eq 1 ] && line="$line · cache froid depuis $(date -d "@$cache_expiry" +%H:%M)"

printf '[budget] %s\n' "$line"
printf '[budget] seuils franchis : %s\n' "$(IFS=,; echo "${tripped[*]}")"

# ── Housekeeping ───────────────────────────────────────────────────────────────
# State files outlive their sessions. Sweep at most once a day so the common path
# stays two stats and a printf.
sweep="$STATE_DIR/.last-sweep"
if [ ! -f "$sweep" ] || [ $(( now - $(stat -c %Y "$sweep" 2>/dev/null || echo 0) )) -gt 86400 ]; then
  find "$STATE_DIR" -maxdepth 1 -name 'ctx-*.txt' -mtime +7 -delete 2>/dev/null
  touch "$sweep" 2>/dev/null
fi

exit 0
