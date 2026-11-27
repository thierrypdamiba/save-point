#!/bin/sh
# Install the Save Point skill for one or more Agent Skills hosts.
# Usage: ./install.sh [--ref <tag|branch>] [claude|codex|goose|all]   (default: all detected hosts)
#        --ref pins the install to a tag or branch: it always clones that ref, even from a checkout.
#        --dry-run prints what would be written and writes nothing under HOME.
#        ./install.sh --uninstall [claude|codex|goose|all]   (removes the skill and the recall hook entry;
#                                                              never touches ~/.save-point)
#   or:  curl -fsSL https://raw.githubusercontent.com/thierrypdamiba/save-point/main/install.sh | sh
# When piped (no repo checkout alongside), it clones the repo to a temp dir first.
set -eu
: "${HOME:?HOME must be set}"

mode=install
ref=""
dry=0
while [ $# -gt 0 ]; do
  case "$1" in
    --uninstall) mode=uninstall; shift ;;
    --dry-run) dry=1; shift ;;
    -h|--help)
      cat <<'U'
Usage: ./install.sh [--ref <tag|branch>] [--dry-run] [claude|codex|goose|all]
       ./install.sh --uninstall [claude|codex|goose|all]

Installs the Save Point skill. With no host it installs for every host it finds.

  --ref <tag|branch>  pin the install to a tag or branch (always clones it)
  --dry-run           print what would be written and write nothing
  --uninstall         remove the skill and the recall hook entry (Claude Code)
                      Your records in ~/.save-point are never touched.
  -h, --help          show this text

Hosts: claude, codex, goose, all
U
      exit 0 ;;
    --ref)
      [ $# -ge 2 ] && [ -n "$2" ] || { echo "error: --ref needs a tag or branch name" >&2; exit 1; }
      ref=$2; shift 2 ;;
    *) break ;;
  esac
done
[ -z "$ref" ] || [ "$mode" = install ] || { echo "error: --ref does not apply to --uninstall" >&2; exit 1; }
[ "$dry" = 0 ] || [ "$mode" = install ] || { echo "error: --dry-run does not apply to --uninstall" >&2; exit 1; }
target=${1:-all}
case "$target" in
  claude|codex|goose|all) ;;
  *) echo "unknown host: $target (use claude, codex, goose, or all)" >&2; exit 1 ;;
esac

here=$(cd "$(dirname "$0")" && pwd)
src="$here/save-point"
if [ "$mode" = install ] && { [ -n "$ref" ] || [ ! -f "$src/SKILL.md" ]; }; then
  command -v git >/dev/null 2>&1 || { echo "error: no local checkout and git not found" >&2; exit 1; }
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  repo_url=${SAVE_POINT_REPO_URL:-https://github.com/thierrypdamiba/save-point.git}   # override is for tests
  echo "cloning thierrypdamiba/save-point${ref:+ at $ref}..."
  if [ -n "$ref" ]; then
    git clone -q --depth 1 --branch "$ref" "$repo_url" "$tmp/save-point-repo" \
      || { echo "error: could not clone ref '$ref'" >&2; exit 1; }
  else
    git clone -q --depth 1 "$repo_url" "$tmp/save-point-repo"
  fi
  src="$tmp/save-point-repo/save-point"
  [ -f "$src/SKILL.md" ] || { echo "error: clone succeeded but SKILL.md missing" >&2; exit 1; }
fi

# Version of the source being installed, read from the plugin manifest.
version=$(sed -n 's/^[[:space:]]*"version":[[:space:]]*"\([^"]*\)".*/\1/p' "$(dirname "$src")/.claude-plugin/plugin.json" 2>/dev/null | head -1)
version=${version:-unknown}

installed=0

install_to() {
  host=$1; base=$2
  dest="$base/save-point"
  # Only warn when the host itself looks absent; a missing skills/ subdir
  # under an existing host dir is normal and created silently.
  [ -d "$base" ] || [ -d "$(dirname "$base")" ] || echo "note: $(dirname "$base") does not exist — installing anyway; this takes effect once $host is installed"
  if [ "$dry" = 1 ]; then
    [ -d "$dest" ] && echo "dry run: would replace existing install at $dest"
    echo "dry run: would install for $host: $dest (version $version)"
    (cd "$src" && find . -type f ! -path './features/*' ! -path './reference/*' ! -path './.claude-plugin/*' | sed 's|^\./||' | sort) \
      | while IFS= read -r f; do echo "  would write $dest/$f"; done
    echo "  would write $dest/VERSION"
    installed=$((installed + 1))
    return 0
  fi
  [ -d "$dest" ] && echo "replacing existing install at $dest"
  mkdir -p "$base"
  rm -rf "$dest"
  cp -R "$src" "$dest"
  rm -rf "$dest/features" "$dest/reference" "$dest/.claude-plugin"   # maintainer docs and packaging, not runtime context
  printf '%s\n' "$version" > "$dest/VERSION"
  echo "installed for $host: $dest (version $version)"
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
  if [ "$dry" = 1 ]; then
    if [ -f "$settings" ] && grep -q 'save-point/scripts/check-due.sh' "$settings"; then
      echo "dry run: recall hook already in $settings, would leave it as is"
    else
      echo "dry run: would add a UserPromptSubmit hook to $settings running \"\$HOME/.claude/skills/save-point/scripts/check-due.sh\""
    fi
    return 0
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    echo "note: python3 not found — register the recall hook manually (snippet in the README)"
    return 0
  fi
  # A literal $HOME keeps the settings file portable; the shell expands it
  # when the hook runs. The path is quoted so a HOME with a space still works.
  python3 - "$settings" '"$HOME/.claude/skills/save-point/scripts/check-due.sh"' <<'PY' 2>/dev/null \
    || echo "note: could not update $settings safely — register the recall hook manually (snippet in the README)"
import json, os, sys, tempfile
path, cmd = sys.argv[1], sys.argv[2]
path = os.path.realpath(path)            # a symlinked settings file (dotfile managers) stays a symlink
data = {}
if os.path.exists(path):
    text = open(path, encoding="utf-8").read()
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
with os.fdopen(fd, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
if os.path.exists(path):
    os.chmod(tmp, os.stat(path).st_mode & 0o777)   # keep the file's own permissions
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
path = os.path.realpath(sys.argv[1])     # a symlinked settings file stays a symlink
text = open(path, encoding="utf-8").read()
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
with os.fdopen(fd, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
if os.path.exists(path):
    os.chmod(tmp, os.stat(path).st_mode & 0o777)   # keep the file's own permissions
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

if [ "$dry" = 1 ]; then
  echo "dry run done, nothing was written. Your records in ~/.save-point are never touched."
  exit 0
fi
echo "done — say /save-point inside any repository"
