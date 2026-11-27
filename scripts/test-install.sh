#!/bin/sh
# Tests for install.sh against throwaway HOME directories. Run from the repo root.
# Prints a count of checks run and passed. Exits 1 on any failure.
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
run=0; pass=0; fail=0
ok() { run=$((run + 1)); if [ "$1" = 0 ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: $2"; fi; }
check() { desc=$1; shift; "$@" >/dev/null 2>&1; ok $? "$desc"; }
nocheck() { desc=$1; shift; "$@" >/dev/null 2>&1; r=$?; [ "$r" != 0 ]; ok $? "$desc"; }
newhome() { H=$(mktemp -d); export HOME=$H; }
inst() { sh "$root/install.sh" "$@"; }
hookcount() { python3 -c 'import json,sys
d=json.load(open(sys.argv[1]))
print(sum(1 for e in d.get("hooks",{}).get("UserPromptSubmit",[]) for h in e.get("hooks",[]) if "save-point/scripts/check-due.sh" in h.get("command","")))' "$1"; }

# 1. fresh install
newhome; mkdir "$HOME/.claude"
check "fresh install exits 0" inst claude
check "skill file present" test -f "$HOME/.claude/skills/save-point/SKILL.md"
check "features dir not shipped" test ! -d "$HOME/.claude/skills/save-point/features"
check "hook registered once" test "$(hookcount "$HOME/.claude/settings.json")" = 1

# 2. second install is idempotent
inst claude >/dev/null 2>&1
check "second install keeps one hook" test "$(hookcount "$HOME/.claude/settings.json")" = 1

# 3. existing settings with other hooks and keys are kept
newhome; mkdir "$HOME/.claude"
cat > "$HOME/.claude/settings.json" <<'J'
{"model": "x", "hooks": {"UserPromptSubmit": [{"hooks": [{"type": "command", "command": "echo mine"}]}], "Stop": [{"hooks": [{"type": "command", "command": "echo stop"}]}]}}
J
inst claude >/dev/null 2>&1
check "other hook kept" grep -q 'echo mine' "$HOME/.claude/settings.json"
check "stop hook kept" grep -q 'echo stop' "$HOME/.claude/settings.json"
check "model key kept" grep -q '"model"' "$HOME/.claude/settings.json"
check "save point hook added" test "$(hookcount "$HOME/.claude/settings.json")" = 1
inst --uninstall claude >/dev/null 2>&1
check "uninstall removes hook" test "$(hookcount "$HOME/.claude/settings.json")" = 0
check "uninstall keeps other hook" grep -q 'echo mine' "$HOME/.claude/settings.json"
check "uninstall keeps stop hook" grep -q 'echo stop' "$HOME/.claude/settings.json"
check "uninstall removes skill" test ! -d "$HOME/.claude/skills/save-point"

# 4. malformed settings left untouched
newhome; mkdir "$HOME/.claude"; printf '{ not json' > "$HOME/.claude/settings.json"
cp "$HOME/.claude/settings.json" "$HOME/before"
inst claude >/dev/null 2>&1
check "install still places skill" test -f "$HOME/.claude/skills/save-point/SKILL.md"
check "malformed settings unchanged by install" cmp -s "$HOME/before" "$HOME/.claude/settings.json"
inst --uninstall claude >/dev/null 2>&1
check "malformed settings unchanged by uninstall" cmp -s "$HOME/before" "$HOME/.claude/settings.json"

# 5. install then uninstall leaves a settings file with no entry byte-identical
newhome; mkdir "$HOME/.claude"
printf '{\n  "model": "x"\n}\n' > "$HOME/.claude/settings.json"
cp "$HOME/.claude/settings.json" "$HOME/before"
inst --uninstall claude >/dev/null 2>&1
check "uninstall without an entry leaves file identical" cmp -s "$HOME/before" "$HOME/.claude/settings.json"
inst claude >/dev/null 2>&1; inst --uninstall claude >/dev/null 2>&1
check "install then uninstall leaves no hook" test "$(hookcount "$HOME/.claude/settings.json")" = 0
check "install then uninstall keeps model key" grep -q '"model"' "$HOME/.claude/settings.json"

# 6. a fresh install then uninstall with no prior settings leaves no hook entry
newhome; mkdir "$HOME/.claude"
inst claude >/dev/null 2>&1; inst --uninstall claude >/dev/null 2>&1
check "empty hooks pruned" test "$(hookcount "$HOME/.claude/settings.json")" = 0
check "no hooks key left" test "$(grep -c '"hooks"' "$HOME/.claude/settings.json")" = 0

# 7. uninstall never touches ~/.save-point
newhome; mkdir "$HOME/.claude" "$HOME/.save-point"; echo keep > "$HOME/.save-point/state"
inst claude >/dev/null 2>&1; inst --uninstall >/dev/null 2>&1
check "state file kept" test "$(cat "$HOME/.save-point/state")" = keep

# 8. single-host installs
newhome; mkdir "$HOME/.claude" "$HOME/.codex" "$HOME/.agents"
inst codex >/dev/null 2>&1
check "codex only: codex installed" test -f "$HOME/.codex/skills/save-point/SKILL.md"
check "codex only: claude not installed" test ! -d "$HOME/.claude/skills/save-point"
check "codex only: no settings written" test ! -f "$HOME/.claude/settings.json"
inst goose >/dev/null 2>&1
check "goose installed" test -f "$HOME/.agents/skills/save-point/SKILL.md"
inst --uninstall goose >/dev/null 2>&1
check "goose uninstalled" test ! -d "$HOME/.agents/skills/save-point"
check "codex untouched by goose uninstall" test -f "$HOME/.codex/skills/save-point/SKILL.md"
inst --uninstall >/dev/null 2>&1
check "uninstall all removes codex" test ! -d "$HOME/.codex/skills/save-point"

# 9. unknown host and nothing to remove
newhome; mkdir "$HOME/.claude"
nocheck "unknown host refused" inst bogus
nocheck "unknown host refused on uninstall" inst --uninstall bogus
check "uninstall with nothing installed exits 0" inst --uninstall
check "nothing-to-remove message" sh -c "sh '$root/install.sh' --uninstall | grep -q 'nothing to remove'"
newhome
nocheck "no hosts present fails" inst

# 10. pinned installs from a local fixture repo (no network)
fix=$(mktemp -d)
mkdir -p "$fix/.claude-plugin" "$fix/save-point/scripts"
printf '{\n  "version": "1.0.0"\n}\n' > "$fix/.claude-plugin/plugin.json"
echo "skill v1" > "$fix/save-point/SKILL.md"
( cd "$fix" && git init -q && git config user.email t@example.com && git config user.name t \
  && git add -A && git commit -qm v1 && git tag v1.0.0 \
  && printf '{\n  "version": "2.0.0"\n}\n' > .claude-plugin/plugin.json && echo "skill v2" > save-point/SKILL.md \
  && git add -A && git commit -qm v2 && git tag v2.0.0 ) >/dev/null 2>&1
export SAVE_POINT_REPO_URL="file://$fix"
newhome; mkdir "$HOME/.claude" "$HOME/.save-point"; echo keep > "$HOME/.save-point/state"
inst --ref v1.0.0 claude >/dev/null 2>&1
check "pinned v1 installs v1 skill" grep -q 'skill v1' "$HOME/.claude/skills/save-point/SKILL.md"
check "pinned v1 writes VERSION" test "$(cat "$HOME/.claude/skills/save-point/VERSION")" = 1.0.0
check "pinned install prints version" sh -c "sh '$root/install.sh' --ref v1.0.0 claude | grep -q 'version 1.0.0'"
inst --ref v2.0.0 claude >/dev/null 2>&1
check "upgrade to v2" grep -q 'skill v2' "$HOME/.claude/skills/save-point/SKILL.md"
check "upgrade writes VERSION 2.0.0" test "$(cat "$HOME/.claude/skills/save-point/VERSION")" = 2.0.0
inst --ref v1.0.0 claude >/dev/null 2>&1
check "rollback to v1" test "$(cat "$HOME/.claude/skills/save-point/VERSION")" = 1.0.0
check "state untouched by pin, upgrade, rollback" test "$(cat "$HOME/.save-point/state")" = keep
nocheck "missing ref refused" inst --ref nope claude
nocheck "--ref without value refused" inst --ref
nocheck "--ref with uninstall refused" inst --ref v1.0.0 --uninstall claude
check "failed ref leaves install in place" test "$(cat "$HOME/.claude/skills/save-point/VERSION")" = 1.0.0
unset SAVE_POINT_REPO_URL

# 11. a normal checkout install records its version
newhome; mkdir "$HOME/.claude"
inst claude >/dev/null 2>&1
want=$(sed -n 's/^[[:space:]]*"version":[[:space:]]*"\([^"]*\)".*/\1/p' "$root/.claude-plugin/plugin.json" | head -1)
check "checkout install writes VERSION from plugin.json" test "$(cat "$HOME/.claude/skills/save-point/VERSION")" = "$want"

# 8. dry run writes nothing and names what a real install writes
newhome; mkdir "$HOME/.claude" "$HOME/.codex"
printf '{\n  "model": "x"\n}\n' > "$HOME/.claude/settings.json"
cp "$HOME/.claude/settings.json" "$HOME/before"
T=$(mktemp -d); (cd "$HOME" && find . | sort) > "$T/before"
check "dry run exits 0" sh -c "sh '$root/install.sh' --dry-run all > '$T/out' 2>&1"
(cd "$HOME" && find . | sort) > "$T/after"
check "dry run changes no file or directory under HOME" cmp -s "$T/before" "$T/after"
check "dry run adds no skill dir" test ! -e "$HOME/.claude/skills"
check "dry run adds no codex skill dir" test ! -e "$HOME/.codex/skills"
check "dry run leaves settings identical" cmp -s "$HOME/before" "$HOME/.claude/settings.json"
check "dry run names SKILL.md path" grep -q "would write $HOME/.claude/skills/save-point/SKILL.md" "$T/out"
check "dry run names VERSION path" grep -q "would write $HOME/.claude/skills/save-point/VERSION" "$T/out"
check "dry run names the hook" grep -q 'would add a UserPromptSubmit hook' "$T/out"
check "dry run names codex target" grep -q "$HOME/.codex/skills/save-point" "$T/out"
nocheck "dry run does not list features dir" grep -q 'save-point/features/' "$T/out"
# every file a real install writes is named by the dry run
inst claude >/dev/null 2>&1
miss=0
for f in $(cd "$HOME/.claude/skills/save-point" && find . -type f | sed 's|^\./||'); do
  grep -q "would write $HOME/.claude/skills/save-point/$f\$" "$T/out" || { miss=1; echo "not named: $f"; }
done
check "dry run names every file a real install writes" test "$miss" = 0
rm -rf "$T"
newhome; mkdir "$HOME/.claude"
nocheck "dry run with uninstall is refused" inst --uninstall --dry-run claude
check "dry run with no host dirs and explicit host writes nothing" sh -c "sh '$root/install.sh' --dry-run goose >/dev/null 2>&1; test ! -e '$HOME/.agents'"

# 14. a HOME with a space: the registered hook command must still run
SP=$(mktemp -d); H="$SP/h o me"; mkdir -p "$H/.claude"; export HOME=$H
check "install into a HOME with a space exits 0" inst claude
hookcmd=$(python3 -c 'import json,sys
print(json.load(open(sys.argv[1]))["hooks"]["UserPromptSubmit"][0]["hooks"][0]["command"])' "$HOME/.claude/settings.json")
check "hook command runs with a space in HOME and exits 0" sh -c "$hookcmd"
check "hook command is quoted" test "$hookcmd" = '"$HOME/.claude/skills/save-point/scripts/check-due.sh"'
check "hooks.json quotes the plugin path" grep -q '\\"\${CLAUDE_PLUGIN_ROOT}/save-point/scripts/check-due.sh\\"' "$root/hooks/hooks.json"
check "uninstall removes the quoted entry" sh -c "sh '$root/install.sh' --uninstall claude >/dev/null 2>&1; test \"\$(grep -c check-due '$HOME/.claude/settings.json')\" = 0"
rm -rf "$SP"

# 15. a symlinked settings file stays a symlink, keeps its mode and its UTF-8 text
newhome; mkdir "$HOME/.claude" "$HOME/dot"
printf '{"note": "caf\303\251"}\n' > "$HOME/dot/settings.json"; chmod 644 "$HOME/dot/settings.json"
ln -s ../dot/settings.json "$HOME/.claude/settings.json"
check "install with a symlinked settings file exits 0" inst claude
check "settings file is still a symlink after install" test -L "$HOME/.claude/settings.json"
check "hook landed in the real file" test "$(hookcount "$HOME/dot/settings.json")" = 1
check "real file keeps mode 644" test "$(ls -l "$HOME/dot/settings.json" | cut -c1-10)" = "-rw-r--r--"
check "UTF-8 text is not escaped" grep -q 'café' "$HOME/dot/settings.json"
inst --uninstall claude >/dev/null 2>&1
check "settings file is still a symlink after uninstall" test -L "$HOME/.claude/settings.json"
check "uninstall removed the hook from the real file" test "$(hookcount "$HOME/dot/settings.json")" = 0

# 16. --help and -h print usage, exit 0 and write nothing
for flag in --help -h; do
  newhome
  check "$flag exits 0" inst "$flag"
  out=$(inst "$flag" 2>&1)
  for w in --ref --dry-run --uninstall claude codex goose all; do
    check "$flag output names $w" sh -c "printf '%s' \"\$1\" | grep -q -e \"\$2\"" _ "$out" "$w"
  done
  check "$flag writes nothing to HOME" test -z "$(ls -A "$HOME")"
done

echo "install tests: $run run, $pass passed, $fail failed"
[ "$fail" = 0 ]
