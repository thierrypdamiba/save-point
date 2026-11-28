# Eval results

One row per real run of `eval/run.sh`. The raw output of each run is saved in `eval/results/` and the last column names it. Rows come only from runs someone made. A scenario that did not run is not listed as passed.

A pass here means the assert script for that scenario passed on that run. It is a count from one run, not a rate. Model replies vary between runs.

| Date (UTC) | Model | Save Point version | Commit | Passed | Scenarios run | Raw output |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-11-26 | default | 0.12.0 | 3b56c1f | 1/1 | s01-solid-close | results/2026-11-26-default-3b56c1f.log |
| 2026-11-28 | default | 0.12.0 | 9d92b9e | 15/15 | s01-solid-close s02-bare-guess s03-assisted-label s04-no-leak s05-superseded-drift s06-failed-dispute s07-teach-taint s08-integrity-not-tunable s09-cross-repo-pending s10-doc-solid-close s11-doc-superseded-drift s12-doc-no-leak s13-custom-intervals s14-doc-persona-intern s15-doc-persona-custom-no-leak | results/2026-11-28-default-9d92b9e.log |
