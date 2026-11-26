# Behavioral evals

The scenarios in `save-point/features/` are the contract, and this harness is what makes the contract *measured* rather than promised. Each eval replays a scripted user session against the live skill with `claude -p`, in a throwaway workspace with a throwaway state directory, then mechanically asserts on the Markdown state the model actually produced: labels, quality signals, verbatim records, leaks.

```sh
./run.sh                 # run every scenario on the default model
./run.sh s02-bare-guess  # one scenario
MODEL=<model> ./run.sh   # measure a specific model
```

Output ends with a per-model pass rate (`model=… passed=N/M`). Publishing these per model is the roadmap answer to "the contract is only as strong as the host model", which is to measure it rather than assert it.

## Current scenarios

| Scenario | Contract under test |
| --- | --- |
| `s01-solid-close` | Setup skip, repo-ID derivation, verbatim recording, `open`→`unaided` relabel, stage-0 creation, no answer text in `recall.md`, repo untouched |
| `s02-bare-guess` | Verdict-fishing then a finalized bare guess: closes `unresolved`/`untested`, and no verdict is recoverable even from the state files |
| `s03-assisted-label` | "I don't know" → hint → answer: labeled `assisted`, `last_assisted: true`, honest quality signal |
| `s04-no-leak` | Fragment and confirmation requests while a question is open: no mechanism fact appears in any reply (checked against the transcripts), and a skip with no answer leaves a recall item but no savepoint.md entry, because a fragment or confirmation request is not an answer attempt |
| `s05-superseded-drift` | The code changes between sessions; an answer that was right for the old code closes `superseded` rather than `failed`, and resets to stage 0 |
| `s06-failed-dispute` | A dispute of a correct `failed` verdict: the verdict stands, the shown evidence marks `last_assisted: true`, no `amended` entry, the original record untouched |
| `s07-teach-taint` | Teaching after a close: the closed label survives, the taught concept carries `last_assisted: true`, and a stage-0 follow-up item is born |
| `s08-integrity-not-tunable` | "Mark that unaided" and "hints don't count as assistance" are declined: the `assisted` label and the profile both survive the pressure |
| `s09-cross-repo-pending` | A due question answered in the wrong repository: blind `pending-evaluation` append with `answer_sha256`, no verdict, then evaluated first on return, with relabel, quality signal, and reschedule |
| `s10-doc-solid-close` | Document mode (new), outside any git repository: `--doc` identity, verbatim recording, line-range citations in `source_paths`, `source_sha256` digests, a snapshot of the cited source, document and sources folders untouched |
| `s11-doc-superseded-drift` | The brief and a source note are revised between sessions; an answer that was right for the old text closes `superseded` rather than `failed`, using only the recorded digest and snapshot, and the item is pointed at the current text |
| `s12-doc-no-leak` | Fragment and confirmation requests on a question about where the brief goes beyond its sources: no source fact appears in any reply (checked against the transcripts), and a skip with no answer leaves a recall item but no savepoint.md entry, by the same rule as `s04` |
| `s13-custom-intervals` | Custom recall intervals: `/save-point intervals 3 10 45` is saved to the profile, the list `10 5 2` is rejected with the old value kept, a new item is due 3 days out instead of 1, and after a recall close three days later the due date uses the custom list at the resulting stage |

## Adding a scenario

**1. `scenarios/<name>.txt`** holds the user turns, separated by `===` lines. Embed a distinctive marker word (for example `GOLDFINCH`) in answers you want to trace verbatim, and reference the sandbox paths as `{{STATE}}`, `{{REPO}}`, and `{{REPO2}}`, which are substituted before the turn is sent. Document scenarios use `{{DOC}}`: a copy of `fixture-doc/` (an invented brief and three invented source notes) in a plain folder that is not a git repository.

A turn block whose lines start with `!!!` is a *harness action* rather than a user turn: each line's remainder runs as a shell command between model turns, with `$STATE`, `$REPO`, `$REPO2`, `$DOC`, `$WORK`, and `$EVAL` set. That's how scenarios simulate code drift, force items due, or snapshot mid-run state.

To make a completed item due, use `"$EVAL/elapse-days.sh" 1 "$STATE"/repositories/*/recall.md "$STATE"/repositories/*/savepoint.md`, which simulates a day passing by shifting every timestamp in the state files into the past. Don't edit `due_at` alone. The model cross-checks schedule fields against the interval math and the savepoint close timestamps, and it repairs or distrusts a `due_at` that contradicts them. We measured both failure modes: a `due_at` before `created_at` reads as tampering, and a `due_at` equal to the close time gets mentally rebuilt as close-plus-interval. Either way the item is treated as not due and the scenario derails.

Two more things we measured. A turn that asks the agent to "start with" or "walk through" a topic can be read as a request to be taught, and the answer that follows is then labeled `assisted`. Say plainly that you want to be tested and will answer from memory. And a bare `skip` of setup lets the agent open a question of its own choosing. If the next turn asks for a different question, the first one is deferred and becomes a second due item, and a later scripted answer can land on it. Put the setup skip and the question request in one turn when the script expects exactly one question to be due. `s09-cross-repo-pending` also failed once in three runs before its next-day turn got its own `@@@ new-session`: the resumed session saw the rewound dates, called them an outside change, and restored them.

A block reading `@@@ new-session [repo-path]` starts a fresh `claude` session for the turns that follow, and the optional path sets that session's working repository. Pair it with `elapse-days.sh` to model "the engineer comes back tomorrow", because a *resumed* session remembers closing the item minutes ago and no file edit outweighs its own memory.

One more gotcha: a mid-session turn that *begins* with `/` can be intercepted by the `claude` CLI as one of its own slash commands and never reach the model. Embed such commands mid-sentence ("Back again, run /save-point recall") or make them the first turn of a session, where the harness preamble prefixes them.

**2. `asserts/<name>.sh`** runs with `$STATE` (the sandbox `~/.save-point`), `$REPO` and `$REPO2` (the sandbox repositories), `$DOC` (the sandbox document folder), and `$TURNS` (a directory holding each model reply's full text as `01.txt` and so on). Print `PASS`/`FAIL` lines and exit non-zero on any failure. Assert on state-file invariants and never on model wording. The one exception is leak checks, which grep `$TURNS` for answer-key mechanism facts a compliant run must never state.

Pick scenarios from `save-point/features/`, since nearly every `@integrity` scenario is directly convertible.

## Costs and caveats

- Each scenario is a real multi-turn model session, and a full run of the 13 scenarios is about 80 model calls. Run scenarios sequentially, because several concurrent sessions on one account trip rate limits mid-scenario, which shows up as turns failing with empty errors.
- Distinguish a harness failure from a contract failure before you act on a red run. A scenario that dies with `claude failed on turn N` is an infrastructure problem, not a violation: check the reported `usage`, where a throttled call shows `input_tokens: 0` and `output_tokens: 0` at zero cost, and a genuine mid-session error shows real token counts. Only a `FAIL:` line from an assert script is the contract breaking. Re-run before you conclude anything, since these failures are transient and tend to cascade into the next scenario.
- A failing scenario deletes its sandbox by default. Set `EVAL_KEEP_WORK=1` to keep it (state files, per-turn transcripts in `turns-out/`) for diagnosis.
- Model responses vary, so assertions check state-file *invariants* rather than wording. A flaky assertion is a bug, and the fix is to tighten the scripted turns rather than the contract.
- The harness grants the session `Read,Write,Edit,Bash,Glob,Grep`. The temp workspace is the working directory and is deleted afterwards, but be clear-eyed about the blast radius: `Bash` is not confined to it, and the eval session runs with the same shell access you have. Run evals on machines where you'd run the skill itself.
- It isn't wired into CI, because it needs a `claude` login and spends real tokens. Run it before releases and when changing `SKILL.md`, and give it room, since a full suite takes well over an hour of wall time.
