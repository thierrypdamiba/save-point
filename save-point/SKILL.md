---
name: save-point
description: Teach and test whether an engineer can explain a repository after AI-assisted work through source-grounded questions, optional AI assistance, user-controlled tuning, and later active recall. Use when a user invokes `/save-point`, says "quiz me", "test me on this repo", or "do I really understand this code", asks to learn or test themselves on a codebase, wants spaced repetition for code knowledge, or wants to curate question difficulty or teaching style. Not for generating code tours or explanations the user only wants to read — this skill asks the user questions and records their answers.
---

# Save Point

Build understanding, then test whether it lasts. Ask source-grounded questions, record the user's own words, and bring concepts back later to measure durable unaided understanding.

Invariants, in every session:

- The repository-derived answer key stays internal. While a question is open, never reveal, hint at, complete, or verify specific facts.
- `savepoint.md` holds only the user's verbatim words, each labeled honestly — assisted work is never presented as unaided.
- Assistance of any form — hint, source trail, restated question, explanation, whether from policy or on request — marks the remainder of the current attempt `assisted` and sets `last_assisted: true` on the item, which holds the stage at the next close. Teaching taints the concept, not just the question: work on any question covering material explained earlier in the session is `assisted` too, and new questions overlapping an item marked `last_assisted` or a pending follow-up inherit the flag.
- State lives only under `~/.save-point/`; never write into a repository, and never let one repository's stored answers leak into another's context.

## Commands

| Command | Effect |
| --- | --- |
| `/save-point` | Start or resume: evaluate pending answers, offer due recall (this repository's items, plus a labeled count from others), then new questions. Only the new-questions phase needs a repository — due recall works anywhere |
| `/save-point start [--level new-engineer\|maintainer\|operator]` | Start a playthrough of the current repository at an explicit difficulty |
| `/save-point start --diff [ref]` | Quiz on what changed since `ref` (default: the last merge, else `HEAD~1`) instead of the whole repository |
| `/save-point recall` | Serve due recall items now, across repositories unless `cross_repo_recall` is `off` (user-invoked, uncapped) |
| `/save-point setup` | Run or rerun the setup session, pre-filled with current values |
| `/save-point settings` | Show active preferences; never shows repository answers |
| `/save-point dispute q014` | Contest a closed verdict: re-derive the key with evidence shown, append an `amended` entry if it was wrong |
| `/save-point repetition intensive\|adaptive` | Switch scheduling mode; history is preserved |
| `/save-point flow <duration>` / `/save-point flow today` | Suppress unsolicited prompts globally for the duration, or until the next local midnight |
| `/save-point resume` | End flow mode early (not session resume — bare `/save-point` does that) |
| `/save-point interruptions off\|on` | Permanently switch to manual-only recall (due items surface only when invoked), or back |

Every command also works as plain conversation ("quiz me", "pause questions until tomorrow"). Never require the user to edit configuration files.

## Run optional first-time setup

Offer a short setup session when no `~/.save-point/profile.md` exists or its `setup_status` is `unset`; make `Skip` equally prominent. Ask exactly five questions, one at a time — primary goal, "I don't know" behavior, difficulty, depth, feedback timing — using the options documented per field in the `assets/profile.md` template. Do not turn setup into a quiz; do not ask about repetition mode here. At the first session's closing save point, offer intensive drilling once and set `intensive_offered: true` (global, in `profile.md`) whatever the answer.

Summarize the resulting profile and ask for confirmation. Write `profile.md` from the template only at that moment: `setup_status: confirmed` with the confirmed values, or `setup_status: skipped` with the template defaults if the user skips. After a skip, do not offer setup again; leave `/save-point setup` discoverable.

## Maintain Markdown state

Use plain, user-readable Markdown as the runtime database.

```text
~/.save-point/
  profile.md      preferences and delivery settings (legal values documented in the template)
  scheduler.md    global delivery state: prompt counts, gap timer, flow mode
  repositories/
    <repository-id>/
      savepoint.md   verbatim user-authored answers, one entry per attempt, each status-labeled
      recall.md        questions, due dates, stages, quality signals; never answer text or keys
```

Initialize each file from its template in `assets/` — read the template from disk, or with `resources/read` when this skill arrived over MCP without a local directory. Create `~/.save-point` with permissions 0700 and its files 0600: the prompts and importance rankings inside are a map of each codebase's sensitive paths. A missing `scheduler.md` reads as its template defaults; create it on first update. Persist incrementally: append each verbatim answer to `savepoint.md` the moment it is recorded; update `recall.md` at every question close and `scheduler.md` whenever an unsolicited prompt is delivered. Write via temp-file-and-rename when the host allows, so an interrupted session loses nothing — except for another repository's files, where isolation wins: use a mechanical file-level append (`>>`) whose existing content never enters context.

Create a repository's files from their templates — frontmatter populated from the derived identity — at the first write that needs them, from inside that repository. Preserve unknown fields, and user edits in `profile.md` — the one file where edits are configuration. Every agent-maintained field elsewhere (labels, quality signals, stages, flags, recorded answers) is the record, not settings. Detection of outside edits is best-effort, but where one is apparent — a digest mismatch, an impossible value, a label contradicting the session's own history — do not trust it: relabel a tampered entry `unresolved`, and quarantine a tampered recall item by resetting invalid values to template defaults (`last_quality: untested`) and appending an `unresolved` entry for it to `savepoint.md`.

Store timestamps as UTC ISO-8601 instants (`2026-08-04T12:00:00Z`). Fields that name a calendar day (`prompt_date`) hold the user's local date, because day boundaries are the user's local midnights.

## Derive the repository ID

Run `scripts/derive-repo-id.sh` from the skill directory when scripts are executable — it prints the canonical identity string and the ID. Otherwise follow its algorithm exactly:

1. Take the fetch URL of `origin`; if absent, of the bytewise-first remote name; with no remotes, the absolute resolved repository root path, used verbatim (skip step 2).
2. Normalize: if the URL has a scheme, drop the scheme, any credentials, and any `:port` after the host; if scheme-less (SCP form), drop any credentials and turn the first `:` into `/`. Then repeatedly strip trailing slashes and a trailing `.git`, and lowercase the whole string.
3. The ID is the first 20 hex characters of the SHA-256 of that string: `printf '%s' "<canonical>" | shasum -a 256 | cut -c1-20`.

`https://GitHub.com/Octo/API.git`, `git@github.com:octo/api.git`, and `ssh://git@github.com:2222/octo/api` all yield `github.com/octo/api` → `540b016418280e51939c`. Every client must derive the same ID for the same repository, or profiles and recall history fragment. Record `repository_id`, `canonical_remote` (the canonical string), and `repository_name` (its final path segment) in `savepoint.md`, and `repository_id` and `repository_name` in `recall.md` frontmatter.

Identity follows the remote, so it changes when a local-only repository gains its first remote or a remote is renamed. When the derived ID has no directory, scan the existing directories' `canonical_remote` values; if one matches this repository's previous identity (its root path, or a prior remote of the same repository), offer to migrate that directory to the new ID — rename it and update both frontmatters — instead of starting fresh.

## Start a repository playthrough

1. Confirm the current directory is a repository and read it without modifying it. If it is not one, say a repository is required for new questions; due recall still works.
2. Inspect architecture, entry points, major flows, data movement, tests, deployment and operational paths, failure handling, and non-obvious invariants. With `--diff`, inspect only the change: what changed, why, what it touches, and what could break.
3. Build a question path organized as Chapters (major flows and subsystems), Maps (data movement and relationships), Secrets (non-obvious invariants and historical decisions), Boss fights (incidents, edge cases, failures), and New Game+ (synthesis questions, unlocked when every chapter is solid). The path's content is private; its shape is not:
   - Open with the world map: "4 chapters, 2 maps, 2 secrets, 1 boss fight — New Game+ locked."
   - Announce transitions: entering a chapter, facing a boss fight, uncovering a secret.
   - At each chapter boundary and session end, show a save point: what closed, chapter status, what's due next.
   - Chapter status is computed from stored recall items — the `chapter` labels on items, not the freshly rebuilt path, are the source of truth. A chapter is `solid` when every item carrying its label has `last_quality: solid`; otherwise `in-progress`; `unvisited` with no items.
4. Ask one concise, open question at a time at the configured difficulty and depth. Assign each question an ID — `q` plus a per-repository ordinal (`q014`) — that never changes, even when wording is later rotated. The vocabulary is tunable: on "plain labels", swap the game framing for neutral terms (sections, data flow, invariants, failure scenarios, review summary) everywhere user-facing.
5. Rebuild the path each session from current source; skip concepts already covered by items in `recall.md`.

## Show the HUD

Unless `question_stats` is `off`, every question — new or recall — carries one line above it: the session tally and this repository's lifetime numbers.

> 📊 Session: 3 closed (2 solid · 1 assisted) | api lifetime: 27 closes · 9 in rotation · 2 at stage 3

Read the lifetime baseline once per session via `scripts/stats.sh <state-repo-dir>` (or count by its rules when scripts are not executable) and add this session's closes on top; shown numbers must never contradict the state files. Scope is the current repository only — aggregate nothing from other repositories' files. The HUD is counts, never content: no question text, no answer text, no key fact, and while a question is open its numbers do not change. Numbers that reveal a verdict move only when the verdict itself is delivered — under `end_of_section` feedback timing, quality-derived numbers hold their section-start values until the boundary, while verdict-free counts (questions closed) may tick. In a repository with no history, say it is the first session rather than inventing numbers. "Plain labels" restyles the line; "stats off" sets `question_stats: off` in the profile and removes it.

## Evaluate answers

Record every attempt the moment it is given: append its verbatim text to `savepoint.md` as its own entry, `## q014 — open @ <timestamp>`, before evaluating. A question is **open** until the user finalizes an answer; finalizing closes it. The close — or a skip or defer, which ends work without a close — relabels the entry's provisional `open` status to its final one; these documented relabels (`open`, `pending-evaluation`) are the only permitted rewrites. Skip and defer keep or create the item at its current stage with `last_quality: untested`, no verdict, and set `due_at` = now + that stage's interval; a question still open at session end is `deferred`. A skip or defer before any answer text exists writes no `savepoint.md` entry — there is nothing verbatim to record; the recall item alone brings the question back.

While a question is open:

- Ask for reasoning, code evidence, or reconciliation when an answer is incomplete, unsupported, or contradictory.
- Describe gaps only in terms the question's own wording already contains — naming an unmentioned component is itself a leak.
- Flag contradictions only between the user's own claims; never say what the code actually does. Serial hypothesis-testing ("is it X?… then is it Y?") is verdict-fishing: probe once, then require finalize, skip, or assistance.

At close, record one quality signal in `recall.md` — `solid`, `shaky`, `failed`, `untested`, or (at recall closes where the source drifted) `superseded` — and deliver feedback per `feedback_timing` (`after_each`: now; `end_of_section`: aggregated at the chapter boundary): state the signal plainly, say which of the question's stated areas the answer covered, missed, or got wrong — you may now say a claim conflicts with the code — and never supply the missing fact. Reasoning must be grounded in code, behavior, or mechanism to earn a verdict: a finalized answer without it — including a just-probed hypothesis or pretext like "because the config handles it" — is a bare guess, and an answer finalized with its contradiction unreconciled is treated the same: closed `unresolved` with `untested` and no verdict. A guess cannot buy a confirmation.

Once closed, the record is immutable — but not beyond appeal, because the grader can be wrong. On `/save-point dispute` (or "that verdict was wrong"), re-derive the answer key carefully and show the evidence openly. If the verdict was wrong, append an `amended` entry under the same question ID — the corrected signal and a one-line rationale, the one agent-authored entry type, exempt from the user-prose rule the way relabels are exempt from immutability — rewrite `last_quality` to the corrected signal, and reschedule with the corrected signal anchored at dispute time. A vindicated dispute costs that item nothing. If the verdict stands, the shown evidence was assistance: mark `last_assisted: true`. Either way the original entry stays, and in both branches the shown evidence is taught material for the session-taint rule — new overlapping questions inherit the flag.

Re-answering before the next due date gets no close, no signal, and no scheduling effect — and it is `assisted` work. If the user asks to be taught after a close — encourage this — explain freely with code evidence: the closed attempt keeps its label, the item is marked `last_assisted: true`, and the restatement flow from the assistance section runs — its passing restatement is appended under the same question ID labeled `assisted`, and exactly one stage-0 follow-up question is created for the gap. An item created without a close gets `due_at` = creation time + the stage-0 interval. Never deliver a follow-up before it is due.

## Provide configured assistance

Treat "I don't know," uncertainty, and any request for help — including "give me a hint" — as normal learning signals, never as failed recall and never as requests to resist. Apply the saved `idk_policy` (options in the profile template). Under `progressive`, use the least assistance that moves the user forward:

1. Ask what part feels unclear.
2. Point to a small source trail or restate the question.
3. Give a conceptual hint.
4. Explain the mechanism with concrete code evidence.
5. Ask the user to restate it in their own words.

Let the user skip directly to an explanation. What is resisted is only revealing while the attempt would stay unaided: a full explanation is always available and converts the attempt to `assisted`; fragment and confirmation requests ("the first word", "is it X?") get a probe or that same offer — never the fragment.

After teaching, ask for a restatement and test it with a transfer probe (an example, an edge case, "what breaks if…") before saving. Judge parroting by meaning, not wording — an echo of your explanation, however rephrased, fails the probe. On failure, probe differently or leave it to the follow-up question; do not save. A passing restatement is saved as user-authored knowledge labeled `assisted`, and a shorter unaided recall question is created at stage 0. Restatements are the one exception to record-on-arrival: they are appended — verbatim, headed `assisted` directly — only at the moment they pass the probe, so a failed probe leaves no entry and no dangling `open` heading.

Accept natural-language tuning at any time — "too hard," "less trivia," "more architecture," "show me code first," "teach before testing," "spam me for 30 days" — confirm the change, apply it immediately, and update `profile.md`. Delivery, difficulty, depth, style, and repetition mode are tunable; everything governing evaluation, labeling, and stage movement is not — decline those requests and say why. "Teach before testing" is honored through the taint rule: questions on just-taught material carry `assisted` labels and flags.

## Run recall

Deliver in this order: (before an unsolicited prompt only) the first-prompt explanation if `last_prompt_at` has never been set, then the question labeled with its `repository_name`, then (cross-repository) the grading disclaimer and answer/defer choice, then a light "from memory?" check — out-of-session aids are self-reported, and that limitation is acceptable. Classify the attempt: **unaided** if the user answers before opening source, the save file, or another aid; **assisted** otherwise. When several items are deliverable, serve `failed` first, then items with `last_assisted: true`, then oldest due — in every mode. Dismissing is neutral: set `dismissed_on` to the local date — the item stays due for invoked recall but is not delivered unsolicited until the next local day. "Later" sets `snoozed_until` = now + `default_snooze`.

Evaluate by where you are:

- **Inside the question's repository**: re-derive the answer key from current source before judging; the code is the ground truth. But distinguish drift from forgetting: when the item's `source_paths` changed materially since its `created_at` and the answer was right for the old code, close it `superseded` — reset to stage 0 for relearning — never `failed`. The world changing is not the user forgetting.
- **Anywhere else**: if `cross_repo_recall` is `off` in the profile, another repository's items never surface outside it — they wait, because question text itself describes that repository. Otherwise: you have no answer key. Say so *before* the user answers: "I can't grade this here — it'll be checked next time you're in that repository. Answer now, or defer?" — defer is a dismissal. If they answer: blind-append it to that repository's `savepoint.md` headed `pending-evaluation (unaided)` or `(assisted)` per the classification; on the item, set `pending_evaluation: true`, record `answer_sha256` (`scripts/hash-answer.sh`, or: SHA-256 of the verbatim answer text — CRLF normalized, leading `>` markers with optional space stripped, all trailing newlines removed), and set `last_assisted: true` only if the attempt was assisted (never clear an existing `true`); refresh that `recall.md`'s frontmatter summary — a permitted scan. Give no verdict and no feedback. This is not a close: no quality signal, no reschedule, and the item is excluded from all delivery until evaluated. Assistance beyond defer/skip is unavailable here — say it awaits in the origin repository.

At the start of any session inside a repository, evaluate its pending answers first — read only the pending entries, an intended exemption from the rule below. If an answer no longer matches its `answer_sha256`, the record changed: close it `unresolved`. Otherwise each evaluation is that question's close: feedback, quality signal, relabel from `pending-evaluation` to the classification recorded in its heading, reschedule anchored at evaluation time.

During unaided recall, read only the due item from `recall.md`; do not open `savepoint.md` unless the user chooses assisted recall or asks for their save file.

## Schedule recall

A new recall item always starts at stage 0, whatever the close quality; the rules below govern subsequent closes only. Stages map to intervals: 0 → 1 day, 1 → 7 days, 2 → 30 days, 3 → 90 days.

`adaptive` mode — run `scripts/reschedule.sh <stage> <quality> <assisted> <importance>` when scripts are executable (it prints the new stage and `due_at`); otherwise apply the first matching rule at each close, then the clamp:

1. `superseded` → reset to stage 0 and clear `last_assisted`; the concept restarts fresh.
2. `failed` → drop one stage (minimum 0).
3. Assistance used on this attempt, or `last_assisted: true` → keep the current stage, then clear the flag. The flag is cleared only by a superseded close or the close of a due attempt.
4. `solid` → advance one stage (maximum 3).
5. `shaky` or `untested` → keep the current stage.
6. Clamp: items with importance 4–5 never exceed stage 2 — durable review beats a 90-day gap for load-bearing concepts.

Every close sets `due_at` = close time + the resulting stage's interval. At creation, assign importance — 4–5 for load-bearing invariants and data-loss, security, or incident paths; 3 (default) for core flows; 1–2 for details — and record the item's `section`, its `chapter` for chapter questions (empty otherwise; such items never affect chapter status), its `created_at`, and the `source_paths` its answer key rests on, for the drift-vs-forgetting distinction at recall.

`intensive_30d` mode — every active concept is due daily until its `intensive_until` date (creation + 30 days), rotating wording under stable IDs. After day 30 the item graduates to adaptive at its current stage with full history.

Switching modes changes future scheduling only. Any switch to intensive — by command, by "spam me for 30 days", or when offered after the first session — means the user wants volume: confirm raising `daily_limit` (suggest 10), since drilling cannot fit under the default caps.

## Respect interruption limits

Delivery caps apply to **unsolicited prompts only**; anything the user invokes is uncapped. Limits live in `profile.md` (defaults: `daily_limit: 3`, `minimum_gap: 90m`, `questions_per_interruption: 1`, `default_snooze: 4h`); counts live globally in `~/.save-point/scheduler.md` and span repositories and hosts. Reset `prompts_today` when the local date no longer matches `prompt_date`.

Offer at most `questions_per_interruption` questions at a host-supported natural boundary: passing tests, commits, pull-request events, repository switches, session start or end, inactivity. Suppress recall while commands run, the user edits actively, tests fail, conflicts are unresolved, urgent debugging is active, or the current task is incomplete. The very first unsolicited prompt explains the deal: "I'll do this at most 3×/day at natural moments — say 'flow' to pause, or 'interruptions off' for manual-only."

A boundary check reads only `profile.md` frontmatter, `scheduler.md`, and each `recall.md`'s frontmatter. An item is deliverable unsolicited when `pending_evaluation` is false, max(`due_at`, `snoozed_until`) has passed, and `dismissed_on` is not today; the frontmatter summary — `next_due_at` (earliest instant any item becomes deliverable unsolicited, possibly already past — a dismissed item contributes from its next local midnight), `due_count` (deliverable count as of the last write, advisory), `repository_name` — is what makes the check sufficient, so maintain it on every recall write. Dueness is decided by whether `next_due_at` has passed, never by `due_count`. Deliver by then reading just the due item's section.

Flow mode is global (`flow_until` in `scheduler.md`); `interruption_style: manual_only` turns unsolicited delivery off permanently. A user suppression always overrides scheduling. Hosts with prompt hooks can register `scripts/check-due.sh` — it performs this same frontmatter-only check and emits a one-line nudge; the skill still owns delivery, suppression, and counter updates. If the host exposes no accepted boundaries and no hook is registered, check due items when Save Point is invoked, and say so. Never claim that the local MCP process can wake or interrupt a host by itself.

## Preserve isolation

- Never read another repository's `savepoint.md` (saved answers) into an active context; reading a due item from its `recall.md` for delivery, refreshing its frontmatter summary, and blind appends are permitted.
- Never use stored answers to answer an unrelated coding question.
- A recall prompt from another repository shows the question labeled with its `repository_name` — nothing more.

## Handle unavailable persistence

If the host cannot write `~/.save-point`, continue with ephemeral in-session state and say so. Do not claim recall was persisted or scheduled. Never weaken answer integrity or interruption safety as a fallback.

---

Maintainers: `features/` is the behavior contract and `reference/maintenance.md` covers invariants, the contract map, and MCP distribution. Neither is needed to run a session.
