import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";

const projectRoot = resolve(import.meta.dirname, "..");

function start(skillDir: string) {
  return spawnSync(process.execPath, ["--import", "tsx", resolve(projectRoot, "src/index.ts")], {
    cwd: projectRoot,
    env: { ...process.env, SAVE_POINT_SKILL_DIR: skillDir },
    input: "",
    encoding: "utf8",
    timeout: 20_000,
  });
}

test("a missing skill folder stops the server at start with a plain message", () => {
  const result = start(join(tmpdir(), "save-point-no-such-folder"));
  assert.equal(result.status, 1);
  assert.match(result.stderr, /no SKILL\.md in .*save-point-no-such-folder/);
  assert.match(result.stderr, /SAVE_POINT_SKILL_DIR/);
});

test("a folder without SKILL.md stops the server at start", () => {
  const result = start(mkdtempSync(join(tmpdir(), "save-point-empty-")));
  assert.equal(result.status, 1);
  assert.match(result.stderr, /no SKILL\.md in/);
});

test("a good skill folder starts and exits cleanly when input closes", () => {
  const result = start(resolve(projectRoot, "../save-point"));
  assert.equal(result.status, 0);
  assert.equal(result.stderr, "");
});
