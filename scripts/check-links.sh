#!/bin/sh
# Fails when a relative link in a tracked Markdown file points at a path that does not exist.
# Usage: sh scripts/check-links.sh [repo-root]   (default: the repository this script is in)
# Checks inline links like [text](path) and [text](path#anchor). Skips http, https, mailto and
# pure #anchor links. Anchors are not checked. Links inside fenced code blocks are skipped.
set -eu
root=${1:-$(cd "$(dirname "$0")/.." && pwd)}
cd "$root"
bad=0; n=0
if git rev-parse --git-dir >/dev/null 2>&1; then files=$(git ls-files '*.md'); else files=$(find . -name '*.md' | sed 's|^\./||'); fi
for f in $files; do
  [ -f "$f" ] || continue
  d=$(dirname "$f"); n=$((n + 1))
  links=$(awk '/^```/ { fence = !fence; next } !fence' "$f" | grep -o '\]([^)]*)' | sed 's/^](//; s/)$//' || true)
  [ -n "$links" ] || continue
  printf '%s\n' "$links" | while IFS= read -r l; do
    l=${l%% *}; l=${l%%#*}
    case "$l" in ''|http://*|https://*|mailto:*) continue ;; esac
    [ -e "$d/$l" ] || echo "BROKEN $f -> $l"
  done > "${TMPDIR:-/tmp}/check-links.$$" || true
  if [ -s "${TMPDIR:-/tmp}/check-links.$$" ]; then cat "${TMPDIR:-/tmp}/check-links.$$"; bad=1; fi
done
rm -f "${TMPDIR:-/tmp}/check-links.$$"
[ "$bad" = 0 ] || exit 1
echo "links ok in $n Markdown files"
