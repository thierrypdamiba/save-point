---
version: 1
setup_status: unset
goal: mixed
idk_policy: offer_choice
difficulty: new-engineer
preferred_depth: balanced
feedback_timing: after_each
repetition_mode: adaptive
intensive_offered: false
daily_limit: 3
minimum_gap: 90m
questions_per_interruption: 1
default_snooze: 4h
interruption_style: natural_boundaries
cross_repo_recall: on
---

# Save Point Profile

The user's preferences. This file is written only when the user confirms a setup summary (`setup_status: confirmed`) or declines setup (`skipped`); a status of `unset` means setup never completed and should be offered again. Update values only on user confirmation or request. This is the one state file where user edits are honored as-is.

Legal values per field — present these as the options during setup:

- `setup_status`: `unset` | `confirmed` | `skipped`
- `goal`: `learn` | `recall` | `mixed`
- `idk_policy`: `explain` (explain immediately) | `hint` | `source_trail` | `offer_choice` (ask each time among a hint, a source trail, a full explanation, or skip-and-revisit) | `skip_revisit` (skip and revisit later) | `progressive` (start with the smallest nudge, escalate)
- `difficulty`: `new-engineer` | `maintainer` | `operator`
- `preferred_depth`: `overview` | `balanced` | `deep-dive`
- `feedback_timing`: `after_each` | `end_of_section`
- `repetition_mode`: `adaptive` | `intensive_30d` (not asked at setup; offered once at the first session's closing save point, then `intensive_offered` is set true)
- `interruption_style`: `natural_boundaries` | `manual_only`
- `cross_repo_recall`: `on` | `off` (not asked at setup; set on request) — `off` keeps every repository's questions inside that repository, since question text describes its internals (useful when repositories belong to different clients or tenants)

Delivery settings (`daily_limit`, `minimum_gap`, `questions_per_interruption`, `default_snooze`) cap unsolicited prompts only — user-invoked sessions are never capped.
