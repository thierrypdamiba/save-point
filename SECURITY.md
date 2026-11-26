# Security policy

## Report a problem

Use GitHub private vulnerability reporting: open the Security tab of https://github.com/thierrypdamiba/save-point and choose "Report a vulnerability". Please do not open a public issue for a security problem.

If that option is not shown to you, open a public issue that says only "I have a security report, please enable private reporting". Do not put details in it.

There is no promised response time. This is a small open-source project.

## In scope

- The scripts in `save-point/scripts/`, `scripts/` and `install.sh`.
- The MCP server in `mcp-server/`.
- Anything in the skill that could write outside `~/.save-point`, leak one repository's answers into another's context, or reveal an answer key while a question is open.
- File permissions on what Save Point creates.

## Out of scope

- What your host model does with text it reads. See `docs/security-and-privacy.md`.
- Problems in the host tools themselves (Claude Code, Codex, Goose).
- Someone with write access to your home directory or your `~/.claude` folder. They can already change anything.

## What Save Point does and does not do

The full list of what it reads, writes and sends is in `docs/security-and-privacy.md`.
