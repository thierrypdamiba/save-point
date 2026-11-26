---
version: 1
repository_id: REPLACE_ME
repository_name: REPLACE_ME
next_due_at:
due_count: 0
---

# Recall Queue

One section per question. No answer keys and no user answers — answer text lives in `savepoint.md`, keys are re-derived from source; `answer_sha256` holds only a digest.

An item is **deliverable unsolicited** when `pending_evaluation` is false, max(`due_at`, `snoozed_until`) has passed, and `dismissed_on` is not the current local date. Maintain the frontmatter summary on every write: `next_due_at` is the earliest instant at which any item becomes deliverable unsolicited — possibly already in the past; boundary checks test whether it has passed. A snoozed item contributes max(`due_at`, `snoozed_until`); a dismissed item contributes no earlier than its next local midnight; a pending item contributes nothing. `due_count` is the deliverable count as of the last write, advisory only — dueness is always decided by `next_due_at`.

Field values: question IDs are `q` + a per-repository ordinal, stable under rewording. `stage` is 0–3 on the default list (intervals 1, 7, 30, 90 days). With the user's own `recall_intervals` in the profile, a stage is a position in that list, from 0 to its last entry and never above 7. `scheduling_mode` is `adaptive` or `intensive_30d`. `importance` is 1–5 (4–5 = core invariants and data-loss/security/incident paths; 3 = core flows, the default; 1–2 = details). `section` is `chapter` | `map` | `secret` | `boss-fight` | `new-game-plus`; `chapter` is the chapter title for chapter questions — the source of truth for save-point status — and empty for other sections, which never affect chapter status. `last_quality` is `untested` | `solid` | `shaky` | `failed` | `superseded` (the item's `source_paths` changed materially after `created_at` and the answer was right for the old code — resets to stage 0; drift is not forgetting). `last_assisted` is true when an attempt used assistance or the concept was explained since the last close; it is never cleared by recording an attempt — only by the close of a due attempt. `answer_sha256` is the SHA-256 of a pending answer's verbatim text (`scripts/hash-answer.sh`: CRLF normalized, leading `>` markers with optional space stripped, all trailing newlines removed), checked at evaluation. `dismissed_on` is the local date of an unsolicited-delivery dismissal. Timestamps are UTC ISO-8601 instants.

Document workspaces only: `source_paths` entries carry a line range (`brief.md:L12-L14`, and `@sources/counts.md:L3-L9` for a file under the sources folder), and `source_sha256` holds one `path=digest` pair per cited file, the SHA-256 of its raw bytes when the item was created or last refreshed (`scripts/hash-source.sh`). A copy of each cited file is kept in `snapshots/`, named by that digest. A digest that no longer matches the file means the document changed. It is checked for drift at recall and is never treated as tampering. `source_sha256` stays empty for repository items.

<!--
## q001

- due_at: 2026-01-01T12:00:00Z
- created_at: 2025-12-31T12:00:00Z
- source_paths: src/queue.js, src/worker.js
- source_sha256:
- stage: 0
- scheduling_mode: adaptive
- intensive_until:
- importance: 3
- section: chapter
- chapter: Chapter 1
- last_assisted: false
- last_quality: untested
- pending_evaluation: false
- snoozed_until:
- dismissed_on:
- answer_sha256:

### Prompt

Why does this subsystem behave this way?
-->
