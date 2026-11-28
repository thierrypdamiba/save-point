# Dev digest

What is on `dev` and not yet on `main`. Written for a two-minute read.

Last updated: 2026-11-28 (run 44).

## On dev now

- Fix: the recall nudge now names at most 5 repositories and says how many more are due. Before, someone with many repositories paid for a long line on every prompt.
- Eval: the full 15 scenario eval was run once and recorded: 15 of 15 passed on the default model. One run is not a pass rate, and model replies vary. Also fixed `eval/record-results.sh`, which was not executable.
- Fix: if you wrote a repository name in quotes or with a note in `recall.md`, the recall nudge showed the quotes and the note. It now shows the plain name.
- Fix: the repository id, answer digest and stats scripts now refuse extra arguments with one usage line. Before, a second path was silently ignored, which could send records to the wrong folder. Correct calls are unchanged.
- Docs only: a fresh audit found no new defect in the code. It added one small roadmap item (three scripts silently ignore extra arguments) and one question for you, Needs the owner 9: the recall hook adds its nudge to every prompt until a question is delivered. Nothing you run changed.
- CI only: a check that the recall hook script and the installer keep their executable bit. If it were lost, the hook would error on every prompt. Both are fine today.
- Fix: if you saved `profile.md` in an editor that adds a hidden byte-order mark (some Windows editors do), the recall hook ignored the whole file, including a `manual_only` opt-out. It now reads those files correctly.
- Fix: the stats numbers now read a recall field a person put in quotes, such as `stage: "2"`. Before, that stage was missed.
- Fix: `minimum_gap: 3H` (capital unit) was read as the 90 minute default, so the hook nudged sooner than you asked. It now reads `3H` and `90 M` the same as `3h` and `90m`.
- Fix: the MCP server now refuses to start, with a clear message, if its skill folder path is wrong. Before, it started and every client saw only "Internal server error".
- Fix: the recall hook could block your prompt if `minimum_gap` had a leading zero, such as `08m`. It now reads that as 8 minutes.
- Fix: the answer digest script now gives a plain one line error for a mistyped file path. Digests are unchanged.
- Tests only: the recall hook output is now checked as valid JSON for odd repository names. Nothing you run changed.
- CI only: a check that fails when a link in a Markdown file points at a missing file. All links are fine today. Plus one new question for you in ROADMAP.md item 38: what `daily_limit: off` should mean.
- Fix: the stats numbers now read a recall field you annotated by hand, such as `stage: 2 # note`. Before, that stage was missed.
- Fix: the stats numbers now count a heading you annotated by hand with an HTML comment at the end. Before, that close was left out.
- Fix: `./install.sh claude --dry-run` used to ignore the flag and install for real. The installer now refuses any argument after the host. Flags before the host work as before.
- Fix: a typo in `cross_repo_recall` (for example `false`) now keeps repositories separate in the recall hook instead of letting another repository's name show up. `on` and `off` behave as before.
- Fix: a typo in `interruption_style` (for example `manual-only`) now keeps the recall hook quiet instead of leaving nudges on.
- Fix: `questions_per_interruption: 0` now turns unsolicited prompts off, as `daily_limit: 0` does. More tests for the recall hook's quiet rules.
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
- Fix: the recall hook now stays quiet instead of blocking your prompt when `HOME` is unset, and keeps its JSON valid for odd repository names. Normal setups behave the same.
- Fix: the recall hook now works when your home folder has a space in its path. Before, it errored on every prompt. Existing installs keep the old entry until you uninstall and install again. 64 installer tests in CI.
- Fix: the MCP server now starts when its skill file has Windows line endings. Before, it stopped at startup. Tests only plus a one line regex change.
- Fix: the installer no longer breaks a symlinked `~/.claude/settings.json` (dotfile managers). It edits the linked file and keeps its permissions. 71 installer tests in CI.
- `./install.sh --help` and `-h` now show the flags and hosts instead of an error. 89 installer tests in CI.
- Fix: a custom persona in a non-English language is no longer refused as too long when no locale is set. English text behaves the same.
- This digest.

The only behavior changes are the new uninstall, `--ref` and `--dry-run` options. The quickstart, team guide and state formats page are docs only. Install, question selection, grading and record formats are unchanged, so the study is not affected.
- Audit only: two new small items in ROADMAP.md (`install.sh --help` fails today; the repo id script shows a raw git error outside git). No code changed.
- Fix: `stats.sh` now reports an error for a path that is not a directory. Before, a typo gave a block of zeros that looked like real stats. Real directories behave the same.
- Test only: `scripts/test-hash-answer.sh` pins the answer digest for fixed inputs, so a change to how answers are hashed fails CI. No script changed.
- Test only: `scripts/test-hash-source.sh` covers the source hash and snapshot script, which had no test. No script changed. One open question for you in ROADMAP.md item 27.
- Fix: the recall hook no longer goes silent when `last_prompt_at` holds a date in the future (a wrong clock). Normal behavior is unchanged.

## Decisions waiting for you

See "Needs the owner" in ROADMAP.md. The most important: whether to tag a release (latest tag is v0.9.0, the version is 0.12.0), and whether to add a format marker to the state files.
- Fix: the repository id script now says to use `--doc` when run outside a git repository, instead of a raw git error. Ids are unchanged.
- Fix: setting `daily_limit: 0` now really turns off recall nudges. Before, one still came each day. Other limits behave the same.

## Next up

A fresh audit in run 13 added four small roadmap items (the first three are now done): a Node 20 CI leg, the recall hook fix, and an installer dry run (still to do). Roadmap item 7 still waits on your answer about a macOS runner (Needs the owner 6). A full 15 scenario eval run is worth making by someone with time and a login (about 90 model calls).
- Fix: the recall hook now honors hand-edited profile values written with YAML quotes or a trailing comment, such as `interruption_style: "manual_only"`. Before, that opt-out was ignored. Bare values behave the same.
