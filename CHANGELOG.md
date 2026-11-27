# Changelog

Newest first. This file follows the idea of Keep a Changelog. Anything on `dev` and not yet on `main` is under Unreleased.

## Unreleased


### Changed
- Fix: the recall hook no longer exits 2 (which blocks the prompt) when `HOME` and `SAVE_POINT_HOME` are both unset, and no longer prints invalid JSON when a repository name holds a control character. Normal setups behave the same.
- The long inline script checks in `ci.yml` now live in `scripts/test-repo-id.sh`, `scripts/test-reschedule.sh`, `scripts/test-persona.sh` and `scripts/test-stats.sh`. CI calls them. A contributor can run each with `sh scripts/<name>.sh` from any directory. The checks are the same text as before. No skill script changed.

### Fixed
- `stats.sh` given a directory that does not exist now prints `error: not a directory: <path>` and exits 1. Before, it printed a full block of zeros, which the question HUD could show as lifetime numbers. An existing directory with no history still gives zeros. 1 new check group in `scripts/test-stats.sh`.
- `derive-repo-id.sh` run outside a git repository now prints one line that names `--doc` and exits 1. Before, it printed git's `fatal: not a git repository` and exited 128. Output for repositories and `--doc` is unchanged. No id changed.
- `install.sh` now keeps a symlinked `~/.claude/settings.json` a symlink. Before, adding or removing the recall hook replaced the link with a plain file with mode 0600 and left the linked file without the hook. It now edits the linked file, keeps its permissions, and no longer rewrites non-ASCII text as `\uXXXX` escapes. Ordinary files behave as before. 7 new installer checks (71 total).
- The MCP server now starts when `SKILL.md` has Windows line endings or a byte order mark, as a checkout with git autocrlf produces. Before, it stopped with "SKILL.md is missing YAML frontmatter". LF files behave as before. 1 new test (10 total).
- The recall hook command is now quoted, in the entry `install.sh` writes, in `hooks/hooks.json` and in the README snippet. Before, a space in `HOME` (or the plugin folder) split the path and the hook failed with "not found" on every prompt. Existing entries are not rewritten: run `./install.sh --uninstall claude` then install again to get the quoted form. Nothing else changed. 5 new installer checks (64 total).
- `save-point/scripts/check-due.sh` no longer fails on absurdly large numbers (over 9 digits) in `daily_limit`, `questions_per_interruption`, `minimum_gap` or `prompts_today`. Before, a huge `prompts_today` printed `Illegal number` on every prompt and skipped the daily cap. Now such values in the profile use the default, and a huge `prompts_today` counts as at the cap. Ordinary files behave as before. No record format changed.
- `save-point/scripts/stats.sh` now reads files with CRLF line endings and trailing spaces. Before, a CRLF `recall.md` showed every stage as 0 and no tainted items, and a CRLF `savepoint.md` printed keys like `closes_failed^M`. The output for LF files is unchanged. No record format changed. A CI step checks a CRLF case.

### Added
- `scripts/test-hash-answer.sh`: 12 checks that pin the digest `hash-answer.sh` gives for fixed inputs (CRLF, quote markers, trailing newlines, file and stdin, missing file). CI runs it. No script changed.
- `./install.sh --help` and `-h` print usage and exit 0. Before, both failed with `unknown host`. Nothing is written. Other arguments parse as before. Quickstart mentions it.
- `./install.sh --dry-run [host]`: prints every file a real install would write and the hook entry it would add, and writes nothing under HOME. It is refused with `--uninstall`. A piped dry run still clones to a temp dir. Normal installs are unchanged. 13 new installer checks (59 total), including a before and after listing of HOME.
- CI job `mcp-node20`: runs `npm ci`, `npm run check` and `npm test` for the MCP server on Node 20, the minimum in `package.json`. The Node 22 job is unchanged. CI only, no code changed.
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
