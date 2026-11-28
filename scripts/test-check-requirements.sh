#!/bin/sh
# Tests for check-requirements.sh. Each broken copy must fail.
here=$(cd "$(dirname "$0")" && pwd)
repo=$(dirname "$here")
tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT
runs=0; pass=0
ok() { runs=$((runs+1)); if [ "$1" = "$2" ]; then pass=$((pass+1)); else echo "FAIL $3 (got $1, want $2)"; fi; }
mk() { rm -rf "$tmp/r"; mkdir -p "$tmp/r"; cp -R "$repo/docs" "$repo/hooks" "$repo/save-point" "$repo/install.sh" "$tmp/r/"; mkdir -p "$tmp/r/mcp-server"; cp "$repo/mcp-server/package.json" "$tmp/r/mcp-server/"; }
mk; sh "$here/check-requirements.sh" "$tmp/r" >/dev/null 2>&1; ok $? 0 "real repo passes"
mk; sed -i 's/`awk`, //' "$tmp/r/docs/quickstart.md"; sh "$here/check-requirements.sh" "$tmp/r" >/dev/null 2>&1; ok $? 1 "tool removed from doc"
mk; sed -i 's/`iconv`/`iconv`, `rsync`/' "$tmp/r/docs/quickstart.md"; sh "$here/check-requirements.sh" "$tmp/r" >/dev/null 2>&1; ok $? 1 "unused tool listed"
mk; sed -i 's/^## Requirements and platforms/## Other/' "$tmp/r/docs/quickstart.md"; sh "$here/check-requirements.sh" "$tmp/r" >/dev/null 2>&1; ok $? 1 "section missing"
mk; sed -i 's/Windows/Other OS/g' "$tmp/r/docs/quickstart.md"; sh "$here/check-requirements.sh" "$tmp/r" >/dev/null 2>&1; ok $? 1 "no Windows statement"
mk; echo 'curl http://x' >> "$tmp/r/save-point/scripts/stats.sh"; sh "$here/check-requirements.sh" "$tmp/r" >/dev/null 2>&1; ok $? 1 "script calls unlisted tool"
sh "$here/check-requirements.sh" a b >/dev/null 2>&1; ok $? 1 "extra args"
echo "check-requirements tests: $pass of $runs passed"
[ "$pass" = "$runs" ]
