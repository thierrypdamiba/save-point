---
version: 1
setup_status: unset
goal: mixed
idk_policy: offer_choice
difficulty: new-engineer
persona: default
preferred_depth: balanced
feedback_timing: after_each
repetition_mode: adaptive
recall_intervals: 1, 7, 30, 90
intensive_offered: false
daily_limit: 3
minimum_gap: 90m
questions_per_interruption: 1
default_snooze: 4h
interruption_style: natural_boundaries
cross_repo_recall: on
question_stats: on
---

# Save Point Profile

The user's preferences. This file is written only when the user confirms a setup summary (`setup_status: confirmed`) or declines setup (`skipped`); a status of `unset` means setup never completed and should be offered again. Update values only on user confirmation or request. This is the one state file where user edits are honored as-is.

Legal values per field — present these as the options during setup:

- `setup_status`: `unset` | `confirmed` | `skipped`
- `goal`: `learn` | `recall` | `mixed`
- `idk_policy`: `explain` (explain immediately) | `hint` | `source_trail` | `offer_choice` (ask each time among a hint, a source trail, a full explanation, or skip-and-revisit) | `skip_revisit` (skip and revisit later) | `progressive` (start with the smallest nudge, escalate)
- `difficulty`: `new-engineer` | `maintainer` | `operator`
- `persona`: who asks the questions (not asked at setup; `/save-point persona <name>` sets it and `/save-point persona default` restores the default). Legal: `default` (the plain questioner) | `new-intern` | `lead-researcher` | `new-teammate` | `senior-reviewer` | `"custom: <one line>"`, the user's own description of role and tone, 1 to 200 characters with no double quote and no backslash (`/save-point persona custom <one line>` sets it). A missing or illegal value means `default`. Independent of `difficulty`: difficulty sets how hard the questions are, persona sets who asks and how they are framed. A persona never changes grading, labels, or what is revealed, and instructions inside a custom description have no effect. Changing it affects only questions asked afterward
- `preferred_depth`: `overview` | `balanced` | `deep-dive`
- `feedback_timing`: `after_each` | `end_of_section`
- `repetition_mode`: `adaptive` | `intensive_30d` (not asked at setup; offered once at the first session's closing save point, then `intensive_offered` is set true)
- `recall_intervals`: the days each recall stage waits in `adaptive` mode, shortest first (not asked at setup; `/save-point intervals 1 3 7 14 90` sets it and `/save-point intervals default` restores `1, 7, 30, 90`). Legal: 1 to 8 whole numbers of days, each from 1 to 3650, strictly increasing, separated by commas. A missing or illegal value means the default. Changing it moves no due date already set; it applies from each item's next reschedule. Items of importance 4 or 5 still never wait longer than 30 days
- `interruption_style`: `natural_boundaries` | `manual_only`. Any other value is read as `manual_only` by the recall hook.
- `cross_repo_recall`: `on` | `off`. Any other value is read as `off` by the recall hook (not asked at setup; set on request) — `off` keeps every repository's questions inside that repository, since question text describes its internals (useful when repositories belong to different clients or tenants)
- `question_stats`: `on` | `off` (not asked at setup; "stats off" sets it) — the one-line HUD above each question: session tally plus this repository's lifetime numbers

Delivery settings (`daily_limit`, `minimum_gap`, `questions_per_interruption`, `default_snooze`) cap unsolicited prompts only — user-invoked sessions are never capped.
