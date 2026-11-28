#!/usr/bin/env node
import { access } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { serveStdio } from "@modelcontextprotocol/server/stdio";

import { createCatalogServer } from "./server.js";

async function main(): Promise<void> {
  const here = dirname(fileURLToPath(import.meta.url));
  const skillRoot = process.env.SAVE_POINT_SKILL_DIR || resolve(here, "../../../save-point");
  // Fail at start, not on the first client request. A wrong path would otherwise
  // start fine and then answer every client with "Internal server error".
  try {
    await access(join(skillRoot, "SKILL.md"));
  } catch {
    const source = process.env.SAVE_POINT_SKILL_DIR ? "SAVE_POINT_SKILL_DIR" : "the default skill folder";
    throw new Error(`no SKILL.md in ${skillRoot} (from ${source}). Set SAVE_POINT_SKILL_DIR to the save-point skill folder, or run the server from a full checkout.`);
  }
  serveStdio(() => createCatalogServer(skillRoot), {
    legacy: "serve",
    onerror: (error) => console.error("Save Point MCP transport error:", error),
  });
}

main().catch((error: unknown) => {
  console.error("Save Point MCP server failed:", error);
  process.exitCode = 1;
});
