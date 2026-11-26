# Dev digest

What is on `dev` and not yet on `main`. Written for a two-minute read.

Last updated: 2026-11-26 (run 8).

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
- This digest.

The only behavior changes are the new uninstall and `--ref` options. The quickstart and team guide are docs only. Install, question selection, grading and record formats are unchanged, so the study is not affected.

## Decisions waiting for you

See "Needs the owner" in ROADMAP.md. The most important: whether to tag a release (latest tag is v0.9.0, the version is 0.12.0), and whether to add a format marker to the state files.

## Next up

Roadmap item 7 is half done. The macOS runner needs your answer (Needs the owner 6). Next ready item: 8 (published eval pass rates), which needs a model CLI, then the doc part of 9. A fresh audit is due when those run out.
