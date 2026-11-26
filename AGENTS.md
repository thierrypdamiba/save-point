# Working on Save Point

This file is for any agent or person changing this repository. Read it before you change anything.

## Two tracks

- `main` is production. It is what `install.sh` and the plugin marketplace install. Only the owner promotes changes to it.
- `dev` is where all work lands first. Every change goes to `dev` through a pull request.

Promotion is a pull request from `dev` into `main`, opened and merged by the owner. Nobody else opens, approves, or merges a pull request into `main`, and nobody pushes to `main` directly.

## Rules for every change

1. Branch from `dev`. Open the pull request against `dev`.
2. One focused change per pull request. Say what changed, why, what you tested, and what you did not test.
3. CI must pass before a merge into `dev`.
4. Never report a test pass you did not observe. Give counts: runs and passes.
5. Never weaken an integrity rule or an assert to make a test pass. This covers the no-leak rules, verbatim answer recording, the unaided and assisted labels, and the answer key. If a rule looks wrong, write it up in `ROADMAP.md` under "Needs the owner" and leave it alone.
6. Default behavior does not change without a note in `CHANGELOG.md` under "Unreleased". Existing users must see no surprise.
7. Do not touch a user's real `~/.save-point`. Eval runs use the harness sandbox. Check before and after.
8. Do not contact anyone, post anywhere outside this repository, or add telemetry.
9. Prose rules: plain words, short sentences, no em dashes, no hype, no claims about users, results, or adoption that are not true today.

## Files that track the work

- `ROADMAP.md`: what to do next, in priority order, plus a "Needs the owner" list for decisions only the owner can make.
- `CHANGELOG.md`: what changed, newest first, with an "Unreleased" section for what is on `dev` and not yet on `main`.

## The research study

The README describes a planned study. A study needs a fixed version of the tool. Do not change question selection, grading, scheduling defaults, or record formats in a way that would make results from two versions hard to compare, without flagging it under "Needs the owner".
