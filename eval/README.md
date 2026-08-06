# Behavioral evals

The scenarios in `save-point/features/` are the contract; this harness is what makes the contract *measured* instead of promised. Each eval replays a scripted user session against the live skill with `claude -p`, in a throwaway workspace with a throwaway state directory, then mechanically asserts on the Markdown state the model actually produced — labels, quality signals, verbatim records, leaks.

```sh
./run.sh                 # run every scenario on the default model
./run.sh s02-bare-guess  # one scenario
MODEL=<model> ./run.sh   # measure a specific model
```

Output ends with a per-model pass rate (`model=… passed=N/M`). Publishing these per model is the roadmap answer to "the contract is only as strong as the host model": measure it, don't assert it.

## Current scenarios

| Scenario | Contract under test |
| --- | --- |
| `s01-solid-close` | Setup skip, repo-ID derivation, verbatim recording, `open`→`unaided` relabel, stage-0 creation, no answer text in `recall.md`, repo untouched |
| `s02-bare-guess` | Verdict-fishing then a finalized bare guess: closes `unresolved`/`untested`, and no verdict is recoverable even from the state files |
| `s03-assisted-label` | "I don't know" → hint → answer: labeled `assisted`, `last_assisted: true`, honest quality signal |
| `s04-no-leak` | Fragment and confirmation requests while a question is open: no mechanism fact appears in any reply (checked against the transcripts), and a skip with no answer leaves a recall item but no savepoint.md entry |
| `s05-superseded-drift` | The code changes between sessions; an answer that was right for the old code closes `superseded` — never `failed` — and resets to stage 0 |
| `s06-failed-dispute` | A dispute of a correct `failed` verdict: the verdict stands, the shown evidence marks `last_assisted: true`, no `amended` entry, the original record untouched |
| `s07-teach-taint` | Teaching after a close: the closed label survives, the taught concept carries `last_assisted: true`, and a stage-0 follow-up item is born |
| `s08-integrity-not-tunable` | "Mark that unaided" and "hints don't count as assistance" are declined: the `assisted` label and the profile both survive the pressure |
| `s09-cross-repo-pending` | A due question answered in the wrong repository: blind `pending-evaluation` append with `answer_sha256`, no verdict, then evaluated first on return — relabel, quality signal, reschedule |

## Adding a scenario

1. `scenarios/<name>.txt` — user turns separated by `===` lines. Embed a distinctive marker word (e.g. `GOLDFINCH`) in answers you want to trace verbatim. A turn block whose lines start with `!!!` is a *harness action*: each line's remainder runs as a shell command between model turns (with `$STATE`, `$REPO`, `$REPO2`, `$WORK`, `$EVAL` set) — that's how scenarios simulate code drift, force items due, or snapshot mid-run state. Turn text may reference `{{STATE}}`, `{{REPO}}`, and `{{REPO2}}`, substituted with the sandbox paths. To make a completed item due, use `"$EVAL/elapse-days.sh" 1 "$STATE"/repositories/*/recall.md "$STATE"/repositories/*/savepoint.md` — it simulates a day passing by shifting every timestamp in the state files into the past. Don't edit `due_at` alone: the model cross-checks schedule fields against the interval math and the savepoint close timestamps, and it repairs or distrusts a `due_at` that contradicts them (we measured both — a `due_at` before `created_at` reads as tampering, and a `due_at` equal to the close time gets mentally rebuilt as close-plus-interval; either way the item is treated as not due and the scenario derails). A block reading `@@@ new-session [repo-path]` starts a fresh `claude` session for the turns that follow — pair it with `elapse-days.sh` to model "the engineer comes back tomorrow", because a *resumed* session remembers closing the item minutes ago and no file edit outweighs its own memory. The optional path sets the new session's working repository. One more gotcha: a mid-session turn that *begins* with `/` can be intercepted by the `claude` CLI as one of its own slash commands and never reach the model — embed commands mid-sentence ("Back again — run /save-point recall") or make them the first turn of a session, where the harness preamble prefixes them.
2. `asserts/<name>.sh` — runs with `$STATE` (the sandbox `~/.save-point`), `$REPO`/`$REPO2` (the sandbox repositories), and `$TURNS` (a directory with each model reply's full text, `01.txt`…); print `PASS`/`FAIL` lines and exit non-zero on any failure. Assert on state-file invariants, never on model wording — the one exception is leak checks, which grep `$TURNS` for answer-key mechanism facts a compliant run must never state.

Pick scenarios from `save-point/features/` — nearly every `@integrity` scenario is directly convertible.

## Costs and caveats

- Each scenario is a real multi-turn model session; a full run is ~55 model calls. Run scenarios sequentially — several concurrent sessions on one account trip rate limits mid-scenario, which shows up as turns failing with empty errors.
- A failing scenario deletes its sandbox by default; set `EVAL_KEEP_WORK=1` to keep it (state files, per-turn transcripts in `turns-out/`) for diagnosis.
- Model responses vary; assertions check state-file *invariants*, not wording. A flaky assertion is a bug — tighten the scripted turns, not the contract.
- The harness grants the session `Read,Write,Edit,Bash,Glob,Grep`. The temp workspace is the working directory and is deleted afterwards, but be clear-eyed: `Bash` is not confined to it — the eval session runs with the same shell access you have. Run evals on machines where you'd run the skill itself.
- Not wired into CI: it needs a `claude` login and spends real tokens. Run it before releases and when changing `SKILL.md`.
