import assert from "node:assert/strict";
import { resolve } from "node:path";
import test from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";
import { z } from "zod";

test("serves the skill through a real stdio process", async () => {
  const projectRoot = resolve(import.meta.dirname, "..");
  const environment = Object.fromEntries(
    Object.entries(process.env).filter((entry): entry is [string, string] => entry[1] !== undefined),
  );
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: ["--import", "tsx", resolve(projectRoot, "src/index.ts")],
    cwd: projectRoot,
    env: {
      ...environment,
      SAVE_POINT_SKILL_DIR: resolve(projectRoot, "../save-point"),
    },
    stderr: "pipe",
  });
  const client = new Client(
    { name: "save-point-stdio-test", version: "1.0.0" },
    { versionNegotiation: { mode: "auto" } },
  );
  await client.connect(transport);

  try {
    const resources = await client.listResources();
    assert.equal(client.getNegotiatedProtocolVersion(), "2026-07-28");
    assert.ok(resources.resources.some((resource) => resource.uri.endsWith("/SKILL.md")));

    const catalog = await client.request(
      { method: "skills/list", params: {} },
      z.object({ skills: z.array(z.object({ uri: z.string() })) }),
    );
    assert.equal(catalog.skills.length, 1);
  } finally {
    await client.close();
  }
});

test("keeps the legacy MCP initialization path", async () => {
  const projectRoot = resolve(import.meta.dirname, "..");
  const environment = Object.fromEntries(
    Object.entries(process.env).filter((entry): entry is [string, string] => entry[1] !== undefined),
  );
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: ["--import", "tsx", resolve(projectRoot, "src/index.ts")],
    cwd: projectRoot,
    env: { ...environment, SAVE_POINT_SKILL_DIR: resolve(projectRoot, "../save-point") },
    stderr: "pipe",
  });
  const client = new Client({ name: "save-point-legacy-test", version: "1.0.0" });
  await client.connect(transport);

  try {
    assert.equal(client.getNegotiatedProtocolVersion(), "2025-11-25");
    const tools = await client.listTools();
    assert.ok(tools.tools.some((tool) => tool.name === "load_skill"));
  } finally {
    await client.close();
  }
});
