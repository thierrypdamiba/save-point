# State file formats

This page describes the files Save Point keeps under `~/.save-point`. It is for people who write tooling on top of them, and for anyone comparing records from two versions of Save Point.

The templates in `save-point/assets/` are the source of truth. This page restates them. A CI step checks that every field in a template is named here. This page does not change any format.

All files are plain Markdown with a front matter block between `---` lines. Timestamps are UTC ISO-8601 instants, such as `2026-08-04T12:00:00Z`. Fields that name a calendar day (`prompt_date`, `dismissed_on`) hold the user's local date.

Every file carries `version: 1`. Nothing reads that number yet, and there is no migration. See "Format marker" at the end.

## Layout

```text
~/.save-point/
  profile.md
  scheduler.md
  repositories/<repository-id>/
    savepoint.md
    recall.md
    snapshots/        document workspaces only
```

The `<repository-id>` is the first 20 hex characters of the SHA-256 of the canonical identity string. `save-point/scripts/derive-repo-id.sh` prints both.

## profile.md

The user's preferences. This is the one file where hand edits are honored. Legal values for each field are listed in the template. The fields are:

- `version`
- `setup_status`: `unset`, `confirmed`, or `skipped`
- `goal`
- `idk_policy`
- `difficulty`
- `persona`
- `preferred_depth`
- `feedback_timing`
- `repetition_mode`
- `recall_intervals`
- `intensive_offered`
- `daily_limit`
- `minimum_gap`
- `questions_per_interruption`
- `default_snooze`
- `interruption_style`
- `cross_repo_recall`
- `question_stats`

A missing or illegal value means the template default.

## scheduler.md

Global delivery state, shared by every repository. Fields:

- `version`
- `prompt_date`: the local date the count applies to
- `prompts_today`: unsolicited prompts delivered that day
- `last_prompt_at`: UTC instant of the last unsolicited prompt
- `flow_until`: UTC instant until which unsolicited prompts are off, or empty

User-invoked sessions do not change these fields.

## recall.md

One file per repository. Front matter:

- `version`
- `repository_id`
- `repository_name`
- `next_due_at`: the earliest instant any item becomes deliverable unsolicited, possibly already past
- `due_count`: advisory only

Then one `## q<ordinal>` section per question, with these fields:

- `due_at`
- `created_at`
- `source_paths`
- `source_sha256`: document workspaces only
- `stage`
- `scheduling_mode`: `adaptive` or `intensive_30d`
- `intensive_until`
- `importance`: 1 to 5
- `section`: `chapter`, `map`, `secret`, `boss-fight`, or `new-game-plus`
- `chapter`
- `last_assisted`
- `last_quality`: `untested`, `solid`, `shaky`, `failed`, or `superseded`
- `pending_evaluation`
- `snoozed_until`
- `dismissed_on`
- `answer_sha256`: a digest only

The section then holds a `### Prompt` heading and the question text. This file never holds an answer or an answer key.

Question IDs are `q` plus a per-repository ordinal and stay the same when the question is reworded.

## savepoint.md

One file per repository. Front matter:

- `version`
- `repository_id`
- `repository_name`
- `canonical_remote`: the normalized identity string. For a document workspace it is `doc:` plus the resolved path, and a `sources_root` field may also appear.

Then one entry per attempt, headed `## <question-id> — <status> @ <UTC timestamp>`. The body is the user's answer, word for word, as a block quote. Statuses are `open`, `unaided`, `assisted`, `skipped`, `deferred`, `pending-evaluation (unaided)`, `pending-evaluation (assisted)`, `superseded`, `unresolved`, and `amended`.

Entries are appended and never edited. The only permitted rewrite is relabeling an `open` or `pending-evaluation` heading.

## snapshots/

Document workspaces only. Each file is a byte-for-byte copy of a cited source, named by the SHA-256 of its bytes, mode `0600`.

## Format marker

`version: 1` is written by the templates, but no script or skill step checks it. A format change would need a real marker and a migration rule. That decision belongs to the owner (see ROADMAP.md, "Needs the owner").
