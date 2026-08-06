#!/bin/sh
# Install the Save Point skill for one or more Agent Skills hosts.
# Usage: ./install.sh [claude|codex|goose|all]   (default: all detected hosts)
#   or:  curl -fsSL https://raw.githubusercontent.com/thierrypdamiba/save-point/main/install.sh | sh
# When piped (no repo checkout alongside), it clones the repo to a temp dir first.
set -eu
: "${HOME:?HOME must be set}"

here=$(cd "$(dirname "$0")" && pwd)
src="$here/save-point"
if [ ! -f "$src/SKILL.md" ]; then
  command -v git >/dev/null 2>&1 || { echo "error: no local checkout and git not found" >&2; exit 1; }
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  echo "no local checkout — cloning thierrypdamiba/save-point..."
  git clone -q --depth 1 https://github.com/thierrypdamiba/save-point.git "$tmp/save-point-repo"
  src="$tmp/save-point-repo/save-point"
  [ -f "$src/SKILL.md" ] || { echo "error: clone succeeded but SKILL.md missing" >&2; exit 1; }
fi

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
  rm -rf "$dest/features" "$dest/reference" "$dest/.claude-plugin"   # maintainer docs and packaging, not runtime context
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
