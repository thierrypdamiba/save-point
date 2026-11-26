# Changelog

Newest first. This file follows the idea of Keep a Changelog. Anything on `dev` and not yet on `main` is under Unreleased.

## Unreleased

### Changed
- The long inline script checks in `ci.yml` now live in `scripts/test-repo-id.sh`, `scripts/test-reschedule.sh`, `scripts/test-persona.sh` and `scripts/test-stats.sh`. CI calls them. A contributor can run each with `sh scripts/<name>.sh` from any directory. The checks are the same text as before. No skill script changed.

### Fixed
- `save-point/scripts/stats.sh` now reads files with CRLF line endings and trailing spaces. Before, a CRLF `recall.md` showed every stage as 0 and no tainted items, and a CRLF `savepoint.md` printed keys like `closes_failed^M`. The output for LF files is unchanged. No record format changed. A CI step checks a CRLF case.

### Added
- `mcp-server/test/errors.test.ts`: 6 tests for MCP server failure paths. Bad directory URIs (`..`, file, http, foreign scheme, non-directory), unknown `skills/get` URI, wrong `load_skill` name, missing `SKILL.md`, bad frontmatter, and dotfiles not served. Tests only. No server code changed.
- ROADMAP.md items 13 to 16 from a fresh audit. Docs only.
- `eval/record-results.sh`, `eval/RESULTS.md` and `eval/results/`: turns saved `eval/run.sh` output into a dated table row and keeps the raw log. It refuses a run that did not finish or whose summary disagrees with its scenario lines. `scripts/test-record-results.sh` (8 checks) runs in CI. One real run is recorded: s01, 1 of 1. No harness or assert changed.
- `docs/state-formats.md`: the on-disk fields of `profile.md`, `scheduler.md`, `recall.md`, `savepoint.md` and `snapshots/`, linked from the README. A CI step fails if a template field is missing from the page. No format changed.
- CI step `verify shell hygiene`: `sh -n` on every tracked `.sh` file, a check that no shell script is missing the `.sh` name, and `shellcheck` at warning level on all scripts outside `eval/`. The step also checks that shellcheck can fail. No script changed.
- `docs/teams.md`: what a team should never share, shared machines, client separation, turning interruptions down, pinning a version, and removal. The README links to it. A CI step checks the setting names against `assets/profile.md` and the commands against the README.
- `docs/quickstart.md`: install, first session, what you will see, turning interruptions off, removal, and troubleshooting. The README links to it. A CI step checks that the installer flags, messages and commands the doc names still exist.
- `./install.sh --ref <tag|branch>`: pin, upgrade or roll back to a ref. It writes a `VERSION` file into the installed skill and prints the version. Without `--ref`, installs behave as before. A failed ref leaves the current install alone, and `~/.save-point` is never touched. 12 new installer checks (46 total).
- `./install.sh --uninstall [host]`: removes the skill and the recall hook entry from `~/.claude/settings.json`, and never touches `~/.save-point`. A settings file with no Save Point entry is not rewritten. Installing is unchanged.
- `scripts/test-install.sh` and a CI step: 34 checks on fresh install, repeat install, other hooks kept, malformed settings untouched, single-host installs, unknown host, and uninstall.
- `SECURITY.md` and `docs/security-and-privacy.md`: what Save Point reads, writes and sends, with the file behind each claim. A CI step fails if a script uses a network tool or the MCP server imports a network or process module.
- `scripts/check-versions.sh` and a CI step that fails when the version differs between `plugin.json`, `package.json`, `package-lock.json` and `server.ts`. `docs/maintenance.md` says where to edit.
- ROADMAP.md: a ranked list of what stands between Save Point and team adoption.
- CHANGELOG.md and DEV-DIGEST.md.
- AGENTS.md and the `dev` branch track (already on dev before this entry).

## 0.12.0

Question personas, with eval scenarios s14 and s15. See the git history for detail. Earlier versions were not logged in this file.
