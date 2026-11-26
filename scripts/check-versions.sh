#!/bin/sh
# Fail if the version differs between the files that carry it.
# Usage: sh scripts/check-versions.sh [repo-root]
root=${1:-.}
ver() { sed -n "$2" "$root/$1" | head -1; }
plugin=$(ver .claude-plugin/plugin.json 's/^[[:space:]]*"version":[[:space:]]*"\([^"]*\)".*/\1/p')
pkg=$(ver mcp-server/package.json 's/^[[:space:]]*"version":[[:space:]]*"\([^"]*\)".*/\1/p')
lock=$(ver mcp-server/package-lock.json 's/^[[:space:]]*"version":[[:space:]]*"\([^"]*\)".*/\1/p')
server=$(ver mcp-server/src/server.ts 's/.*name: "save-point-skills", version: "\([^"]*\)".*/\1/p')
status=0
for pair in "plugin.json=$plugin" "package.json=$pkg" "package-lock.json=$lock" "server.ts=$server"; do
  v=${pair#*=}
  if [ -z "$v" ]; then echo "FAIL no version found in ${pair%%=*}" >&2; status=1; fi
done
for v in "$pkg" "$lock" "$server"; do
  if [ "$v" != "$plugin" ]; then status=1; fi
done
if [ "$status" -ne 0 ]; then
  echo "FAIL versions differ: plugin.json=$plugin package.json=$pkg package-lock.json=$lock server.ts=$server" >&2
  exit 1
fi
echo "version $plugin"
