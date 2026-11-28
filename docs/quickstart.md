# Quickstart

About ten minutes. You need a coding agent that supports Agent Skills (Claude Code, Codex or Goose) and a git repository to practice on.

## 1. Install

From a checkout:

```sh
git clone https://github.com/thierrypdamiba/save-point.git
cd save-point
./install.sh claude     # or codex, goose. No argument installs for every host it finds
```

You should see lines like these:

```
installed for Claude Code: ~/.claude/skills/save-point (version 0.12.0)
recall hook registered in ~/.claude/settings.json  (say 'interruptions off' to silence, or delete that entry)
done — say /save-point inside any repository
```

Run `./install.sh --help` to see every flag and host. `--dry-run` shows what an install would write and writes nothing.

The recall hook is Claude Code only. It is a small script that reads scheduling data and tells the session when a question is due. It makes no network calls.

Other install routes (curl one-liner, plugin, MCP) are in the [README](../README.md#install).

## 2. Start a new session

An agent session that was already running will not see the new skill. Close it and open a new one inside the repository you want to be quizzed on.

## 3. Run your first session

Right after you merge or commit a change, say:

```
/save-point start --diff
```

On a first run the agent offers a short setup. Answer it or decline it. Then it asks one question at a time about the change, each tied to real code. What to expect:

- You answer in your own words. Your answer is saved word for word.
- The agent says how you did and shows the evidence from the code.
- If you say "I don't know", it can give a hint or explain. That question is then marked `assisted`, not `unaided`. The two labels are kept apart in your records.
- The session ends with a save point: what you closed and what comes back later.

No repository? Use a document instead: `/save-point start --doc <file-or-folder>`.

## 4. Come back later

Closed questions return after 1, 7, 30 and 90 days. In Claude Code the hook nudges the session when something is due. You can also ask for it any time:

```
/save-point recall
```

## 5. Turn interruptions down or off

| You want | Say |
| --- | --- |
| No unprompted questions, ever | `/save-point interruptions off` |
| A pause for a while | `/save-point flow 4h` or `/save-point flow today` |
| Back to normal | `/save-point resume` or `/save-point interruptions on` |
| See your settings | `/save-point settings` |

## 6. Where your records are

In `~/.save-point/`, as plain Markdown. Do not sync or share that folder. See [security and privacy](security-and-privacy.md).

## 7. Remove it

```sh
./install.sh --uninstall claude
```

This removes the skill and the hook entry. Your records in `~/.save-point/` stay. Delete that folder yourself if you want them gone.

## Requirements and platforms

Save Point is shell scripts and Markdown. It calls only the tools below.

| Tool | Used by | Required |
| --- | --- | --- |
| `sh` (POSIX) | every script | yes |
| `awk`, `sed`, `tr`, `cut`, `grep`, `sort`, `head`, `tail`, `wc`, `date` | recall, scheduling, stats and install scripts | yes |
| `sha256sum` or `shasum` | answer, source and repository id hashes | yes, one of them |
| `git` | repository id | yes |
| `cat`, `chmod`, `cp`, `mv`, `rm`, `mkdir`, `mktemp`, `find`, `dirname`, `basename` | installer and snapshot scripts | yes |
| `python3` | installer hook merge only | only to register the recall hook |
| `iconv` | recall hook output cleanup | no. Without it the hook keeps printable ASCII only |
| Node 20 or newer | the MCP server only | only if you use the MCP server |

What is tested: Linux. CI runs the scripts and the MCP server tests on ubuntu. The MCP server is also tested on Node 20.

What is written for but not tested: macOS. The scripts have `shasum` and `date -j` branches for it. No CI job runs on macOS.

Windows is untested and not supported. Running the agent inside WSL is also untested.

## Troubleshooting

**The agent says it does not know `/save-point`.**
Start a new session after installing. Then check the file exists: `ls ~/.claude/skills/save-point/SKILL.md` (use `~/.codex/skills/` for Codex, `~/.agents/skills/` for Goose).

**The installer says "no host directories found".**
None of `~/.claude`, `~/.codex` or `~/.agents` exists. Name a host: `./install.sh claude`.

**The installer says "unknown host".**
Use `claude`, `codex`, `goose`, or no argument.

**The installer says python3 was not found.**
The skill is installed. Only the hook registration was skipped. Add the entry by hand from the [README](../README.md#unsolicited-recall-is-on-by-default-claude-code), or ignore it. Without the hook, run `/save-point recall` yourself.

**Every prompt complains about a missing `check-due.sh`.**
You deleted the skill folder by hand and left the hook entry. Remove the Save Point entry under `hooks.UserPromptSubmit` in `~/.claude/settings.json`. `./install.sh --uninstall` avoids this.

**The installer says "could not update ... safely".**
Your `~/.claude/settings.json` is not valid JSON, so the installer left it alone. The skill is installed. Fix the file, then run the installer again, or add the hook entry by hand.

**The MCP server will not start.**
It needs Node 20 or newer (`node -v`). Build it from the checkout: `cd mcp-server && npm install && npm run build`.

**You want an older version.**
`./install.sh --ref v0.9.0 claude`. Your records are not changed. Read the installed version with `cat ~/.claude/skills/save-point/VERSION`.
