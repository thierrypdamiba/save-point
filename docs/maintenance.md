# Maintenance

## Changing the version

The version is written in four files. Change all four in one commit:

- `.claude-plugin/plugin.json`
- `mcp-server/package.json`
- `mcp-server/package-lock.json` (the top `version` and the `packages[""]` entry; `npm install --package-lock-only` updates both)
- `mcp-server/src/server.ts` (the `version` in the server name block)

CI runs `sh scripts/check-versions.sh` and fails if they differ. Tags and releases belong to the owner.
