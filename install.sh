#!/bin/sh
# Install the Save Point skill for one or more Agent Skills hosts.
# Usage: ./install.sh [claude|codex|goose|all]   (default: all detected hosts)
set -eu

here=$(cd "$(dirname "$0")" && pwd)
src="$here/save-point"
[ -f "$src/SKILL.md" ] || { echo "error: $src/SKILL.md not found — run from the repo root" >&2; exit 1; }
: "${HOME:?HOME must be set}"

target=${1:-all}
installed=0

install_to() {
  host=$1; base=$2
  dest="$base/save-point"
  [ -d "$base" ] || echo "note: $base did not exist — creating it; this takes effect once $host is installed"
  [ -d "$dest" ] && echo "replacing existing install at $dest"
  mkdir -p "$base"
  rm -rf "$dest"
  cp -R "$src" "$dest"
  rm -rf "$dest/features" "$dest/reference"   # maintainer docs, not runtime context
  echo "installed for $host: $dest"
  installed=$((installed + 1))
}

want() { [ "$target" = "all" ] || [ "$target" = "$1" ]; }
detected() { [ "$target" != "all" ] || [ -d "$2" ]; }

want claude && detected claude "$HOME/.claude"  && install_to "Claude Code" "$HOME/.claude/skills"
want codex  && detected codex  "$HOME/.codex"   && install_to "Codex"       "$HOME/.codex/skills"
want goose  && detected goose  "$HOME/.agents"  && install_to "Goose"       "$HOME/.agents/skills"

if [ "$installed" -eq 0 ]; then
  if [ "$target" = "all" ]; then
    echo "no host directories found (~/.claude, ~/.codex, ~/.agents) — pick one explicitly:" >&2
    echo "  ./install.sh claude|codex|goose" >&2
  else
    echo "unknown host: $target (use claude, codex, goose, or all)" >&2
  fi
  exit 1
fi

echo "done — say /save-point inside any repository"
