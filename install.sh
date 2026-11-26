#!/bin/sh
# Install the Save Point skill for one or more Agent Skills hosts.
# Usage: ./install.sh [claude|codex|goose|all]   (default: all detected hosts)
#        ./install.sh --uninstall [claude|codex|goose|all]   (removes the skill and the recall hook entry;
#                                                              never touches ~/.save-point)
#   or:  curl -fsSL https://raw.githubusercontent.com/thierrypdamiba/save-point/main/install.sh | sh
# When piped (no repo checkout alongside), it clones the repo to a temp dir first.
set -eu
: "${HOME:?HOME must be set}"

mode=install
if [ "${1:-}" = "--uninstall" ]; then mode=uninstall; shift; fi
target=${1:-all}
case "$target" in
  claude|codex|goose|all) ;;
  *) echo "unknown host: $target (use claude, codex, goose, or all)" >&2; exit 1 ;;
esac

here=$(cd "$(dirname "$0")" && pwd)
src="$here/save-point"
if [ "$mode" = install ] && [ ! -f "$src/SKILL.md" ]; then
  command -v git >/dev/null 2>&1 || { echo "error: no local checkout and git not found" >&2; exit 1; }
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  echo "no local checkout — cloning thierrypdamiba/save-point..."
  git clone -q --depth 1 https://github.com/thierrypdamiba/save-point.git "$tmp/save-point-repo"
  src="$tmp/save-point-repo/save-point"
  [ -f "$src/SKILL.md" ] || { echo "error: clone succeeded but SKILL.md missing" >&2; exit 1; }
fi

installed=0

install_to() {
  host=$1; base=$2
  dest="$base/save-point"
  # Only warn when the host itself looks absent; a missing skills/ subdir
  # under an existing host dir is normal and created silently.
  [ -d "$base" ] || [ -d "$(dirname "$base")" ] || echo "note: $(dirname "$base") does not exist — installing anyway; this takes effect once $host is installed"
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

# Register the recall boundary check as a Claude Code prompt hook so spaced
# recall is delivered by default. The script itself honors every off switch
# ("interruptions off", flow mode, daily caps); non-destructive JSON merge,
# idempotent across reinstalls, and the file is written only on success.
register_claude_hook() {
  settings="$HOME/.claude/settings.json"
  if ! command -v python3 >/dev/null 2>&1; then
    echo "note: python3 not found — register the recall hook manually (snippet in the README)"
    return 0
  fi
  # A literal $HOME keeps the settings file portable; the shell expands it
  # when the hook runs.
  python3 - "$settings" '$HOME/.claude/skills/save-point/scripts/check-due.sh' <<'PY' 2>/dev/null \
    || echo "note: could not update $settings safely — register the recall hook manually (snippet in the README)"
import json, os, sys, tempfile
path, cmd = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(path):
    text = open(path).read()
    if text.strip():
        data = json.loads(text)          # malformed JSON -> abort, file untouched
hooks = data.setdefault("hooks", {})
entries = hooks.setdefault("UserPromptSubmit", [])
for e in entries:
    for h in e.get("hooks", []):
        if "save-point/scripts/check-due.sh" in h.get("command", ""):
            print("recall hook already registered in " + path)
            sys.exit(0)
entries.append({"hooks": [{"type": "command", "command": cmd}]})
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path) or ".", prefix=".save-point-")
with os.fdopen(fd, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
os.replace(tmp, path)
print("recall hook registered in " + path + "  (say 'interruptions off' to silence, or delete that entry)")
PY
}

# Remove only the entries this installer added. A settings file with no Save
# Point entry is not rewritten, so it stays byte-identical.
unregister_claude_hook() {
  settings="$HOME/.claude/settings.json"
  [ -f "$settings" ] || return 0
  command -v python3 >/dev/null 2>&1 || { echo "note: python3 not found — remove the recall hook from $settings by hand"; return 0; }
  python3 - "$settings" <<'PY' 2>/dev/null \
    || echo "note: could not update $settings safely — remove the recall hook by hand"
import json, os, sys, tempfile
path = sys.argv[1]
text = open(path).read()
if not text.strip():
    sys.exit(0)
data = json.loads(text)                  # malformed JSON -> abort, file untouched
entries = data.get("hooks", {}).get("UserPromptSubmit", [])
changed = False
kept = []
for e in entries:
    hs = e.get("hooks", [])
    left = [h for h in hs if "save-point/scripts/check-due.sh" not in h.get("command", "")]
    if len(left) != len(hs):
        changed = True
        if left:
            e["hooks"] = left
            kept.append(e)
    else:
        kept.append(e)
if not changed:
    sys.exit(0)
if kept:
    data["hooks"]["UserPromptSubmit"] = kept
else:
    del data["hooks"]["UserPromptSubmit"]
    if not data["hooks"]:
        del data["hooks"]
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path) or ".", prefix=".save-point-")
with os.fdopen(fd, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
os.replace(tmp, path)
print("recall hook removed from " + path)
PY
}

remove_from() {
  host=$1; dest="$2/save-point"
  if [ -d "$dest" ]; then
    rm -rf "$dest"
    echo "removed for $host: $dest"
    installed=$((installed + 1))
  fi
}

if [ "$mode" = uninstall ]; then
  want claude && remove_from "Claude Code" "$HOME/.claude/skills"
  want claude && unregister_claude_hook
  want codex  && remove_from "Codex"       "$HOME/.codex/skills"
  want goose  && remove_from "Goose"       "$HOME/.agents/skills"
  [ "$installed" -gt 0 ] || echo "nothing to remove"
  echo "your records in ~/.save-point were not touched"
  exit 0
fi

want claude && detected claude "$HOME/.claude"  && install_to "Claude Code" "$HOME/.claude/skills" && register_claude_hook
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
