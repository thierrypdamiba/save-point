# Security and privacy

This page lists what Save Point reads, writes and sends. It is written for someone deciding whether to allow it on a work machine. Each claim names the file that backs it, so you can check it.

Version covered: see `.claude-plugin/plugin.json`.

## The short version

- The scripts and the MCP server make no network calls. They contain no telemetry.
- The only network use is in `install.sh`, which runs `git clone` from GitHub when you run it without a local checkout (the curl one-liner). Installing from a checkout makes no network call.
- Save Point stores its state in plain Markdown under `~/.save-point`.
- The host model reads whatever the skill reads. Save Point cannot stop that.

## What it reads

| What | Who reads it | Why |
| --- | --- | --- |
| `~/.save-point/profile.md`, `scheduler.md`, `repositories/*/recall.md` (front matter only) | `save-point/scripts/check-due.sh`, the recall hook | Decide whether a recall nudge is due |
| The git remote of the current folder | `save-point/scripts/derive-repo-id.sh` | Make a stable repository ID |
| A cited source file in document mode | `save-point/scripts/hash-source.sh` | Hash it, and keep a copy |
| The skill files in `save-point/` | `mcp-server/src/skill-catalog.ts` | Serve the skill over MCP, read-only |
| The repository you ask to be quizzed on | The host model, following `SKILL.md` | Write source-grounded questions |

The last row is the large one. The host model reads repository files through the host's own tools, under the host's own permissions. Save Point adds no access of its own.

## What it writes

| What | Where | Written by |
| --- | --- | --- |
| Preferences, schedule, answers, recall state | `~/.save-point/` (directory `0700`, files `0600`, as set by the skill in `SKILL.md`) | The host model, following `SKILL.md` |
| Copies of files cited in document mode, named by SHA-256 | `~/.save-point/repositories/<id>/snapshots/` (directory `0700`, copies `0600`) | `save-point/scripts/hash-source.sh` |
| The installed skill | `~/.claude/skills/save-point`, `~/.codex/skills/save-point`, `~/.agents/skills/save-point` | `install.sh` |
| One hook entry in `~/.claude/settings.json` | Claude Code only | `install.sh`, through a temp file and rename. It leaves the file alone if the JSON is malformed |

Save Point does not write into the repository or document folder you are being quizzed on. The skill says so as an invariant, and CI checks that document mode leaves the folder unchanged (see `.github/workflows/ci.yml`, step "verify document identity and source digests").

The helper scripts `check-due.sh`, `derive-repo-id.sh`, `reschedule.sh`, `check-persona.sh`, `stats.sh` and `hash-answer.sh` write nothing to disk.

## What it sends

Nothing, by itself. There is no telemetry and no account. The scripts and the MCP server contain no network code. CI fails if a script in `save-point/scripts/`, `scripts/` or `hooks/` uses a network tool, or if the MCP server source imports a network or process module (step "verify no network use").

What the host sends is a separate matter. Your host model receives the questions, your answers, and the files it reads, and sends them to its provider under that provider's terms. If that matters for a repository, do not run Save Point on it.

## Things worth knowing

- The question prompts and importance rankings in `~/.save-point` name the sensitive parts of each codebase. Treat the folder like a note about where the risks are.
- `repository_name` and `canonical_remote` in `recall.md` can include private hostnames.
- Do not sync `~/.save-point` with dotfile tools or cloud folders unless you mean to. Sync tools ignore file permissions.
- `cross_repo_recall: off` in `profile.md` stops one repository's questions from surfacing in another.
- The recall hook runs `check-due.sh` on every prompt in Claude Code. It reads front matter only, and prints one line of JSON or nothing.
- The installer replaces the installed skill folder with a fresh copy. It does not touch `~/.save-point`.
- The curl one-liner installs whatever is on `main` at that moment. To review first, clone the repository and run `./install.sh` from the checkout.

## What this page does not claim

- It does not claim the host model keeps anything private.
- It does not claim a third party has audited the code. None has.
- It does not cover the host tools or the npm packages the MCP server depends on. The MCP server has three runtime dependencies, pinned in `mcp-server/package.json`.

## Reporting a problem

See `SECURITY.md`.
