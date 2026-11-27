import assert from "node:assert/strict";
import { mkdtemp, mkdir, writeFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";

import { Client, InMemoryTransport } from "@modelcontextprotocol/client";
import { z } from "zod";

import { createCatalogServer } from "../src/server.js";

const realSkill = resolve(import.meta.dirname, "../../save-point");
const PREFIX = "skill://save-point-local/save-point";
const dirSchema = z.object({ resources: z.array(z.object({ uri: z.string(), name: z.string() })) });

async function connect(skillRoot: string) {
  const server = await createCatalogServer(skillRoot);
  const client = new Client({ name: "save-point-test", version: "1.0.0" }, { versionNegotiation: { mode: "auto" } });
  const [c, s] = InMemoryTransport.createLinkedPair();
  await server.connect(s);
  await client.connect(c);
  return { client, close: async () => { await client.close(); await server.close(); } };
}

async function tempSkill(files: Record<string, string>): Promise<string> {
  const dir = await mkdtemp(join(tmpdir(), "sp-skill-"));
  for (const [name, body] of Object.entries(files)) {
    const path = join(dir, name);
    await mkdir(resolve(path, ".."), { recursive: true });
    await writeFile(path, body);
  }
  return dir;
}

const GOOD = "---\nname: save-point\ndescription: test skill\n---\nbody\n";

test("resources/directory/read refuses bad URIs", async () => {
  const { client, close } = await connect(realSkill);
  try {
    for (const uri of [
      `${PREFIX}/../../etc`,
      `${PREFIX}/features/../../..`,
      "file:///etc",
      "file:///etc/passwd",
      "http://example.com/x",
      "skill://other/save-point",
      `${PREFIX}/SKILL.md`,
      `${PREFIX}/nope`,
      `${PREFIX}x`,
    ]) {
      await assert.rejects(
        client.request({ method: "resources/directory/read", params: { uri } }, dirSchema),
        `should refuse ${uri}`,
      );
    }
    const ok = await client.request({ method: "resources/directory/read", params: { uri: PREFIX } }, dirSchema);
    assert.ok(ok.resources.some((r) => r.name === "SKILL.md"));
  } finally {
    await close();
  }
});

test("skills/get refuses an unknown URI", async () => {
  const { client, close } = await connect(realSkill);
  try {
    await assert.rejects(
      client.request({ method: "skills/get", params: { uri: "skill://save-point-local/other" } }, z.object({ skill: z.unknown() })),
      /Unknown skill URI/,
    );
  } finally {
    await close();
  }
});

test("load_skill refuses a name other than save-point", async () => {
  const { client, close } = await connect(realSkill);
  try {
    let refused = false;
    try {
      const res = await client.callTool({ name: "load_skill", arguments: { name: "other" } });
      refused = res.isError === true;
    } catch {
      refused = true;
    }
    assert.ok(refused, "load_skill accepted an unknown name");
  } finally {
    await close();
  }
});

test("a skill directory with no SKILL.md fails startup", async () => {
  const dir = await tempSkill({ "README.md": "x" });
  try {
    await assert.rejects(createCatalogServer(dir), /missing SKILL\.md/);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});

test("bad frontmatter fails startup", async () => {
  const cases: Array<[string, RegExp]> = [
    ["no frontmatter\n", /missing YAML frontmatter/],
    ["---\nname: 5\ndescription: x\n---\n", /string name and description/],
    ["---\nname: save-point\n---\n", /string name and description/],
    ["---\n- a\n- b\n---\n", /string name and description/],
    ["---\n\n---\n", /missing YAML frontmatter|must be an object/],
  ];
  for (const [body, pattern] of cases) {
    const dir = await tempSkill({ "SKILL.md": body });
    try {
      await assert.rejects(createCatalogServer(dir), pattern, body);
    } finally {
      await rm(dir, { recursive: true, force: true });
    }
  }
});

test("dotfiles and dot directories are not served", async () => {
  const dir = await tempSkill({
    "SKILL.md": GOOD,
    "notes.md": "ok",
    ".secret": "hidden",
    ".git/config": "hidden",
  });
  const { client, close } = await connect(dir);
  try {
    const listing = await client.request({ method: "resources/directory/read", params: { uri: PREFIX } }, dirSchema);
    assert.deepEqual(listing.resources.map((r) => r.name).sort(), ["SKILL.md", "notes.md"]);
    const all = await client.listResources();
    assert.ok(all.resources.every((r) => !r.uri.includes("/.")));
    await assert.rejects(client.readResource({ uri: `${PREFIX}/.secret` }));
  } finally {
    await close();
    await rm(dir, { recursive: true, force: true });
  }
});

test("a SKILL.md with Windows line endings or a byte order mark still loads", async () => {
  for (const body of [GOOD.replace(/\n/g, "\r\n"), "﻿" + GOOD]) {
    const dir = await tempSkill({ "SKILL.md": body });
    try {
      const { client, close } = await connect(dir);
      try {
        const list = await client.request({ method: "skills/list", params: {} }, z.object({ skills: z.array(z.object({ frontmatter: z.object({ name: z.string() }).passthrough() })) }));
        assert.equal(list.skills[0].frontmatter.name, "save-point");
      } finally {
        await close();
      }
    } finally {
      await rm(dir, { recursive: true, force: true });
    }
  }
});
