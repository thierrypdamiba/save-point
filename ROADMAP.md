# Roadmap

Ranked by what stands between today's Save Point and software a company could adopt. Most valuable first. Sizes: small (under a day), medium (a few days), large (a week or more).

Status key: `ready` means a run can pick it up. `blocked` means it needs an owner decision first. `done` means merged to dev.

Audit date: 2026-11-26 (first audit). Items 13 to 16 added by the run 13 audit. Items 17 to 47 added by later audits. Audited: README, SKILL.md, scripts, features, eval, install.sh, mcp-server, CI, plugin files.

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
- Size: medium. Status: done (dev, see CHANGELOG). `eval/record-results.sh` and `eval/RESULTS.md`. Two runs are recorded: s01 only (1 of 1), and the full 15 scenario run on 2026-11-28 (15 of 15, one run, default model). `record-results.sh` is now executable, as the eval README shows it being run.

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

### 26. Test the source hash and snapshot script
- Change: add `scripts/test-hash-source.sh` and run it in CI. `hash-source.sh` had no test. The run 22 audit tried it by hand: digests, snapshots, modes and errors all behaved correctly. No script changed.
- Benefits: the owner running the study, and anyone who stores `source_sha256` or relies on a snapshot holding the exact bytes an answer was right for in a document workspace.
- Verify: the test passes on the current script (10 check groups). It fails when `chmod 700` is removed from the script, and when the file check before `mkdir` is removed. Removing the "snapshot exists" check does not fail it, because rewriting identical bytes is harmless.
- Size: small. Status: done (dev, see CHANGELOG).

### 27. Snapshot reuse trusts a file by name (open question, no change yet)
- Change: if a file named by a digest already exists in the snapshot directory, `hash-source.sh` keeps it without checking its bytes. A hand-edited or damaged snapshot stays and is later read as the text an answer was right for. Decide whether to re-hash an existing copy and replace it on mismatch. This touches how study evidence is stored, so it waits for the owner.
- Benefits: the study analyst, who relies on snapshots being what their name says.
- Verify: a test that damages a snapshot, runs the script, and expects the copy to match its name again.
- Size: small. Status: blocked on the owner (Needs the owner 7).

### 28. questions_per_interruption 0 must mean no unsolicited prompts
- Change: `check-due.sh` exits quietly when `questions_per_interruption` is 0. It used to nudge with "offer at most 0 question(s)", which contradicts itself. Also added tests for branches that had none: `manual_only`, flow mode (on and expired), the minimum gap, and `cross_repo_recall: off`.
- Benefits: a team admin or person who sets the value to 0 to stop interruptions, and anyone relying on those quiet rules, which no test covered.
- Verify: the new 0 case fails on the old script (nudge printed) and passes on the new one. `scripts/test-reschedule.sh` now has 9 more cases of these rules; only the 0 case failed on the old script.
- Size: small. Status: done (dev, see CHANGELOG).

### 29. A last prompt in the future must not mute the recall hook
- Change: `check-due.sh` treats a `last_prompt_at` later than now as unset. Before, a value from a wrong clock (for example year 2999) kept the hook silent until that date. The daily cap still applies. Test added in `scripts/test-reschedule.sh`.
- Benefits: a person whose machine clock was wrong once, or a team whose shared state came from a skewed machine. They would otherwise lose nudges with no sign why.
- Verify: the new future case fails on the old script (no nudge) and passes on the new one. A just-now value still stays quiet.
- Size: small. Status: done (dev, see CHANGELOG).

### 30. Recall hook must read quoted and commented profile values
- Change: `check-due.sh` read `interruption_style: "manual_only"` or `daily_limit: 0 # none` as unknown values, so the opt-out was ignored and the hook still nudged. It now drops one pair of surrounding quotes and a trailing ` # comment` from profile, scheduler and recall values. Found in the run 24 audit. Names such as `repository_name` are read as before.
- Benefits: a person or team admin who hand-edits `profile.md` the way YAML allows, and who would otherwise keep getting prompts they turned off.
- Verify: `scripts/test-reschedule.sh` has 9 new checks. The first fails on the old script. Bare values behave as before.
- Size: small. Status: done (dev, see CHANGELOG).

### 31. Recall hook must read an unknown interruption_style as an opt-out
- Change: `interruption_style: manual-only` (hyphen), `off` or any other value that is not `natural_boundaries` was treated as the default, so the hook kept nudging. Now only an empty value or `natural_boundaries` allows nudges. The two documented values behave as before. Found in the run 25 audit.
- Benefits: a person or team admin who hand-edits `profile.md`, makes a small typo while turning prompts off, and would otherwise keep getting them.
- Verify: `scripts/test-reschedule.sh` has 7 new checks. The first fails on the old script. Values `natural_boundaries` (bare and quoted) and empty still nudge.
- Size: small. Status: done (dev, see CHANGELOG).

### 32. Recall hook must read an unknown cross_repo_recall as off
- Change: `check-due.sh` only kept other repositories out for the exact text `off`. `false`, `no`, `OFF` or a typo let the hook name another repository in the nudge. Now only an empty value or `on` (any case) allows it. Found in the run 26 audit. Same rule as item 31.
- Benefits: a consultant who isolates client repositories, and whose hand edit had a typo. The nudge names the other repository, which can leak a client's project name.
- Verify: `scripts/test-reschedule.sh` has 11 new checks. The first fails on the old script. `on`, `On`, `ON`, `"on"` and empty still nudge.
- Size: small. Status: done (dev, see CHANGELOG).

### 33. Stats script drops a heading that ends in an HTML comment
- Change: `stats.sh` skips any line holding `-->`, so `## q1 — solid @ date <!-- note -->` is not counted. Found in the run 26 audit. No known writer produces such a heading, so only fix it if one does. Verify with a fixture that counts the heading.
- Benefits: someone who annotates headings by hand.
- Size: small. Status: done (dev, see CHANGELOG). Comment state is now updated after a line is counted, and complete `<!-- -->` pairs are removed first. Check added to `scripts/test-stats.sh`; the old script gave closes 1 on that fixture, not 3.

### 34. Custom persona length must count characters in the C locale
- Change: `check-persona.sh` counted length with `wc -m`, which counts bytes in the C locale. A 150 character description in French or Japanese was refused as "300 characters" when `LANG` is unset. Now it drops UTF-8 continuation bytes and counts the rest, so the 200 character limit holds in any locale. Found in the run 27 audit.
- Benefits: a non-English speaker setting a custom persona through an agent or hook, where no locale is set.
- Verify: `scripts/test-persona.sh` accepts 200 and refuses 201 accented characters under `LC_ALL=C` and `C.UTF-8`. The C case fails on the old script (4 checks added).
- Size: small. Status: done (dev, see CHANGELOG).

### 35. Installer must refuse arguments after the host
- Change: `install.sh` read only the first non-option argument, so `./install.sh claude --dry-run` ignored the flag and wrote a real install, and `./install.sh --uninstall claude --bogus` uninstalled. Any argument after the host is now refused with `unexpected argument`, before anything is written. Options before the host work as before. Found in the run 28 audit.
- Benefits: an IT reviewer who adds `--dry-run` at the end of the line to look before approving, and who got a real install on a managed machine.
- Verify: `scripts/test-install.sh` has 14 new checks (103 total). 14 fail on the old installer, including a trailing `--dry-run` that wrote files.
- Size: small. Status: done (dev, see CHANGELOG).

### 36. Stats script must read a field with a trailing note
- Change: `stats.sh` counted `- stage: 2 # note` as no stage and `- last_quality: solid # note` as a quality named `note`. The recall hook already reads such hand edits (item 30). Now `stats.sh` drops a trailing ` # note` from recall.md fields. Headings are untouched. Files without notes give the same output as before.
- Benefits: a person who annotates `recall.md` by hand and reads the HUD totals.
- Verify: `scripts/test-stats.sh` has a case. On the old script it failed with `missing 'stage2: 1'`.
- Size: small. Status: done (dev, see CHANGELOG).

### 37. Broken relative links in Markdown fail CI
- Change: `scripts/check-links.sh` fails when a relative link in a tracked Markdown file points at a path that does not exist. CI runs `scripts/test-check-links.sh`, which also checks the real repository. Anchors and web links are not checked. Found in the run 31 audit, which checked the docs by hand: none were broken today.
- Benefits: a new person following the README and docs, and a maintainer who renames or moves a file.
- Verify: `scripts/test-check-links.sh` passes (6 checks), and a broken link in the README makes `check-links.sh` exit 1 with `BROKEN README.md -> ...`.
- Size: small. Status: done (dev, see CHANGELOG).

### 38. Recall hook and a non-numeric daily_limit (open question, no change yet)
- Change: `daily_limit: off`, `none` or `no` is read as the default 3, so the hook still nudges, and so does `-1`. Items 31 and 32 read a near miss as an opt-out for `interruption_style` and `cross_repo_recall`. Numbers are different, because `-1` or `none` could also mean no cap. Decide what a non-numeric limit means, document it in `profile.md`, then test it. Found in the run 31 audit.
- Benefits: a person or team admin who types a word to turn interruptions off.
- Verify: `scripts/test-reschedule.sh` cases for `off`, `none`, `no` and `-1` that match the decision.
- Size: small. Status: blocked on the owner (Needs the owner 8).

### 39. Pin the recall hook output as valid JSON
- Change: `scripts/test-reschedule.sh` feeds the hook seven repository names (quotes, backslashes, `</script>`, UTF-8, control bytes, JSON text) and parses each output with `python3`. An existing check covered only one odd name by string match. Found in the run 32 audit, which looked for untested output paths. No skill script changed.
- Benefits: anyone with the hook installed, since the hook runs on every prompt and bad JSON there is seen on every prompt.
- Verify: `sh scripts/test-reschedule.sh` prints `hook JSON: 7 names parsed`. Removing the name escaping in `check-due.sh` fails the suite (the older string check fires first).
- Size: small. Status: done (dev, see CHANGELOG).

### 40. Answer digest script gives a plain error for a bad path
- Change: `hash-answer.sh` given a missing file or a directory printed a shell message (`hash-answer.sh: 13: cannot open ...` or `sed: read error`) and exited 2 or 4. Now it prints `hash-answer.sh: not a file: <path>` and exits 1, as `derive-repo-id.sh` and `hash-source.sh` do. The digest of a real file or stdin is unchanged. Found in the run 33 audit by feeding each script a bad path.
- Benefits: an agent or person who mistypes the answer file path. The skill runs this script when it records an answer, so a clear one line error is what the agent reads.
- Verify: `sh scripts/test-hash-answer.sh` prints `18 checks passed`. On the old script the new check fails with `exit 2, want 1`.
- Size: small. Status: done (dev, see CHANGELOG).

### 41. Recall hook must survive a number with a leading zero
- Change: `check-due.sh` exited 2 on `minimum_gap: 08m` (or `09m`, `008h`). Dash reads `08` as a bad octal number in `$(( ))`. Exit 2 blocks the person's prompt in Claude Code. `digits_or` now drops leading zeros, so `08m` is 8 minutes. Numbers without a leading zero behave as before. Found in the run 34 audit by feeding the hook odd hand-edited values.
- Benefits: anyone who hand-edits `profile.md` and pads a number, and so would otherwise find every prompt blocked.
- Verify: `sh scripts/test-reschedule.sh` runs 9 new checks. On the old script the first fails with `check-due exit`.
- Size: small. Status: done (dev, see CHANGELOG).

### 42. MCP server must fail at start on a wrong skill folder
- Change: with a wrong `SAVE_POINT_SKILL_DIR`, or a build moved away from the checkout, the server started and then answered every client with `Internal server error`. The cause was only on stderr, which many hosts hide. `src/index.ts` now checks for `SKILL.md` first. If it is missing, the server prints one line naming the folder and the variable, and exits 1. A good folder behaves as before. Found in the run 35 audit by starting the server with a bad path.
- Benefits: an admin who sets up the MCP server for a team and mistypes a path, and would otherwise see an unexplained error.
- Verify: `cd mcp-server && npm test` runs 3 new tests in `test/startup.test.ts`. With the old `index.ts`, 2 of them fail.
- Size: small. Status: done (dev, see CHANGELOG).

### 43. Recall hook must read the minimum_gap unit in any case
- Change: `check-due.sh` read `minimum_gap: 3H` or `90M` as the 90 minute default, because only lowercase `m` and `h` matched. A person who asked for a longer gap got nudges sooner. It now lowercases the value and drops spaces first. Lowercase values and unreadable values behave as before. Found in the run 36 audit by trying capital units.
- Benefits: a person or team admin who hand-edits `profile.md` to space prompts out, and would otherwise get more of them than they set.
- Verify: `sh scripts/test-reschedule.sh` runs 9 new checks. On the old script the first fails with `not quiet: minimum_gap 3H`.
- Size: small. Status: done (dev, see CHANGELOG).

### 44. Stats script must read a quoted field value
- Change: `stats.sh` counted `- stage: "2"` as no stage and `- last_quality: "solid"` as a quality named `"solid"`. The recall hook already reads quoted hand edits (item 30). Now `stats.sh` drops one pair of surrounding quotes. Files without quotes give the same output.
- Who benefits: anyone who hand edits recall.md, and the question HUD numbers they see.
- Verify: `sh scripts/test-stats.sh`. The old script failed the new check group.
- Size: small. Status: done (dev, see CHANGELOG).

### 45. Recall hook must read state files that start with a byte-order mark
- Change: `check-due.sh` did not see the opening `---` of a file that began with a byte-order mark, so every setting read as missing. A `manual_only` opt-out or `daily_limit: 0` was ignored and the hook still nudged. Now the mark is dropped before the fence is read. Files without a mark give the same output.
- Who benefits: anyone who edits `profile.md` or `scheduler.md` in Windows Notepad or another editor that adds a mark, and who turned nudges off.
- Verify: `sh scripts/test-reschedule.sh`. 4 new checks. The old script failed the first one (it nudged with `manual_only` set).
- Size: small. Status: done (dev, see CHANGELOG).

### 46. Scripts that are run directly must keep their executable bit
- Change: `scripts/check-modes.sh` fails when a tracked `save-point/scripts/*.sh` or `install.sh` is not mode 100755 in git. CI runs `scripts/test-check-modes.sh`. The recall hook runs `check-due.sh` by path, so a lost bit means a "permission denied" error on every prompt. Found in the run 39 audit. All 8 files are correct today.
- Who benefits: anyone with the hook installed, and a contributor who edits a script on Windows or through a tool that drops the bit.
- Verify: `sh scripts/test-check-modes.sh` runs 5 checks. Clearing the bit on `check-due.sh` or `install.sh` in a fixture makes `check-modes.sh` exit 1.
- Size: small. Status: done (dev, see CHANGELOG).

### 47. Identity and digest scripts must refuse extra arguments
- Change: `derive-repo-id.sh`, `hash-answer.sh` and `stats.sh` ignore arguments after the first. `derive-repo-id.sh /a /b` prints the id of `/a` and exits 0. `hash-answer.sh a b` hashes only `a`. `stats.sh dir1 dir2` reports only `dir1`. Each should print one usage line and exit 1 when given more than it takes, as `install.sh` does after item 35. Output for correct calls must not change. Found in the run 40 audit by passing two paths to each script.
- Who benefits: an agent or person who passes two paths by mistake. The repository id keys every record, so a silent wrong id sends answers to the wrong folder. A wrong digest or HUD would look right.
- Verify: new cases in `scripts/test-repo-id.sh`, `scripts/test-hash-answer.sh` and `scripts/test-stats.sh`: exit 1, empty stdout, one stderr line. They fail on the current scripts (exit 0 today). Existing cases give identical output.
- Size: small. Status: done (dev, see CHANGELOG). Each new case failed on the old scripts (exit 0) and passes now.

### 48. Recall hook must show a hand-edited repository name without its quotes or note
- Change: `check-due.sh` read `repository_name` raw, so `repository_name: "acme"  # client` appeared in the nudge as `("acme"  # client)`. Every other setting already drops one pair of quotes and a trailing note. Read the name the same way. Found in the run 42 audit by writing such a file and running the hook.
- Who benefits: a person who edits `recall.md` by hand. The nudge goes into the agent's context on every prompt, so stray text there is noise and confuses the repository name.
- Verify: a new case in `scripts/test-reschedule.sh` checks the nudge ends with `acme)` and has no quote or note. It fails on the old script and passes now. The JSON validity cases are unchanged.
- Size: small. Status: done (dev, see CHANGELOG).

### 49. Recall nudge must stay short when many repositories are due
- Change: `check-due.sh` named every due repository in the nudge. With 60 due repositories the line was about 1.9 KB, and it is added to the agent's context on every prompt until questions are delivered. The nudge now names the first 5 and adds `, and N more`. The count in front is unchanged. Found in the run 44 audit by creating 60 due repositories and running the hook.
- Who benefits: a consultant or team member with many repositories, who would pay that cost on every prompt.
- Verify: a new case in `scripts/test-reschedule.sh` checks 60 due repositories give `, and 55 more)` and a line under 600 bytes, and 5 due repositories name all 5. The new case fails on the old script. It does not change recall.md, scheduling or delivery.
- Size: small. Status: done (dev, see CHANGELOG).

## Needs the owner

1. Releases. Version is 0.12.0 but the latest tag is v0.9.0. Decide whether to tag a release from main, and who owns the changelog on release.
2. A format marker (for example `format_version:`) in `recall.md` and `savepoint.md`. This touches record formats, so it affects comparability across study versions.
3. Whether the MCP server should be published to npm.
4. Whether the installer's curl line should point at a tag instead of `main`.
5. A security contact address for SECURITY.md. This run will not invent one. Item 2 will use GitHub private vulnerability reporting unless you say otherwise.
6. Whether a macOS CI runner is acceptable cost-wise.
7. Whether `hash-source.sh` should verify an existing snapshot against its name and replace it if damaged (item 27). It is a safe change in my view, but snapshots are study evidence, so you decide.
8. What a non-numeric `daily_limit` such as `off`, `none` or `-1` should mean (item 38): no unsolicited prompts, or the default of 3. Today it is the default. It only affects hand-edited files.
9. How the recall hook should behave when its nudge is not acted on (found in the run 40 audit). The hook writes nothing, and the skill updates `last_prompt_at` only when it delivers a question. If the agent holds back (tests failing, user mid-task), `last_prompt_at` does not move, so the nudge is added again on every later prompt until a question is delivered. That costs tokens and may annoy. Options: leave it (the hook stays write-free, as `docs/security-and-privacy.md` says), have the skill record a suppressed check in `scheduler.md` so the gap applies, or let the hook write one small stamp. The last two change delivery behavior and the hook's "writes nothing" statement, so this is yours to decide.
