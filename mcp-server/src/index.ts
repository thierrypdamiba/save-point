#!/usr/bin/env node
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { serveStdio } from "@modelcontextprotocol/server/stdio";

import { createCatalogServer } from "./server.js";

async function main(): Promise<void> {
  const here = dirname(fileURLToPath(import.meta.url));
  const skillRoot = process.env.WALKTHROUGH_SKILL_DIR || resolve(here, "../../../walkthrough");
  serveStdio(() => createCatalogServer(skillRoot), {
    legacy: "serve",
    onerror: (error) => console.error("Walkthrough MCP transport error:", error),
  });
}

main().catch((error: unknown) => {
  console.error("Walkthrough MCP server failed:", error);
  process.exitCode = 1;
});
