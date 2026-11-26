# Using Save Point on a team

This page is for an engineering manager or IT lead deciding how to roll Save Point out. Read [security-and-privacy.md](security-and-privacy.md) first. This page does not repeat it.

Save Point has no server, no account and no admin console. Everything is per person, per machine. A rollout is a shared install command plus a shared set of habits.

## What stays private

Each person's state lives in `~/.save-point`. It holds their answers word for word, their recall schedule, and question text that names the risky parts of your code. Treat it like personal notes about where the risks are.

- Do not collect it, sync it, or put it in a shared drive or a dotfiles repo.
- Do not use it to rank people. It records what one person answered, labeled unaided or assisted. It was not built as a performance review tool, and nothing in it is scored across people.
- Do not commit it to a repository.

If someone wants to share a question or an answer, they copy that one piece by hand.

## Shared and multi-user machines

State is stored under the home directory of the user who runs it. Two people with separate accounts get two separate `~/.save-point` folders. The directory is created `0700` and files `0600`, so other accounts cannot read them by default.

Do not run Save Point from a shared account (a build user, a pairing login). Answers from different people would be mixed in one folder.

## Client and tenant separation

Question text describes a repository's internals. If one person works on repositories that belong to different clients, they should set `cross_repo_recall: off` in `~/.save-point/profile.md`. Then a repository's questions are asked only inside that repository.

## Turning interruptions down for everyone

Unsolicited prompts are controlled by these `profile.md` settings: `interruption_style`, `daily_limit`, `minimum_gap`, `questions_per_interruption` and `default_snooze`. They cap prompts the tool starts. A session the person starts is never capped.

| Goal | What to do |
| --- | --- |
| No unprompted questions | Each person says `/save-point interruptions off`. This sets `interruption_style: manual_only`. |
| Fewer unprompted questions | Lower `daily_limit` or raise `minimum_gap` in `profile.md`. |
| Hide the one-line stats above each question | `question_stats: off` |
| Remove the hook completely | Run `./install.sh --uninstall` or delete the Save Point entry under `hooks.UserPromptSubmit` in `~/.claude/settings.json`. |

These are per person. Save Point has no central switch. A team that wants one can hand out the same `profile.md` values in its onboarding notes. `profile.md` is the one state file where a person's edits are honored as written, and `setup_status: confirmed` skips the first-run setup. Not tested here: pushing settings to a fleet with your own device management. If you do, remember the hook entry is in Claude Code's `~/.claude/settings.json`.

## Pinning a version

Give everyone the same version so they ask and record the same way:

```sh
./install.sh --ref <tag>
cat ~/.claude/skills/save-point/VERSION
```

Ask people to send you the contents of that `VERSION` file if you need to confirm. To upgrade or roll back, run the same command with another ref. Their `~/.save-point` is not touched. Tags exist only when the owner publishes one, so check the repository's tags before you promise a version.

The curl one-liner in the README installs whatever is on `main` at that moment. For a team, clone the repository, review it, and run `./install.sh` from the checkout, or use `--ref`.

## If you are using the answers for research

The README describes a planned study. It needs everyone on one fixed version. Pin with `--ref`, and record the version. Do not change `recall_intervals`, `repetition_mode` or `persona` partway through for people in the same group, because that makes results harder to compare. Tell participants what is recorded: their answers word for word, with the unaided or assisted label.

## Removing it

`./install.sh --uninstall` removes the skill and the hook entry on that machine. It leaves `~/.save-point` alone, because those are the person's records. Whether to delete them is their choice.

## What this page does not claim

- It does not say how many teams use Save Point. It makes no claim about adoption or results.
- It does not describe any central reporting. There is none.
