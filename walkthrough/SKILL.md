---
name: walkthrough
description: Teach and test whether an engineer can explain a repository after AI-assisted work through source-grounded questions, optional AI assistance, user-controlled tuning, and later active recall. Use when a user invokes `/walkthrough`, asks to learn, quiz, or test themselves on a codebase, wants to curate question difficulty or teaching style, wants a human-authored repository walkthrough, or wants to practice cross-session codebase recall.
---

# Walkthrough

Build understanding, then test whether it lasts. Treat the scenarios in `features/` as the behavior contract. When changing this skill, preserve every invariant tagged `@integrity`, `@privacy`, or `@non_interruption`.

## Run optional first-time setup

Before the first repository question, check for a user profile. If none exists, offer a short setup session and make `Skip` equally available. Ask one configuration question at a time; do not turn setup into a quiz.

Configure at least:

1. Primary goal: learn, test recall, or mix both.
2. “I don't know” behavior: explain immediately, give a hint, show a source trail, offer a choice each time, or skip and revisit.
3. Question difficulty and preferred depth.
4. Feedback timing: after each answer or at the end of a section.
5. Repetition mode: intensive daily drilling for 30 days, or adaptive spacing based on recall quality.

Summarize the resulting profile and ask for confirmation before saving it to `~/.walkthrough/profile.md`. Let the user rerun setup with `/walkthrough setup`, inspect it with `/walkthrough settings`, or change any preference conversationally.

If the user skips setup, begin with conservative defaults: mixed learning and recall, new-engineer difficulty, one question at a time, feedback after each answer, offer a choice when the user says “I don't know,” and adaptive repetition. Do not repeatedly offer setup after it has been skipped; make it discoverable through `/walkthrough setup`.

Treat this as end-user runtime configuration, not developer configuration. Initialize the file from `assets/profile.md`, then update its YAML frontmatter. Keep it separate from repository-specific knowledge.

## Maintain Markdown state

Use plain, user-readable Markdown as the runtime database. Never write state into a source repository.

```text
~/.walkthrough/
  profile.md
  repositories/
    <repository-id>/
      walkthrough.md
      recall.md
```

Derive `<repository-id>` from the SHA-256 of the normalized canonical remote. When no remote exists, hash the canonical repository root. Use the first 20 lowercase hexadecimal characters. This prevents same-named repositories from colliding.

Initialize files from the matching templates in `assets/`:

- `profile.md`: confirmed setup preferences only.
- `walkthrough.md`: repository metadata and verbatim user-authored answers. Never add generated explanations as user prose.
- `recall.md`: questions, due dates, stages, quality signals, and assistance labels. Never add answer keys or answer text.

Read only the minimum file needed for the current operation. During a recall attempt, read the due prompt from `recall.md`; do not read `walkthrough.md` unless the user chooses assisted recall or opens their walkthrough. Update files atomically when possible and preserve unknown fields and user edits.

## Start a repository walkthrough

1. Confirm that the current directory is a repository and read it without modifying it.
2. Inspect architecture, entry points, major flows, data movement, tests, deployment and operational paths, failure handling, and non-obvious invariants.
3. Build a private question path organized as:
   - Chapters: major flows and subsystems
   - Maps: data movement and component relationships
   - Secrets: non-obvious invariants and historical decisions
   - Boss fights: incidents, edge cases, and failures
   - New Game+: harder modes that require synthesis or code evidence
4. Ask one concise, open question at a time. Adapt difficulty to the requested level: `new-engineer`, `maintainer`, or `operator`.
5. Follow the user's configured learning policy. During unaided recall, keep the repository-derived answer key internal until the configured assistance policy is triggered.

## Evaluate unaided recall

- Record the user's response verbatim before evaluating it.
- Ask for reasoning, code evidence, or reconciliation when an answer is incomplete, unsupported, or contradictory.
- Describe the gap without supplying the missing fact. Prefer: “Your answer conflicts with an earlier claim; what evidence resolves that?”
- Do not label an answer correct when that would disclose the answer. Record internal quality signals for scheduling.
- If the user asks for help or says they do not know, apply their configured “I don't know” behavior. Mark subsequent work on that question as assisted.
- Assemble `walkthrough.md` only from user-authored responses. Clearly mark unanswered, skipped, assisted, and unresolved items.

## Provide configured assistance

Treat “I don't know,” uncertainty, and requests for help as normal learning signals. Follow the saved preference. When the profile says to offer a choice, offer: explanation, hint, source trail, or skip. Otherwise apply the selected behavior directly.

When progressive assistance is selected, use the least assistance that moves the user forward:

1. Ask what part feels unclear.
2. Point to a small source trail or restate the question.
3. Give a conceptual hint.
4. Explain the mechanism with concrete code evidence.
5. Ask the user to restate it in their own words.

Let the user skip directly to an explanation. Never pretend an assisted response was unaided. After teaching, create a shorter follow-up question and schedule a later `recall` attempt.

Accept natural-language configuration feedback at any time, including “too hard,” “too easy,” “less trivia,” “more architecture,” “show me code first,” “teach before testing,” “spam me for 30 days,” and “switch to adaptive recall.” Do not require the user to edit configuration files. Confirm the changed setting, apply it immediately, and update `profile.md`.

## Preserve isolation

- Store state globally under `~/.walkthrough/repositories/<repository-id>/`; never write into the repository.
- Keep old repository files and stored answers out of unrelated coding context by not reading their Markdown files unless Walkthrough is active.
- Never use stored answers to answer an unrelated coding question.
- Use stable repository identity from the canonical remote when available; otherwise use a collision-resistant local identifier.
- Treat opening source, the saved walkthrough, or another aid before answering as assisted recall. Dismissing or deferring is neutral, not failure.

## Schedule recall

Create a recall item after each completed answer. Select the scheduling algorithm from `repetition_mode`:

- `intensive_30d`: drill every active concept daily for 30 days from its first completed answer. Rotate questions to avoid repeating identical wording, prioritize missed and assisted concepts, then graduate the item to adaptive scheduling after day 30.
- `adaptive`: reschedule using elapsed time, confidence, prior mistakes, concept importance, answer quality, and reliance on aids. Prefer intervals near 1, 7, and 30 days, adjusting rather than applying fixed punishment.

Allow `/walkthrough repetition intensive` and `/walkthrough repetition adaptive` to switch modes without deleting history. A mode change applies to future scheduling decisions; preserve prior attempts, labels, and original creation dates. In intensive mode, record `intensive_until` per item so the 30-day window is explicit and recoverable.

Offer at most one question at a host-supported natural boundary and enforce these delivery defaults:

```yaml
daily_limit: 3
minimum_gap: 90m
questions_per_interruption: 1
default_snooze: 4h
interruption_style: natural_boundaries
```

Natural boundaries include passing tests, commits, pull-request events, repository switches, session start or end, and inactivity. Suppress recall while commands run, the user edits actively, tests fail, conflicts are unresolved, urgent debugging is active, or the current task is incomplete.

Honor `/walkthrough flow <duration>`, `/walkthrough flow today`, and `/walkthrough resume`. A user suppression always overrides scheduling. If the host exposes no accepted boundaries, check due items when Walkthrough is invoked. Do not claim that the local MCP process can wake or interrupt a host by itself.

## Handle unavailable persistence

If the host cannot write `~/.walkthrough`, continue with ephemeral in-session state and state the limitation. Do not claim that recall was persisted. Never weaken answer integrity or interruption safety as a fallback.

## Consult the behavior contract

Read the relevant feature before implementing or changing behavior:

- `features/start-session.feature`: repository inspection and question paths
- `features/answer-integrity.feature`: no-answer and human-authorship rules
- `features/recall.feature`: recall classification and scheduling
- `features/interruption-safety.feature`: workflow boundaries and flow mode
- `features/storage-isolation.feature`: global storage and context separation
- `features/mcp-boundary.feature`: skill, MCP server, and host responsibilities
- `features/first-run-setup.feature`: optional personal configuration
- `features/tuning-mode.feature`: configured assistance and later adjustments
- `features/user-controls.feature`: commands and graceful fallbacks
- `features/cross-client.feature`: shared behavior across Codex, Claude Code, and Goose

## Use MCP for skill distribution

The companion MCP server distributes this skill and its templates through the `io.modelcontextprotocol/skills` extension on MCP `2026-07-28`, while retaining legacy MCP compatibility. It implements `skills/list`, `skills/get`, `resources/read`, and `resources/directory/read`, with SHA-256 content binding and private cache hints. For clients that support MCP but do not activate the skills extension, it also exposes read-only `list_skills` and `load_skill` tools plus a `walkthrough` prompt. Runtime state remains in Markdown and requires no stateful MCP tools.

Use this exact skill directory across Agent Skills hosts. Codex loads it from its personal skills directory; Claude Code loads it from `~/.claude/skills/walkthrough/`; Goose loads it from `~/.agents/skills/walkthrough/`. Do not maintain host-specific copies of `SKILL.md` or the templates. Ignore host-specific metadata such as `agents/openai.yaml` on hosts that do not use it.

Treat interruption delivery as a host responsibility. MCP cannot independently interrupt the user. Check `recall.md` when Walkthrough is invoked or at accepted host boundaries, then re-check suppression rules before showing anything.
