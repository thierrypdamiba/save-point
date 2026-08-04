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

## Adding a scenario

1. `scenarios/<name>.txt` — user turns separated by `===` lines. Embed a distinctive marker word (e.g. `GOLDFINCH`) in answers you want to trace verbatim.
2. `asserts/<name>.sh` — runs with `$STATE` (the sandbox `~/.save-point`) and `$REPO` (the sandbox repository); print `PASS`/`FAIL` lines and exit non-zero on any failure.

Pick scenarios from `save-point/features/` — nearly every `@integrity` scenario is directly convertible.

## Costs and caveats

- Each scenario is a real multi-turn model session; a full run is ~15 model calls.
- Model responses vary; assertions check state-file *invariants*, not wording. A flaky assertion is a bug — tighten the scripted turns, not the contract.
- The harness grants the session `Read,Write,Edit,Bash,Glob,Grep`. The temp workspace is the working directory and is deleted afterwards, but be clear-eyed: `Bash` is not confined to it — the eval session runs with the same shell access you have. Run evals on machines where you'd run the skill itself.
- Not wired into CI: it needs a `claude` login and spends real tokens. Run it before releases and when changing `SKILL.md`.
