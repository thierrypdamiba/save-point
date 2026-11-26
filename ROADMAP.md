# Roadmap

Ranked by what stands between today's Save Point and software a company could adopt. Most valuable first. Sizes: small (under a day), medium (a few days), large (a week or more).

Status key: `ready` means a run can pick it up. `blocked` means it needs an owner decision first. `done` means merged to dev.

Audit date: 2026-11-26. Audited: README, SKILL.md, scripts, features, eval, install.sh, mcp-server, CI, plugin files.

## Facts found in the audit

- Version `0.12.0` is written in four places by hand: `.claude-plugin/plugin.json`, `mcp-server/package.json`, `mcp-server/package-lock.json`, `mcp-server/src/server.ts`. The only git tag is `v0.9.0`. CI now checks that they agree.
- There is no SECURITY.md, no CHANGELOG.md (added in this run), and no privacy statement outside the README paragraph on `~/.save-point`.
- `install.sh` has no uninstall, no `--version`, and no dry run. The curl one-liner installs whatever is on `main`, with no pin to a release.
- The installer's hook merge (python3 JSON edit) is only exercised by a smoke test that checks the skill files. Idempotency, malformed settings, and an existing hook list are not tested.
- CI runs shell checks and the MCP tests on one OS (ubuntu). The scripts target macOS users too. No `shellcheck`, no `sh -n` pass.
- The eval harness is not run in CI and no pass rates are published in the repo.
- Team use is undocumented: what to share, what never to share, how to use it on a shared machine.

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
- Size: small. Status: ready.

### 3. Installer tests: hook merge, idempotency, uninstall
- Change: add CI tests for `install.sh` against a temp HOME. Cases: fresh install, second install (one hook entry only), existing settings with other hooks kept, malformed settings left untouched, single-host installs, unknown host. Add `./install.sh --uninstall [host]` that removes the skill and its hook entry, and test it.
- Benefits: anyone upgrading or removing it, and IT staff who need a clean removal.
- Verify: the new CI steps pass. Settings JSON is byte-identical after install then uninstall on a file that had no Save Point entry.
- Size: medium. Status: ready.

### 4. Upgrade path and pinned installs
- Change: let the installer take `--ref <tag>` so a team can pin a release. Print the installed version. Document upgrade and rollback in the README. Keeps `~/.save-point` state untouched, with a test that proves it.
- Benefits: a team lead who needs everyone on the same version, and the research study, which needs a fixed version.
- Verify: install with a ref from a local fixture repo, check the version file, check state files unchanged.
- Size: medium. Status: ready. Depends on item 1 for a single version source.

### 5. Ten-minute quickstart and troubleshooting doc
- Change: add `docs/quickstart.md`: install, first session, what you will see, how to turn off interruptions, how to remove. Add a troubleshooting list: skill not found in a running session, hook complaints after uninstall, python3 missing, Node too old for the MCP server.
- Benefits: a new person on a team who has never used it.
- Verify: follow the doc from a clean temp HOME and confirm each command works as written. Record the commands tried.
- Size: small. Status: ready.

### 6. Team and admin guide
- Change: `docs/teams.md`: what is safe to share (nothing in `~/.save-point`), shared machines, how to disable the hook for everyone, how to pin a version, what to tell a team about the study. No claims about adoption.
- Benefits: an engineering manager considering a rollout.
- Verify: every setting named in the guide exists in `assets/profile.md` or the README. A CI grep checks the names.
- Size: small. Status: ready.

### 7. Shell hygiene in CI
- Change: run `sh -n` on every script and `shellcheck` if it can be installed in the runner. Fix findings that do not change behavior. Add a macOS job for the script steps, since `date -d` and `shasum` differ.
- Benefits: macOS users, who are likely most of the audience, and maintainers.
- Verify: CI green on both runners. Report any finding left unfixed.
- Size: medium. Status: ready.

### 8. Published eval pass rates
- Change: write a small script that turns `eval/run.sh` output into a dated table in `eval/RESULTS.md` with model, scenario count, and passes. Commit results only from runs someone actually made.
- Benefits: a reviewer who wants evidence that the integrity rules hold, and the owner for the study.
- Verify: the table matches the raw run output saved next to it. Needs a model CLI, so this run type may be "not run" in some environments.
- Size: medium. Status: ready, but a run needs the `claude` CLI and a login.

### 9. Upgrade-safe state format note
- Change: document the on-disk formats of `savepoint.md`, `recall.md`, `profile.md`, `scheduler.md` and add a `format_version` check plan. Do not change the formats.
- Benefits: anyone writing tooling on top, and the study analysts who compare versions.
- Verify: the doc matches the templates in `assets/`, checked by a CI grep for each field name.
- Size: small. Status: blocked on the owner for adding a format marker (see below). The doc part is ready.

### 10. MCP server packaging
- Change: publish-ready package: a `files` list, a `prepare` build, README instructions that do not need a checkout path. Keep it private until the owner decides.
- Benefits: MCP-only users who cannot use native skills.
- Verify: `npm pack` in CI lists the expected files and the packed server starts and answers `list_skills`.
- Size: medium. Status: blocked on the owner (publishing decision).

## Needs the owner

1. Releases. Version is 0.12.0 but the latest tag is v0.9.0. Decide whether to tag a release from main, and who owns the changelog on release.
2. A format marker (for example `format_version:`) in `recall.md` and `savepoint.md`. This touches record formats, so it affects comparability across study versions.
3. Whether the MCP server should be published to npm.
4. Whether the installer's curl line should point at a tag instead of `main`.
5. A security contact address for SECURITY.md. This run will not invent one. Item 2 will use GitHub private vulnerability reporting unless you say otherwise.
6. Whether a macOS CI runner is acceptable cost-wise.
