# Contributing

Save Point's behavior is a contract, and the contract is the interesting part, so the most valuable contributions touch it.

## The one rule

The scenarios in [`save-point/features/`](save-point/features) are the behavior contract. Changes must preserve every scenario tagged `@integrity`, `@privacy`, or `@non_interruption`. If your change and a tagged scenario conflict, change the proposal, not the tag. [`save-point/reference/maintenance.md`](save-point/reference/maintenance.md) maps which feature file governs what, and lists the places prose and scripts must stay in agreement.

## What's most useful

- **War stories.** You ran it and the model leaked an answer, mislabeled assisted work, graded drift as forgetting, interrupted you mid-debug? That's a contract violation, so open an issue with the transcript. These are gold: each one becomes an eval scenario.
- **Eval scenarios.** [`eval/README.md`](eval/README.md) documents the harness (scripted turns, mechanical asserts on state files, harness actions for simulating time and code drift). Nearly every `@integrity` scenario is convertible, and coverage of a new one is a great first PR.
- **Host reports.** Codex and Goose installs are wired but less battle-tested than Claude Code. A session report covering what worked and what didn't moves them forward.

## Checks

- MCP server: `cd mcp-server && npm test`
- Scripts: CI (`.github/workflows/ci.yml`) pins fixtures for `derive-repo-id.sh`, `reschedule.sh`, `hash-answer.sh`, `check-due.sh`, and `stats.sh`. Keep them green, and keep script behavior in agreement with the prose in `SKILL.md`.
- Behavioral evals: `cd eval && ./run.sh` replays real model sessions. It needs a `claude` login and spends tokens, so it's run before releases rather than in CI. Run the scenarios your change touches.

Small fixes need no ceremony, so open the PR.
