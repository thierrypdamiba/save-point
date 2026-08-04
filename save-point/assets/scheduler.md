---
version: 1
prompt_date:
prompts_today: 0
last_prompt_at:
flow_until:
---

# Save Point Scheduler

Global delivery state, shared across every repository and host. Boundary checks read this file plus `profile.md` and `recall.md` frontmatter — never `walkthrough.md`.

- `prompt_date`: the user's **local** calendar date the count applies to; when today's local date differs, reset `prompts_today` to 0.
- `prompts_today`: unsolicited prompts delivered during that local day, across all repositories.
- `last_prompt_at`: UTC instant of the most recent unsolicited prompt, for the `minimum_gap` check.
- `flow_until`: UTC instant until which all unsolicited prompts are suppressed; empty when flow mode is off.

User-invoked sessions do not increment `prompts_today` and ignore `flow_until`.
