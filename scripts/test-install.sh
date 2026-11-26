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

echo "install tests: $run run, $pass passed, $fail failed"
[ "$fail" = 0 ]
