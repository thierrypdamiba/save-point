import { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";

import { registerSkillCatalog } from "./skill-catalog.js";

export async function createCatalogServer(skillRoot: string): Promise<McpServer> {
  const server = new McpServer(
    { name: "save-point-skills", version: "0.10.0" },
    {
      capabilities: { extensions: { "io.modelcontextprotocol/skills": { directoryRead: true } } },
      cacheHints: {
        "server/discover": { ttlMs: 60_000, cacheScope: "private" },
        "tools/list": { ttlMs: 60_000, cacheScope: "private" },
        "prompts/list": { ttlMs: 60_000, cacheScope: "private" },
        "resources/list": { ttlMs: 60_000, cacheScope: "private" },
        "resources/read": { ttlMs: 60_000, cacheScope: "private" },
      },
      instructions:
        "This server distributes the Save Point Agent Skill. Hosts with native Agent Skills support should activate save-point directly. Other hosts should call list_skills, then load_skill before running a learning or recall session on a codebase or a written document. Runtime state stays in user-readable Markdown under ~/.save-point; MCP tools do not store user data.",
    },
  );
  const skill = await registerSkillCatalog(server, skillRoot);
  const readOnly = { readOnlyHint: true, destructiveHint: false, openWorldHint: false } as const;

  server.registerTool(
    "list_skills",
    {
      title: "List distributed skills",
      description: "Discover Agent Skills distributed by this server. Call before load_skill when the host does not natively support skills/list.",
      inputSchema: z.object({}),
      outputSchema: z.object({
        skills: z.array(z.object({ name: z.string(), description: z.string(), uri: z.string() })),
      }),
      annotations: readOnly,
    },
    async () => ({
      structuredContent: {
        skills: [
          {
            name: skill.frontmatter.name,
            description: skill.frontmatter.description,
            uri: skill.uri,
          },
        ],
      },
      content: [{ type: "text", text: `${skill.frontmatter.name}: ${skill.frontmatter.description}` }],
    }),
  );

  server.registerTool(
    "load_skill",
    {
      title: "Load an Agent Skill",
      description: "Load the complete Save Point instructions when a user wants to learn, quiz, or test themselves on a codebase or a written document.",
      inputSchema: z.object({ name: z.literal("save-point") }),
      outputSchema: z.object({
        name: z.literal("save-point"),
        instructions: z.string(),
        resourceUris: z.array(z.string()),
      }),
      annotations: readOnly,
    },
    async () => ({
      structuredContent: {
        name: "save-point" as const,
        instructions: skill.content,
        resourceUris: skill.resources.map((resource) => resource.uri),
      },
      content: [{ type: "text", text: skill.content }],
    }),
  );

  server.registerPrompt(
    "save-point",
    {
      title: "Start Save Point",
      description: "Teach or test understanding of a codebase or a written document with the Save Point skill.",
      argsSchema: z.object({ request: z.string().optional() }),
    },
    async ({ request }) => ({
      messages: [
        {
          role: "user",
          content: {
            type: "text",
            text: `${skill.content}\n\nUser request: ${request || "Start Save Point in the current repository."}`,
          },
        },
      ],
    }),
  );
  return server;
}
