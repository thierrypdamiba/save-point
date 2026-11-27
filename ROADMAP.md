# Roadmap

Ranked by what stands between today's Save Point and software a company could adopt. Most valuable first. Sizes: small (under a day), medium (a few days), large (a week or more).

Status key: `ready` means a run can pick it up. `blocked` means it needs an owner decision first. `done` means merged to dev.

Audit date: 2026-11-26 (first audit). Items 13 to 16 added by the run 13 audit. Items 17 to 24 added by later audits. Audited: README, SKILL.md, scripts, features, eval, install.sh, mcp-server, CI, plugin files.

## Facts found in the audit

- Version `0.12.0` is written in four places by hand: `.claude-plugin/plugin.json`, `mcp-server/package.json`, `mcp-server/package-lock.json`, `mcp-server/src/server.ts`. The only git tag is `v0.9.0`. CI now checks that they agree.
- SECURITY.md and `docs/security-and-privacy.md` now exist (item 2). CHANGELOG.md exists.
- `install.sh` has an uninstall (item 3) and `--ref` pinning (item 4). It has no dry run. The curl one-liner installs whatever is on `main` unless `--ref` is given.
- The installer's hook merge is now tested (item 3).
- CI runs shell checks and the MCP tests on one OS (ubuntu). The scripts target macOS users too. `sh -n` and `shellcheck` now run in CI (item 7); there is still no macOS job.
- The eval harness is not run in CI. `eval/RESULTS.md` now holds one recorded run (s01, 1/1). The full suite is not yet recorded.
- Team use is documented in `docs/teams.md`. Fleet rollout through device management is untested.

## Items

### 1. Version consistency check in CI
- Change: add a CI step that fails if `plugin.json`, `mcp-server/package.json`, and `server.ts` carry different versions. Document the one place a maintainer edits, in `maintenance.md`.
- Benefits: the owner at release time, and anyone who installs from the plugin marketplace and expects the version they were told.
- Verify: CI fails on a branch where one file is bumped alone, and passes when all three match.
- Size: small. Status: done (dev, see CHANGELOG). Checks four files, since `package-lock.json` also carries the version.

### 2. Security and privacy statement
- Change: add SECURITY.md (how to report a problem, what is in scope) and a docs page that lists exactly what Save Point reads, writes, and sends. Files it writes, where, with what permissions. States that the tool itself has no network calls and no telemetry. Say plainly that the host model sees whatever the skill reads.
- Benefits: a security reviewer at a company deciding whether to allow it.
- Verify: each statement is backed by a grep or test in the repo. Add a CI check that the scripts contain no `curl`, `wget`, or `nc` calls.
- Size: small. Status: done (dev, see CHANGELOG). Uses GitHub private reporting. The CI check greps for network tools in scripts and network or process imports in the MCP server. `install.sh` is excluded because it runs `git clone` when piped, and the page says so.

### 3. Installer tests: hook merge, idempotency, uninstall
- Change: add CI tests for `install.sh` against a temp HOME. Cases: fresh install, second install (one hook entry only), existing settings with other hooks kept, malformed settings left untouched, single-host installs, unknown host. Add `./install.sh --uninstall [host]` that removes the skill and its hook entry, and test it.
- Benefits: anyone upgrading or removing it, and IT staff who need a clean removal.
- Verify: the new CI steps pass. Settings JSON is byte-identical after install then uninstall on a file that had no Save Point entry.
- Size: medium. Status: done (dev, see CHANGELOG). 34 checks in `scripts/test-install.sh`.

### 4. Upgrade path and pinned installs
- Change: let the installer take `--ref <tag>` so a team can pin a release. Print the installed version. Document upgrade and rollback in the README. Keeps `~/.save-point` state untouched, with a test that proves it.
- Benefits: a team lead who needs everyone on the same version, and the research study, which needs a fixed version.
- Verify: install with a ref from a local fixture repo, check the version file, check state files unchanged.
- Size: medium. Status: done (dev, see CHANGELOG). `--ref`, a `VERSION` file, and README upgrade and rollback notes. Tests use a local fixture repo through `SAVE_POINT_REPO_URL`. The curl one-liner still follows `main` (see Needs the owner 4).

### 5. Ten-minute quickstart and troubleshooting doc
- Change: add `docs/quickstart.md`: install, first session, what you will see, how to turn off interruptions, how to remove. Add a troubleshooting list: skill not found in a running session, hook complaints after uninstall, python3 missing, Node too old for the MCP server.
- Benefits: a new person on a team who has never used it.
- Verify: follow the doc from a clean temp HOME and confirm each command works as written. Record the commands tried.
- Size: small. Status: done (dev, see CHANGELOG). `docs/quickstart.md`, linked from the README. The install, uninstall, and error messages were tried in a clean temp HOME. A CI step checks the doc against `install.sh` and the README command list.

### 6. Team and admin guide
- Change: `docs/teams.md`: what is safe to share (nothing in `~/.save-point`), shared machines, how to disable the hook for everyone, how to pin a version, what to tell a team about the study. No claims about adoption.
- Benefits: an engineering manager considering a rollout.
- Verify: every setting named in the guide exists in `assets/profile.md` or the README. A CI grep checks the names.
- Size: small. Status: done (dev, see CHANGELOG). `docs/teams.md`, linked from the README. A CI step checks the setting names against `assets/profile.md` and the commands against the README.

### 7. Shell hygiene in CI
- Change: run `sh -n` on every script and `shellcheck` if it can be installed in the runner. Fix findings that do not change behavior. Add a macOS job for the script steps, since `date -d` and `shasum` differ.
- Benefits: macOS users, who are likely most of the audience, and maintainers.
- Verify: CI green on both runners. Report any finding left unfixed.
- Size: medium. Status: partly done (dev, see CHANGELOG). Done: `sh -n` on all 27 tracked `.sh` files and `shellcheck` at warning level on every script outside `eval/`, with a check that it can fail. Not done: the macOS job (blocked on Needs the owner 6), and 5 shellcheck warnings in `eval/asserts` (the string test `\>` in s05, s09, s11, and an unused variable in s13). Those files hold integrity asserts, so they are only syntax checked until someone reviews a rewrite with the owner.

### 8. Published eval pass rates
- Change: write a small script that turns `eval/run.sh` output into a dated table in `eval/RESULTS.md` with model, scenario count, and passes. Commit results only from runs someone actually made.
- Benefits: a reviewer who wants evidence that the integrity rules hold, and the owner for the study.
- Verify: the table matches the raw run output saved next to it. Needs a model CLI, so this run type may be "not run" in some environments.
- Size: medium. Status: done (dev, see CHANGELOG). `eval/record-results.sh` and `eval/RESULTS.md`. One real run is recorded so far: s01 only, 1 of 1. The full 15 scenario run has not been made. Anyone with a login can run it and record it.

### 9. Upgrade-safe state format note
- Change: document the on-disk formats of `savepoint.md`, `recall.md`, `profile.md`, `scheduler.md` and add a `format_version` check plan. Do not change the formats.
- Benefits: anyone writing tooling on top, and the study analysts who compare versions.
- Verify: the doc matches the templates in `assets/`, checked by a CI grep for each field name.
- Size: small. Status: doc part done (dev, see CHANGELOG): `docs/state-formats.md`, with a CI check that names every template field. The format marker itself stays blocked on the owner (Needs the owner 2). No format was changed.

### 10. MCP server packaging
- Change: publish-ready package: a `files` list, a `prepare` build, README instructions that do not need a checkout path. Keep it private until the owner decides.
- Benefits: MCP-only users who cannot use native skills.
- Verify: `npm pack` in CI lists the expected files and the packed server starts and answers `list_skills`.
- Size: medium. Status: blocked on the owner (publishing decision).

### 11. Stats script reads CRLF state files
- Change: make `stats.sh` ignore a trailing carriage return and trailing spaces, as `check-due.sh` already does. Found in the run 11 audit.
- Benefits: anyone on Windows or with git autocrlf, whose HUD lifetime numbers were wrong.
- Verify: a CRLF fixture gives the same counts as the LF one. 
- Size: small. Status: done (dev, see CHANGELOG). CI step `verify stats script reads CRLF files`. Run before the fix: stage2 showed 0 and a key ended in a carriage return.

### 12. Run the inline CI script checks locally
- Change: move the long inline `run:` blocks in `ci.yml` for the skill scripts into files under `scripts/` that CI calls, so a contributor can run them with `sh`. No check may be weakened in the move.
- Benefits: contributors, who today must copy shell out of YAML to test a script change.
- Verify: CI passes with the same checks. Each block runs locally to the same result.
- Size: medium. Status: done (dev, see CHANGELOG). Four files under `scripts/`: repo id and document identity, reschedule and hooks, persona, stats (LF and CRLF). Text moved unchanged. Other CI steps (network, shell hygiene, doc checks) stay inline since they grep the repo and are short.

### 13. MCP server error-path tests
- Change: add tests for the failure paths of the MCP server. Today the 3 tests only cover the working paths. Cases: `resources/directory/read` with a `..` URI, a foreign scheme, and a file URI (all must be refused); `skills/get` with an unknown URI; `load_skill` with a name other than `save-point`; a skill directory with no `SKILL.md` makes startup fail with a clear error; frontmatter without a string name or description is refused; dotfiles in the skill directory are not served.
- Benefits: a security reviewer who wants proof that the server only serves the skill directory, and a maintainer changing the catalog code.
- Verify: `npm test` runs the new cases and passes. Each refusal case fails when the guard in `skill-catalog.ts` is removed. The audit run tried the first five by hand: all behaved correctly, none are tested.
- Size: small. Status: done (dev, see CHANGELOG). 6 new tests in `mcp-server/test/errors.test.ts`. Removing the dotfile skip, the `skills/get` guard or the SKILL.md check each makes a test fail. Removing the directory prefix check alone does not: the later empty-directory check also refuses those URIs, so the prefix check is a second guard. The URIs are still tested.

### 14. Run the MCP tests on the oldest supported Node
- Change: `mcp-server/package.json` says `node >=20` and the README and quickstart tell people Node 20 works. CI only runs Node 22. Add a Node 20 leg to the CI matrix for `npm ci`, `npm run check` and `npm test`. If Node 20 fails, change the stated minimum instead.
- Benefits: an MCP-only user on Node 20, who is told it works and has no evidence.
- Verify: CI shows both legs green, or the docs and `engines` name the real minimum.
- Size: small. Status: done (dev, see CHANGELOG). Separate job `mcp-node20` in `ci.yml`. The result of the Node 20 leg is on the pull request.

### 15. Recall hook should not fail open on absurd numbers
- Change: in `save-point/scripts/check-due.sh`, a number with more than 18 digits in `daily_limit`, `prompts_today` or `minimum_gap` overflows shell arithmetic. Found in the run 13 audit: a huge `prompts_today` printed `[: Illegal number` on stderr on every prompt and the daily cap was skipped, so the nudge still fired. A huge `minimum_gap` wrapped and also let the nudge through. Make `digits_or` fall back to its default for values longer than 9 digits. The hook must still print nothing and exit 0 for any state file content.
- Benefits: anyone who hand-edits `profile.md` or `scheduler.md`, who today could get a stray error line on every prompt and a cap that does nothing. The change only touches values no honest file holds, so ordinary behavior and the study are unaffected.
- Verify: add cases to `scripts/test-reschedule.sh` (or a new `scripts/test-check-due.sh`) for each oversized field: stderr empty, exit 0, and the cap still holds. Ordinary values give the same output as before.
- Size: small. Status: done (dev, see CHANGELOG). `digits_or` now falls back to the default above 9 digits. An all-digit `prompts_today` over 9 digits counts as at the cap, so the hook stays quiet. 5 new cases in `scripts/test-reschedule.sh`. Before the fix the first case failed with `Illegal number` on stderr.

### 16. Installer dry run
- Change: `./install.sh --dry-run [host]` prints what it would copy and which settings entry it would add, and writes nothing. Test with a temp HOME that no file appears.
- Benefits: an IT reviewer who wants to see the effect before approving the install on a managed machine.
- Verify: a test compares the file tree and `settings.json` bytes before and after a dry run. Output names every path that a real install writes.
- Size: small. Status: done (dev, see CHANGELOG). A test lists HOME before and after a dry run and compares settings bytes. Another checks that every file of a real install is named in the dry run output.

### 17. Recall hook must fail open
- Change: `check-due.sh` exited 2 when neither `SAVE_POINT_HOME` nor `HOME` was set, and printed invalid JSON when a repository name held a control character such as a tab. Exit 2 blocks the person's prompt in Claude Code. Now it exits 0 quietly in the first case and strips control characters from names in the second.
- Benefits: anyone who runs the hook under a service account, container or minimal environment, and anyone with an odd repository name.
- Verify: `scripts/test-reschedule.sh` has 3 new checks. The first fails on the old script (exit nonzero with no HOME).
- Size: small. Status: done (dev, see CHANGELOG).

### 18. Recall hook command must survive a space in HOME
- Change: the installer wrote the hook command `$HOME/.claude/skills/save-point/scripts/check-due.sh` unquoted, and `hooks/hooks.json` did the same with `${CLAUDE_PLUGIN_ROOT}`. With a space in the path the shell split it and the hook failed with "not found" (exit 127) on every prompt. Both are now quoted. An existing unquoted entry is left alone, since the installer sees it as already registered.
- Benefits: anyone whose home folder or plugin folder has a space in it, who got an error on every prompt.
- Verify: `scripts/test-install.sh` has 5 new checks that install into a HOME with a space and run the registered command. Two fail on the old installer.
- Size: small. Status: done (dev, see CHANGELOG).

### 19. MCP server must start on a CRLF SKILL.md
- Change: `parseFrontmatter` in `mcp-server/src/skill-catalog.ts` matched only LF line endings and no byte order mark, so a skill folder checked out with CRLF made the server exit at startup. Found in the run 14 audit. It now accepts both.
- Benefits: an MCP-only user on Windows, or anyone with git autocrlf, who got "SKILL.md is missing YAML frontmatter" and no server.
- Verify: `mcp-server/test/errors.test.ts` has a test for CRLF and for a byte order mark. It failed before the fix with that error.
- Size: small. Status: done (dev, see CHANGELOG).

### 20. Installer must keep a symlinked settings file a symlink
- Change: `install.sh` wrote `settings.json` by replacing the path, so a symlink (as dotfile managers such as stow or chezmoi create) became a plain file with mode 0600, and the real file never got the hook. Found in the run 15 audit. It now writes to the file the link points to, keeps its mode, and keeps non-ASCII text as written. Install and uninstall both.
- Benefits: anyone who keeps `~/.claude/settings.json` in a dotfiles repo, whose link was silently broken and whose tracked file missed the hook.
- Verify: `scripts/test-install.sh` has 7 new checks. 3 of them fail on the old installer.
- Size: small. Status: done (dev, see CHANGELOG).

### 21. Installer answers --help and -h
- Change: `./install.sh --help` and `-h` print the usage line and the list of flags and hosts, and exit 0. Today both print `unknown host: --help` and exit 1, and the usage text exists only as a comment in the script. Found in the run 16 audit. Document the flags in `docs/quickstart.md`. Do not change how any other argument is parsed.
- Benefits: a new person or an IT reviewer who runs `install.sh --help` before running an installer on a managed machine, which is the normal first step.
- Verify: `scripts/test-install.sh` gets checks for `--help` and `-h` (exit 0, output names `--ref`, `--dry-run`, `--uninstall` and every host, nothing written to HOME). Both fail on the current installer.
- Size: small. Status: done (dev, see CHANGELOG). 18 new checks in `scripts/test-install.sh` (89 total). The old installer printed `unknown host: --help` and exited 1.

### 22. Repository id script gives a plain error outside git
- Change: `derive-repo-id.sh` run outside a git repository prints git's `fatal: not a git repository` and exits 128. Print one clear line that names the script and says to use `--doc` for a folder that is not a repository, and exit 1. The id output for valid repositories must not change.
- Benefits: a person using Save Point on a plain folder of documents, who sees a git error with no hint about `--doc`.
- Verify: `scripts/test-repo-id.sh` gets a case run in an empty temp directory: exit 1, one stderr line that mentions `--doc`. Existing id cases give identical output.
- Size: small. Status: done (dev, see CHANGELOG). 1 new case group in `scripts/test-repo-id.sh`. On the old script it failed with exit 128.

### 23. Stats script must not report zeros for a missing directory
- Change: `stats.sh` exits 1 with a plain error when its argument is not a directory.
- Benefits: anyone reading the question HUD, whose lifetime numbers must not contradict the state files.
- Verify: `scripts/test-stats.sh` runs it on a missing path and expects exit 1, an empty stdout and a message. It failed on the old script.
- Size: small. Status: done (dev, see CHANGELOG).

### 24. Pin the answer digest format with a test
- Change: add `scripts/test-hash-answer.sh` with fixed digests for `hash-answer.sh`, and run it in CI. No script changed.
- Benefits: the owner running the study, and anyone who stores `answer_sha256`. A silent change to the canonical form would make old digests fail to match new ones.
- Verify: the test passes on the current script (12 checks) and fails when the `>` marker rule is removed from the script.
- Size: small. Status: done (dev, see CHANGELOG).
### 25. daily_limit 0 must mean no unsolicited prompts
- Change: `check-due.sh` exits quietly when `daily_limit` is 0. Test added in `scripts/test-reschedule.sh`.
- Benefits: a person or team admin who sets `daily_limit: 0` to turn interruptions off (`docs/teams.md` lists the setting). Before, one nudge still came each day.
- Verify: the new case fails on the old script (exit 1, nudge printed) and passes on the new one.
- Size: small. Status: done (dev, see CHANGELOG).

## Needs the owner

1. Releases. Version is 0.12.0 but the latest tag is v0.9.0. Decide whether to tag a release from main, and who owns the changelog on release.
2. A format marker (for example `format_version:`) in `recall.md` and `savepoint.md`. This touches record formats, so it affects comparability across study versions.
3. Whether the MCP server should be published to npm.
4. Whether the installer's curl line should point at a tag instead of `main`.
5. A security contact address for SECURITY.md. This run will not invent one. Item 2 will use GitHub private vulnerability reporting unless you say otherwise.
6. Whether a macOS CI runner is acceptable cost-wise.
