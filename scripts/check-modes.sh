#!/bin/sh
# Fails when a script that is run directly has lost its executable bit in git.
# The recall hook runs save-point/scripts/check-due.sh by path, and install.sh
# is run as ./install.sh. A file committed as 100644 fails there with
# "permission denied" (exit 126), on every prompt in the hook's case.
# Usage: sh scripts/check-modes.sh [repo-root]   (default: the repository this script is in)
set -eu
root=${1:-$(cd "$(dirname "$0")/.." && pwd)}
cd "$root"
bad=0; n=0
for f in $(git ls-files 'save-point/scripts/*.sh' install.sh); do
  n=$((n + 1))
  mode=$(git ls-files -s -- "$f" | cut -d' ' -f1)
  [ "$mode" = 100755 ] || { echo "NOT EXECUTABLE $f (git mode $mode, want 100755)"; bad=1; }
done
[ "$n" -gt 0 ] || { echo "no scripts found under $root" >&2; exit 1; }
[ "$bad" = 0 ] || exit 1
echo "modes ok for $n scripts"
