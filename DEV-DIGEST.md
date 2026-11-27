# Dev digest

What is on `dev` and not yet on `main`. Written for a two-minute read.

Last updated: 2026-11-27.

## On dev now

- Working rules for contributors (AGENTS.md) and CI that also runs on `dev`.
- ROADMAP.md: ten ranked items toward team-ready software, plus six decisions that are yours.
- CHANGELOG.md with an Unreleased section.
- A CI check that the four version numbers agree, and `docs/maintenance.md`.
- A security policy (SECURITY.md) and a page on what Save Point reads, writes and sends. CI now fails if a script gains a network call.
- `./install.sh --uninstall [host]` removes the skill and the recall hook entry, and leaves your records alone. 34 installer tests run in CI. Normal installs behave as before.
- `./install.sh --ref <tag>` pins, upgrades or rolls back the install, and a `VERSION` file records what is installed. 46 installer tests in CI.
- A ten-minute quickstart with troubleshooting (docs/quickstart.md), linked from the README. CI checks it against the installer.
- A team guide (docs/teams.md): what never to share, shared machines, client separation, turning interruptions down, pinning, removal. Docs only. CI checks it against the profile template.
- CI now runs `sh -n` and `shellcheck` on all scripts. No script changed. Eval assert scripts are syntax checked only.
- A state formats page (docs/state-formats.md) that lists every field in the state files. Docs only. CI checks it against the templates.
- `eval/record-results.sh` and `eval/RESULTS.md`: a way to publish eval results from real runs, with the raw log kept. One run is recorded (s01, 1 of 1). Evals and asserts are unchanged.
- Fix: `stats.sh` now counts correctly in files with Windows line endings. Normal files give the same output.
- CI script checks moved into `scripts/test-*.sh` so you can run them locally. Same checks. No skill script changed.
- Tests for how the MCP server refuses bad requests (6 new, 9 total). Tests only.
- CI now also tests the MCP server on Node 20, the stated minimum. CI only.
- Fix: the recall hook no longer prints an error or skips the daily cap when a state file holds an absurdly large number. Normal files behave the same.
- `./install.sh --dry-run [host]` shows what an install would write and writes nothing. Normal installs are unchanged. 59 installer tests in CI.
- This digest.

The only behavior changes are the new uninstall, `--ref` and `--dry-run` options. The quickstart, team guide and state formats page are docs only. Install, question selection, grading and record formats are unchanged, so the study is not affected.

## Decisions waiting for you

See "Needs the owner" in ROADMAP.md. The most important: whether to tag a release (latest tag is v0.9.0, the version is 0.12.0), and whether to add a format marker to the state files.

## Next up

A fresh audit in run 13 added four small roadmap items (the first three are now done): a Node 20 CI leg, the recall hook fix, and an installer dry run (still to do). Roadmap item 7 still waits on your answer about a macOS runner (Needs the owner 6). A full 15 scenario eval run is worth making by someone with time and a login (about 90 model calls).
