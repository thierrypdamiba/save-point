# Changelog

Newest first. This file follows the idea of Keep a Changelog. Anything on `dev` and not yet on `main` is under Unreleased.

## Unreleased

### Added
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
