import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { execFileSync, spawnSync } from "node:child_process";

const repoRoot = path.resolve(import.meta.dirname, "..");
const hasChezmoi = spawnSync("which", ["chezmoi"], { encoding: "utf8" }).status === 0;

function withStubbedPath() {
  const binDir = fs.mkdtempSync(path.join(os.tmpdir(), "dotfiles-bin-"));
  for (const name of ["bw", "docker", "firebase", "uvx"]) {
    const target = path.join(binDir, name);
    fs.writeFileSync(target, "#!/bin/sh\nexit 0\n", "utf8");
    fs.chmodSync(target, 0o755);
  }
  return binDir;
}

function renderTemplate(templatePath, fixtureName) {
  const stubPath = withStubbedPath();
  const overrideDataPath = path.join(repoRoot, "tests", "fixtures", fixtureName);
  return execFileSync(
    "chezmoi",
    [
      "execute-template",
      "--source",
      repoRoot,
      "--override-data-file",
      overrideDataPath,
      "--file",
      templatePath
    ],
    {
      cwd: repoRoot,
      encoding: "utf8",
      env: {
        ...process.env,
        PATH: `${stubPath}:${process.env.PATH || ""}`
      }
    }
  );
}

const renderTest = hasChezmoi ? test : test.skip;

renderTest("software-development full renders the managed host surfaces", () => {
  const codex = renderTemplate(path.join(repoRoot, "dot_codex", "config.toml.tmpl"), "software-development-full.json");
  const cursor = renderTemplate(path.join(repoRoot, "dot_cursor", "mcp.json.tmpl"), "software-development-full.json");
  const claude = JSON.parse(renderTemplate(path.join(repoRoot, "dot_claude", "settings.json.tmpl"), "software-development-full.json"));
  const gemini = JSON.parse(renderTemplate(path.join(repoRoot, "dot_gemini", "settings.json.tmpl"), "software-development-full.json"));
  const factory = JSON.parse(renderTemplate(path.join(repoRoot, "dot_factory", "mcp.json.tmpl"), "software-development-full.json"));

  assert.match(codex, /\[mcp_servers\.stitch\]/);
  assert.match(codex, /\[mcp_servers\.obsidian\]/);
  assert.match(codex, /@bitbonsai\/mcpvault@latest/);

  const cursorJson = JSON.parse(cursor);
  assert.ok(cursorJson.mcpServers["MCP_DOCKER"]);
  assert.ok(cursorJson.mcpServers["github"]);
  assert.ok(cursorJson.mcpServers["stitch"]);
  assert.equal(claude.env.DOTFILES_RUNTIME_PROFILE, undefined);
  assert.ok(claude.permissions.allow.includes("Bash(git *)"));

  assert.ok(gemini.mcpServers.obsidian);
  assert.ok(gemini.mcpServers.stitch);
  assert.ok(factory.mcpServers.obsidian);
  assert.ok(factory.mcpServers.stitch);
});

renderTest("builtin memory keeps the rest of the toolchain but disables mcpvault", () => {
  const codex = renderTemplate(path.join(repoRoot, "dot_codex", "config.toml.tmpl"), "software-development-full-builtin-memory.json");
  const cursor = JSON.parse(renderTemplate(path.join(repoRoot, "dot_cursor", "mcp.json.tmpl"), "software-development-full-builtin-memory.json"));
  const claude = JSON.parse(renderTemplate(path.join(repoRoot, "dot_claude", "settings.json.tmpl"), "software-development-full-builtin-memory.json"));

  assert.match(codex, /@modelcontextprotocol\/server-memory@2026\.1\.26/);
  assert.doesNotMatch(codex, /@bitbonsai\/mcpvault@latest/);
  assert.ok(cursor.mcpServers.memory);
  assert.equal(claude.env.DOTFILES_RUNTIME_PROFILE, undefined);
});

renderTest("Claude settings omit SessionStart hooks", () => {
  const claude = JSON.parse(renderTemplate(path.join(repoRoot, "dot_claude", "settings.json.tmpl"), "software-development-full.json"));
  assert.equal(claude.SessionStart, undefined, "SessionStart hooks are not managed by dotfiles");
});
