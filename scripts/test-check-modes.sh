#!/bin/sh
# Tests scripts/check-modes.sh on fixtures, then on this repository.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fail=0; runs=0
ok() { runs=$((runs + 1)); echo "ok: $1"; }
no() { runs=$((runs + 1)); fail=$((fail + 1)); echo "FAIL: $1"; }

mkdir -p "$tmp/r/save-point/scripts"
cd "$tmp/r"
git init -q .
printf '#!/bin/sh\n' > save-point/scripts/check-due.sh
printf '#!/bin/sh\n' > install.sh
chmod 755 save-point/scripts/check-due.sh install.sh
git add -A

out=$(sh "$here/check-modes.sh" "$tmp/r" 2>&1) && rc=0 || rc=$?
{ [ "$rc" = 0 ] && echo "$out" | grep -q 'modes ok for 2'; } && ok "all executable passes" || no "all executable passes (rc=$rc: $out)"

git update-index --chmod=-x save-point/scripts/check-due.sh
out=$(sh "$here/check-modes.sh" "$tmp/r" 2>&1) && rc=0 || rc=$?
{ [ "$rc" = 1 ] && echo "$out" | grep -q 'NOT EXECUTABLE save-point/scripts/check-due.sh'; } && ok "lost bit on the hook script fails" || no "lost bit fails (rc=$rc: $out)"

git update-index --chmod=+x save-point/scripts/check-due.sh
git update-index --chmod=-x install.sh
out=$(sh "$here/check-modes.sh" "$tmp/r" 2>&1) && rc=0 || rc=$?
{ [ "$rc" = 1 ] && echo "$out" | grep -q 'NOT EXECUTABLE install.sh'; } && ok "lost bit on install.sh fails" || no "install.sh (rc=$rc: $out)"

mkdir "$tmp/empty"; (cd "$tmp/empty" && git init -q .)
sh "$here/check-modes.sh" "$tmp/empty" >/dev/null 2>&1 && no "empty repo must fail" || ok "repo with no scripts fails"

out=$(sh "$here/check-modes.sh" 2>&1) && ok "this repository passes ($out)" || no "this repository ($out)"

echo "check-modes tests: $runs run, $((runs - fail)) passed, $fail failed"
[ "$fail" = 0 ]
