# Save Point maintenance

For skill maintainers. Nothing here is needed to run a session — keep it out of runtime context.

## Invariants

The scenarios in `features/` are the behavior contract. When changing this skill, preserve every invariant tagged `@integrity`, `@privacy`, or `@non_interruption`. If a change and a tagged scenario conflict, change the proposal, not the tag.

## Behavior contract map

Read the relevant feature before changing behavior:

- `features/start-session.feature`: repository inspection, question paths, diff mode, and session presentation
- `features/answer-integrity.feature`: no-answer, feedback, and human-authorship rules
- `features/recall.feature`: recall classification, evaluation location, and deterministic scheduling, including custom `recall_intervals`
- `features/interruption-safety.feature`: workflow boundaries, global delivery limits, and flow mode
- `features/storage-isolation.feature`: global storage and context separation
- `features/mcp-boundary.feature`: skill, MCP server, and host responsibilities
- `features/first-run-setup.feature`: optional personal configuration and `setup_status` lifecycle
- `features/tuning-mode.feature`: configured assistance and conversational tuning
- `features/user-controls.feature`: commands and graceful fallbacks
- `features/question-stats.feature`: the per-question stats HUD, its verdict-leak freeze rule, and `stats.sh` as the lifetime baseline
- `features/cross-client.feature`: shared behavior and identical repository IDs across Codex, Claude Code, and Goose
- `features/document-mode.feature`: experimental document workspaces: `--doc` identity, text-grounded answer keys, read-only access to the document and sources, and drift detected from content digests and snapshots

## Distribution over MCP

The companion server in `mcp-server/` distributes this skill and its asset templates (`assets/`) through the `io.modelcontextprotocol/skills` extension on MCP `2026-07-28`, while retaining legacy MCP compatibility. It implements `skills/list`, `skills/get`, `resources/read`, and `resources/directory/read`, with SHA-256 content binding and private cache hints. For clients that support MCP but do not activate the skills extension, it also exposes read-only `list_skills` and `load_skill` tools plus a `save-point` prompt. Runtime state remains in Markdown and requires no stateful MCP tools.

Use this exact skill directory across Agent Skills hosts — do not maintain host-specific copies of `SKILL.md` or the asset templates:

- Codex: personal skills directory
- Claude Code: `~/.claude/skills/save-point/`
- Goose: `~/.agents/skills/save-point/`

`agents/openai.yaml` is host-specific metadata; hosts that do not use it ignore it. `scripts/derive-repo-id.sh` is the executable authority for repository identity — keep the prose algorithm in `SKILL.md` and the script in exact agreement, and update `cross-client.feature`'s examples when either changes. `scripts/reschedule.sh` is the authority for stage movement, for the importance clamp, and for what makes a `recall_intervals` list legal: keep it in agreement with the "Schedule recall" section of `SKILL.md`, with the `recall_intervals` line in `assets/profile.md`, and with `recall.feature` and `user-controls.feature`. The same holds for `derive-repo-id.sh`'s `--doc` mode and for `scripts/hash-source.sh`, which are the authority for document identity and source digests: keep them in agreement with the "Document workspaces" section of `SKILL.md` and with `document-mode.feature`.

## Test coupling

`mcp-server/test/catalog.test.ts` asserts that the loaded skill content contains the sentence "Build understanding, then test whether it lasts" and that `features/cross-client.feature` exists. It also asserts that `features/document-mode.feature` and `scripts/hash-source.sh` are served and that the skill content has a "Document workspaces (experimental)" heading. Keep both, or update the tests deliberately.
