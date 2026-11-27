#!/bin/sh
# Tests scripts/check-links.sh. Run from anywhere: sh scripts/test-check-links.sh. CI calls this file.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
mkdir -p "$t/docs"
printf 'x\n' > "$t/docs/b.md"
printf '[a](docs/b.md) [b](docs/b.md#top) [c](https://example.com/x) [d](#here) [e](mailto:a@b.c)\n```\n[code](nowhere.md)\n```\n' > "$t/a.md"
printf '[up](../a.md)\n' > "$t/docs/c.md"
out=$(sh "$here/check-links.sh" "$t") || { echo "FAIL good tree refused: $out"; exit 1; }
echo "$out" | grep -q 'links ok in 3 ' || { echo "FAIL count: $out"; exit 1; }
printf '[gone](docs/missing.md)\n' > "$t/d.md"
if out=$(sh "$here/check-links.sh" "$t" 2>&1); then echo "FAIL broken link accepted"; exit 1; fi
echo "$out" | grep -q 'BROKEN d.md -> docs/missing.md' || { echo "FAIL message: $out"; exit 1; }
printf '[bad](../a.md)\n' > "$t/d.md"
if sh "$here/check-links.sh" "$t" >/dev/null 2>&1; then echo "FAIL link escaping root to a missing file accepted"; exit 1; fi
# The real repository must pass.
sh "$here/check-links.sh" "$here/.." >/dev/null || { echo "FAIL repository has a broken link"; exit 1; }
echo "check-links tests passed"
