import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { resolve } from "node:path";
import test from "node:test";

import { Client, InMemoryTransport } from "@modelcontextprotocol/client";
import { z } from "zod";

import { createCatalogServer } from "../src/server.js";

test("advertises and serves the complete Save Point skill", async () => {
  const skillRoot = resolve(import.meta.dirname, "../../save-point");
  const server = await createCatalogServer(skillRoot);
  const client = new Client(
    { name: "save-point-test", version: "1.0.0" },
    { versionNegotiation: { mode: "auto" } },
  );
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();

  await server.connect(serverTransport);
  await client.connect(clientTransport);

  try {
    assert.deepEqual(client.getServerCapabilities()?.extensions?.["io.modelcontextprotocol/skills"], {
      directoryRead: true,
    });
    // Direct in-memory McpServer wiring exercises the SDK's legacy-compatible path;
    // the real stdio test below covers modern server/discover negotiation.

    const tools = await client.listTools();
    assert.deepEqual(
      tools.tools.map((tool) => tool.name).sort(),
      ["list_skills", "load_skill"],
    );
    const loaded = await client.callTool({ name: "load_skill", arguments: { name: "save-point" } });
    assert.equal(loaded.isError, undefined);
    assert.match(JSON.stringify(loaded.structuredContent), /Build understanding, then test whether it lasts/);

    const prompts = await client.listPrompts();
    assert.ok(prompts.prompts.some((prompt) => prompt.name === "save-point"));
    const prompt = await client.getPrompt({ name: "save-point", arguments: { request: "Quiz me" } });
    assert.match(JSON.stringify(prompt.messages), /Quiz me/);

    const resourceSchema = z.object({ uri: z.string(), digest: z.string() });
    const skillSchema = z.object({
      uri: z.string(),
      frontmatter: z.record(z.string(), z.unknown()),
      resources: z.array(resourceSchema),
    });
    const catalogSchema = z.object({
      skills: z.array(
        skillSchema,
      ),
      ttlMs: z.number(),
      cacheScope: z.string(),
    });
    const catalog = await client.request({ method: "skills/list", params: {} }, catalogSchema);
    assert.equal(catalog.skills.length, 1);
    assert.equal(catalog.ttlMs, 60_000);
    assert.equal(catalog.skills[0].frontmatter.name, "save-point");
    assert.ok(catalog.skills[0].resources.length >= 10);
    for (const resource of catalog.skills[0].resources) {
      assert.match(resource.digest, /^sha256:[a-f0-9]{64}$/);
    }

    const fetched = await client.request(
      { method: "skills/get", params: { uri: catalog.skills[0].uri } },
      z.object({ skill: skillSchema }),
    );
    assert.deepEqual(fetched.skill, catalog.skills[0]);

    const directory = await client.request(
      { method: "resources/directory/read", params: { uri: "skill://save-point-local/save-point/features" } },
      z.object({ resources: z.array(z.object({ name: z.string(), mimeType: z.string() })) }),
    );
    assert.ok(directory.resources.some((resource) => resource.name === "cross-client.feature"));
    assert.ok(directory.resources.some((resource) => resource.name === "document-mode.feature"));
    assert.ok(catalog.skills[0].resources.some((resource) => resource.uri.endsWith("/scripts/hash-source.sh")));
    assert.match(JSON.stringify(loaded.structuredContent), /## Document workspaces \(new\)/);

    for (const resource of catalog.skills[0].resources) {
      const response = await client.readResource({ uri: resource.uri });
      assert.equal(response.contents.length, 1);
      const item = response.contents[0];
      const bytes = "text" in item ? Buffer.from(item.text, "utf8") : Buffer.from(item.blob, "base64");
      const digest = `sha256:${createHash("sha256").update(bytes).digest("hex")}`;
      assert.equal(digest, resource.digest);
    }
  } finally {
    await client.close();
    await server.close();
  }
});
