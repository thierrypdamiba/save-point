import { createHash } from "node:crypto";
import { readFile, readdir } from "node:fs/promises";
import { relative, resolve, sep } from "node:path";

import { z } from "zod";
import { INVALID_PARAMS, ProtocolError, type McpServer } from "@modelcontextprotocol/server";
import { parse as parseYaml } from "yaml";

const CATALOG_PREFIX = "skill://save-point-local/save-point";

const SkillResourceSchema = z.object({ uri: z.string(), digest: z.string() });
const SkillEntrySchema = z.object({
  uri: z.string(),
  frontmatter: z.record(z.string(), z.unknown()),
  resources: z.array(SkillResourceSchema),
});

interface SkillResource {
  uri: string;
  digest: string;
  path: string;
  content: string;
}

export interface PublishedSkill {
  uri: string;
  frontmatter: Record<string, unknown> & { name: string; description: string };
  resources: Array<{ uri: string; digest: string }>;
  content: string;
}

export async function registerSkillCatalog(server: McpServer, skillRoot: string): Promise<PublishedSkill> {
  const resolvedRoot = resolve(skillRoot);
  const filePaths = await listFiles(resolvedRoot);
  const resources: SkillResource[] = [];

  for (const path of filePaths) {
    const content = await readFile(path, "utf8");
    const relativePath = relative(resolvedRoot, path).split(sep).join("/");
    resources.push({
      uri: `${CATALOG_PREFIX}/${relativePath}`,
      digest: `sha256:${createHash("sha256").update(Buffer.from(content, "utf8")).digest("hex")}`,
      path,
      content,
    });
  }

  const skillDocument = resources.find((resource) => resource.uri === `${CATALOG_PREFIX}/SKILL.md`);
  if (!skillDocument) throw new Error("Save Point skill is missing SKILL.md");
  const skill: PublishedSkill = {
    uri: skillDocument.uri,
    frontmatter: parseFrontmatter(skillDocument.content),
    resources: resources.map(({ uri, digest }) => ({ uri, digest })),
    content: skillDocument.content,
  };
  const catalogSkill = {
    uri: skill.uri,
    frontmatter: skill.frontmatter,
    resources: skill.resources,
  };

  for (const resource of resources) {
    server.registerResource(
      `save-point-${relative(resolvedRoot, resource.path).split(sep).join("-")}`,
      resource.uri,
      {
        title: `Save Point: ${relative(resolvedRoot, resource.path)}`,
        mimeType: mimeType(resource.path),
        cacheHint: { ttlMs: 60_000, cacheScope: "private" },
      },
      async () => ({
        contents: [{ uri: resource.uri, mimeType: mimeType(resource.path), text: resource.content }],
      }),
    );
  }

  server.server.setRequestHandler(
    "skills/list",
    {
      params: z.object({ cursor: z.string().optional() }),
      result: z.object({
        skills: z.array(SkillEntrySchema),
        ttlMs: z.number().int().nonnegative(),
        cacheScope: z.enum(["public", "private"]),
      }),
    },
    async () => ({ skills: [catalogSkill], ttlMs: 60_000, cacheScope: "private" as const }),
  );
  server.server.setRequestHandler(
    "skills/get",
    { params: z.object({ uri: z.string() }), result: z.object({ skill: SkillEntrySchema }) },
    async ({ uri }) => {
      if (uri !== skill.uri) throw new ProtocolError(INVALID_PARAMS, `Unknown skill URI: ${uri}`);
      return { skill: catalogSkill };
    },
  );
  server.server.setRequestHandler(
    "resources/directory/read",
    {
      params: z.object({ uri: z.string(), cursor: z.string().optional() }),
      result: z.object({
        resources: z.array(
          z.object({ uri: z.string(), name: z.string(), mimeType: z.string(), description: z.string().optional() }),
        ),
      }),
    },
    async ({ uri }) => ({ resources: listDirectory(uri, resources) }),
  );
  return skill;
}

function listDirectory(uri: string, resources: SkillResource[]): Array<{
  uri: string;
  name: string;
  mimeType: string;
}> {
  const normalized = uri.replace(/\/$/, "");
  if (normalized !== CATALOG_PREFIX && !normalized.startsWith(`${CATALOG_PREFIX}/`)) {
    throw new ProtocolError(INVALID_PARAMS, `Unknown directory URI: ${uri}`);
  }
  const children = new Map<string, { uri: string; name: string; mimeType: string }>();
  const prefix = `${normalized}/`;
  for (const resource of resources) {
    if (!resource.uri.startsWith(prefix)) continue;
    const remainder = resource.uri.slice(prefix.length);
    const [name, ...rest] = remainder.split("/");
    if (!name) continue;
    children.set(name, {
      uri: `${normalized}/${name}`,
      name,
      mimeType: rest.length > 0 ? "inode/directory" : mimeType(resource.path),
    });
  }
  if (children.size === 0 && normalized !== CATALOG_PREFIX) {
    throw new ProtocolError(INVALID_PARAMS, `Unknown or non-directory URI: ${uri}`);
  }
  return [...children.values()].sort((a, b) => a.name.localeCompare(b.name));
}

async function listFiles(directory: string): Promise<string[]> {
  const entries = await readdir(directory, { withFileTypes: true });
  const paths: string[] = [];
  for (const entry of entries.sort((a, b) => a.name.localeCompare(b.name))) {
    if (entry.name.startsWith(".")) continue;
    const path = resolve(directory, entry.name);
    if (entry.isDirectory()) paths.push(...(await listFiles(path)));
    else if (entry.isFile()) paths.push(path);
  }
  return paths;
}

function parseFrontmatter(content: string): Record<string, unknown> & { name: string; description: string } {
  const match = content.match(/^---\n([\s\S]*?)\n---(?:\n|$)/);
  if (!match) throw new Error("SKILL.md is missing YAML frontmatter");
  const frontmatter = parseYaml(match[1]);
  if (!frontmatter || typeof frontmatter !== "object") throw new Error("SKILL.md frontmatter must be an object");
  const record = frontmatter as Record<string, unknown>;
  if (typeof record.name !== "string" || typeof record.description !== "string") {
    throw new Error("SKILL.md frontmatter needs string name and description");
  }
  return record as Record<string, unknown> & { name: string; description: string };
}

function mimeType(path: string): string {
  if (path.endsWith(".md")) return "text/markdown";
  if (path.endsWith(".yaml") || path.endsWith(".yml")) return "application/yaml";
  return "text/plain";
}
