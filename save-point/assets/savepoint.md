---
version: 1
repository_id: REPLACE_ME
repository_name: REPLACE_ME
canonical_remote: REPLACE_ME
---

# Save File

Only user-authored answers, recorded verbatim the moment they are given. Never add generated explanations as user prose, and never store answer keys. `canonical_remote` is the normalized identity string from the repository-ID derivation; `repository_name` is its final path segment.

Every attempt — first answers and recall attempts alike — is appended as its own entry headed `## <question-id> — <status> @ <UTC timestamp>`, so one question ID may have many entries. Statuses: `open` (provisional — the append-time status, relabeled at close, skip, or defer), `unaided`, `assisted`, `skipped`, `deferred`, `pending-evaluation (unaided)` / `pending-evaluation (assisted)` (awaiting in-repository evaluation; relabeled to the recorded classification at evaluation), `superseded` (right for code that has since changed), `unresolved` (bare guess, unreconciled contradiction, or a record altered outside a session), or `amended` (a dispute's correction, appended as a new entry — the original stays). Relabeling `open` and `pending-evaluation` headings is the only permitted rewrite — everything else, once written, is the agent's record.

<!--
## q001 — unaided @ 2026-01-01T12:00:00Z

> The user's answer, verbatim.

## q001 — pending-evaluation (unaided) @ 2026-01-08T09:30:00Z

> A later recall attempt, verbatim.
-->
