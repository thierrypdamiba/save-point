#!/bin/sh
# Delivery-boundary check, suitable as a host prompt hook (e.g. Claude Code
# UserPromptSubmit). Reads only frontmatter, honors the delivery caps, and
# emits hook JSON with a one-line nudge when recall is due — otherwise nothing.
# The skill itself still owns actual delivery, suppression, and counter updates.
# State root: $SAVE_POINT_HOME if set, else ~/.save-point.
set -eu

# A hook must fail open: exit status 2 would block the person's prompt. With no
# SAVE_POINT_HOME and no HOME there is nothing to read, so stay quiet.
root=${SAVE_POINT_HOME:-"${HOME:-}/.save-point"}
[ -n "${SAVE_POINT_HOME:-}${HOME:-}" ] || exit 0
[ -d "$root" ] || exit 0

here=$(cd "$(dirname "$0")" && pwd)
now=$(date +%s)
today=$(date +%Y-%m-%d)

# frontmatter <file> <key> -> value (CRLF-tolerant, trailing space trimmed; empty if missing)
frontmatter() {
  [ -f "$1" ] || { echo ""; return; }
  awk -v key="$2" '
    { sub(/\r$/, "") }
    /^---$/ { fence++; next }
    fence == 1 && index($0, key ":") == 1 {
      sub(/^[^:]*:[ ]*/, ""); sub(/[ \t]+$/, ""); print; exit
    }
    fence >= 2 { exit }
  ' "$1"
}

# setting <file> <key> -> frontmatter value as YAML would read it for a person's hand edit:
# one pair of surrounding quotes and a trailing " # comment" are dropped. Without this,
# `interruption_style: "manual_only"` or `daily_limit: 0 # none` would be ignored and the hook would still nudge.
setting() {
  frontmatter "$1" "$2" | sed -e 's/[ \t][ \t]*#.*$//' -e 's/[ \t]*$//' \
    -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'\$/\1/"
}

iso_to_epoch() {
  [ -n "$1" ] || { echo 0; return; }
  date -u -j -f %Y-%m-%dT%H:%M:%SZ "$1" +%s 2>/dev/null || date -u -d "$1" +%s 2>/dev/null || echo 0
}

# Non-numbers and numbers over 9 digits (which could overflow shell arithmetic) give the default.
digits_or() { case "$1" in ''|*[!0-9]*) echo "$2" ;; *) [ "${#1}" -gt 9 ] && echo "$2" || echo "$1" ;; esac; }

# Profile: manual-only means never nudge.
style=$(setting "$root/profile.md" interruption_style)
[ "$style" = "manual_only" ] && exit 0
limit=$(digits_or "$(setting "$root/profile.md" daily_limit)" 3)
# A daily limit of 0 means no unsolicited prompts, on any day.
[ "$limit" -gt 0 ] || exit 0
qpi=$(digits_or "$(setting "$root/profile.md" questions_per_interruption)" 1)
# Zero questions per interruption means no unsolicited prompts, like a daily limit of 0.
[ "$qpi" -gt 0 ] || exit 0
gap=$(setting "$root/profile.md" minimum_gap)
case "$gap" in
  *m) gap_s=$(( $(digits_or "${gap%m}" 90) * 60 )) ;;
  *h) gap_s=$(( $(digits_or "${gap%h}" 2) * 3600 )) ;;
  *) gap_s=5400 ;;   # unparseable values fall back to the 90m default
esac

# Scheduler: flow mode, daily cap, minimum gap.
flow=$(iso_to_epoch "$(setting "$root/scheduler.md" flow_until)")
[ "$flow" -gt "$now" ] && exit 0
if [ "$(setting "$root/scheduler.md" prompt_date)" = "$today" ]; then
  raw=$(setting "$root/scheduler.md" prompts_today)
  count=$(digits_or "$raw" 0)
  # An all-digit count over 9 digits is over any cap: stay quiet, do not fall back to 0.
  case "$raw" in ''|*[!0-9]*) ;; *) [ "${#raw}" -gt 9 ] && count=$limit ;; esac
  [ "$count" -ge "$limit" ] && exit 0
fi
last=$(iso_to_epoch "$(setting "$root/scheduler.md" last_prompt_at)")
# A last prompt in the future (a clock that was wrong once) must not mute the hook until that date.
[ "$last" -le "$now" ] || last=0
[ $((now - last)) -lt "$gap_s" ] && exit 0

# With cross_repo_recall off, only the current repository's queue may nudge here.
only_repo=""
if [ "$(setting "$root/profile.md" cross_repo_recall)" = "off" ]; then
  only_repo=$(sh "$here/derive-repo-id.sh" . 2>/dev/null | tail -1) || true
  [ -n "$only_repo" ] || exit 0
fi

# Recall queues: collect repositories whose next_due_at has passed.
due_names=""; due_count=0
for f in "$root"/repositories/*/recall.md; do
  [ -f "$f" ] || continue
  if [ -n "$only_repo" ]; then
    case "$f" in */"$only_repo"/recall.md) ;; *) continue ;; esac
  fi
  next=$(iso_to_epoch "$(setting "$f" next_due_at)")
  [ "$next" -gt 0 ] && [ "$next" -le "$now" ] || continue
  name=$(frontmatter "$f" repository_name | tr -d '\000-\037\177' | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
  due_names="$due_names${due_names:+, }${name:-unknown}"
  due_count=$((due_count + 1))
done
[ "$due_count" -gt 0 ] || exit 0

printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"Save Point: recall is due for %s (%s). At the next natural boundary, offer at most %s question(s) per the save-point skill; it applies suppression rules and updates scheduler.md."}}\n' \
  "$due_count repository/ies" "$due_names" "$qpi"
