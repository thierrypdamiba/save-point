# Save Point

[![ci](https://github.com/thierrypdamiba/save-point/actions/workflows/ci.yml/badge.svg)](https://github.com/thierrypdamiba/save-point/actions/workflows/ci.yml)

**The 30-second comprehension check after every AI-assisted merge.**

You just merged a PR you half-read. Everyone does now — AI writes the code, you skim the diff, CI is green, ship it. The debt is invisible: a month later you're on call for a system you can't explain. Save Point is the merge ritual that catches it while the diff is still warm:

```
you    ▸ /save-point start --diff
```

Your coding agent reads what changed and asks *you* — one source-grounded question at a time — whether you actually understood it. Your answers are recorded **verbatim and honestly labeled**, and the concepts come back on a spaced schedule (1 → 7 → 30 → 90 days) to test whether the understanding lasts. It's an [Agent Skill](https://code.claude.com/docs/en/skills): no service, no account, plain Markdown state on your machine.

By contract, it never writes into your repositories, never puts words in your mouth, and never pretends you knew something you were told (see [Alpha status](#alpha-status) for what "by contract" means).

## The five-minute version

![A Save Point --diff session: the world map, a source-grounded question, a verbatim answer, the verdict, and the closing save point](docs/save-point-demo.gif)

Right after you merge a change you only half-read — this run is drawn from a real session on Save Point's own repo, minutes after a large refactor of it landed:

```
you    ▸ /save-point start --diff

agent  ▸ The last commit is a big one — the quiz covers everything since HEAD~1.
         World map for this diff: 4 chapters, 1 map, 1 secret, 1 boss fight
         — New Game+ locked.
         Entering Chapter 1: The rename and where state lives now.
         q001 — After this change, where does a user's runtime state live,
         what files make it up, and which of them is the one file where
         your own edits are honored as configuration?

you    ▸ (answer, in your own words)

agent  ▸ Solid. You covered the top-level split, both per-repo files, and the
         rationale.

         ⋯ (three chapters and a save point later) ⋯

         Boss fight.
         q002 — A due question from repo A surfaces while you're working in
         repo B, and you answer it on the spot. Walk me through what Save Point
         does with your answer, what it deliberately refuses to do there, and
         what happens next time you open repo A — including the failure case
         where the stored record no longer checks out.
```

If that second question makes you sweat, that's the point. Sessions end at a **save point**: what you closed, chapter status, what comes back tomorrow.

## Install

One line (append `-s -- claude` to install for one host only):

```sh
curl -fsSL https://raw.githubusercontent.com/thierrypdamiba/save-point/main/install.sh | sh
```

Or as a Claude Code plugin, from inside Claude Code:

```
/plugin marketplace add thierrypdamiba/save-point
/plugin install save-point@save-point
```

Or from a checkout — Save Point is a plain skill directory, and installing is copying it where your agent looks:

```sh
git clone https://github.com/thierrypdamiba/save-point.git
cd save-point
./install.sh          # installs for every host it detects
./install.sh claude   # or pick one: claude | codex | goose
```

| Host | Skill location |
| --- | --- |
| Claude Code | `~/.claude/skills/save-point/` |
| Codex | `~/.codex/skills/save-point/` |
| Goose | `~/.agents/skills/save-point/` |

Then say `/save-point` (or just "quiz me on this repo") inside any repository — in a session started *after* the install; an already-running session won't see a newly installed skill.

To uninstall: `rm -rf ~/.claude/skills/save-point` (per host), or `/plugin uninstall save-point` if you installed as a plugin — and if you registered the recall hook below, remove it from `~/.claude/settings.json` too, or every prompt will complain about the missing script. Your answers and recall schedule live in `~/.save-point/` — delete that too if you want them gone.

### Enable unsolicited recall (Claude Code)

Out of the box, recall is served when you invoke Save Point. To get the spaced schedule delivered *to* you, register the bundled boundary check as a prompt hook — it reads only scheduling frontmatter, honors every cap, and nudges the session when something is due:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      { "hooks": [ { "type": "command", "command": "$HOME/.claude/skills/save-point/scripts/check-due.sh" } ] }
    ]
  }
}
```

Add that to `~/.claude/settings.json` — merging into your existing `hooks` key if you have one; the snippet is the whole-file shape for a fresh settings file. The skill still owns actual delivery: at most 3 prompts a day with 90-minute gaps by default, never mid-task, and `interruptions off` silences it permanently.

### What lives in `~/.save-point` — and why you shouldn't sync it

Plain Markdown you can read: your preferences, the recall schedule, and your verbatim answers. Be deliberate about it — question prompts name the load-bearing parts of each codebase, importance rankings literally tag data-loss and security paths, and `canonical_remote` records private remote hostnames. Save Point creates the directory `0700`, but dotfile sync tools don't care about your permissions: exclude `~/.save-point` from chezmoi/Mackup/iCloud unless you mean it. Consultants juggling client repos can also set `cross_repo_recall: off` so one client's questions never surface while working for another.

### Via MCP instead

For MCP clients without native Agent Skills support, the companion server distributes the same skill through the `io.modelcontextprotocol/skills` extension (MCP `2026-07-28`), with `list_skills` / `load_skill` tools and a `save-point` prompt as the legacy path. Needs Node 20+; run it from the checkout — the server resolves the skill directory relative to its own build (set `SAVE_POINT_SKILL_DIR` to serve a skill directory from somewhere else):

```sh
cd mcp-server && npm install && npm run build
```

```json
{
  "mcpServers": {
    "save-point": {
      "command": "node",
      "args": ["/absolute/path/to/save-point/mcp-server/dist/src/index.js"]
    }
  }
}
```

## Commands

| Command | Effect |
| --- | --- |
| `/save-point` | Start or resume; pending evaluations, then due recall, then new questions |
| `/save-point start --diff [ref]` | Quiz on what changed since `ref` — post-merge check, or run it on a branch as a merge gate |
| `/save-point dispute q014` | Contest a verdict: the key is re-derived with evidence shown; wrong verdicts get an `amended` entry |
| `/save-point start [--level new-engineer\|maintainer\|operator]` | Full playthrough, optionally at an explicit difficulty |
| `/save-point recall` | Serve due recall now, across repositories (unless `cross_repo_recall` is off) |
| `/save-point setup` / `settings` | Configure / inspect preferences |
| `/save-point repetition intensive\|adaptive` | Daily 30-day drilling vs. spaced (1 → 7 → 30 → 90 days) |
| `/save-point flow 4h` / `flow today` / `resume` | Pause interruptions; resume them |
| `/save-point interruptions off\|on` | Manual-only recall, permanently |

Everything also works as plain conversation — "too hard", "less trivia", "spam me for 30 days", "pause questions until tomorrow". If chapters and boss fights aren't your thing, say "plain labels" and the game framing disappears. Every question carries a one-line HUD — this session's tally plus the repository's lifetime numbers — and "stats off" removes it.

## How it holds the line

- **Your words only.** `~/.save-point/` holds plain Markdown you can read: your verbatim answers (`savepoint.md`), the recall schedule (`recall.md`), your preferences, and nothing generated in your voice.
- **Honest labels.** Any assistance — a hint, a source trail, an explanation — marks the work `assisted`, permanently. Asking to be taught after a question closes is free and encouraged; it just can't advance your recall stage.
- **No answer leaks.** While a question is open the agent probes; it never confirms, completes, or reveals *for free* — a full explanation is always one ask away, but taking it marks the attempt `assisted`. A bare guess can't buy a confirmation.
- **Polite by contract.** Unsolicited recall: at most 3 prompts a day with 90-minute gaps by default (both tunable), only at natural boundaries (tests pass, commits land), never during focused work — and never once you say `interruptions off`.
- **The grader is on the record too.** LLM verdicts can be wrong, so wrong verdicts are appealable: `/save-point dispute` re-derives the answer key with the evidence shown openly, and a vindicated dispute costs you nothing. And when a teammate's refactor invalidates an old answer, the close is `superseded` — reset and relearn — never `failed`, because the world changing is not you forgetting.
- **One identity everywhere.** `save-point/scripts/derive-repo-id.sh` derives the same repository ID on every host, so your history follows you across Claude Code, Codex, and Goose — the one thing a built-in platform feature will never give you. Deterministic bookkeeping (scheduling math, digests, due checks) ships as scripts, not model improvisation.

The behavior contract lives in [`save-point/features/`](save-point/features) as Gherkin scenarios; [`save-point/SKILL.md`](save-point/SKILL.md) is the runtime contract itself.

## Alpha status

This is an alpha. Tested end-to-end on Claude Code (live multi-session runs, including `--diff`); the MCP server has an automated test suite (`cd mcp-server && npm test`). Known limitations:

- Contract enforcement is only as strong as the host model following it — so it's measured, not asserted: [`eval/`](eval) replays scripted sessions against the live skill and asserts on the state files it produces (currently 9 scenarios, 96 assertions, passing on the default model — including answer-leak refusal, dispute handling, code drift, and the full cross-repo pending flow). Publishing per-model pass rates is the next milestone.
- Identity follows the remote, so adding a first remote or renaming one re-keys a repository. The contract now includes a migration offer (scan for the previous identity, move the history), but it's young.
- Unsolicited recall needs the prompt hook above (Claude Code) or host boundary events; without either, recall is served on invocation only.
- Codex and Goose install paths are wired but not yet battle-tested.

Issues and war stories welcome.

## License

[MIT](LICENSE)
