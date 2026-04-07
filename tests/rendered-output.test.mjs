import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { execFileSync } from "node:child_process";

const repoRoot = path.resolve(import.meta.dirname, "..");

function withStubbedPath() {
  const binDir = fs.mkdtempSync(path.join(os.tmpdir(), "dotfiles-bin-"));
  for (const name of ["bw", "docker", "uvx"]) {
    const target = path.join(binDir, name);
    fs.writeFileSync(target, "#!/bin/sh\nexit 0\n", "utf8");
    fs.chmodSync(target, 0o755);
  }
  return binDir;
}

function renderTemplate(templatePath, fixtureName) {
  const stubPath = withStubbedPath();
  const overrideDataPath = path.join(repoRoot, "tests", "fixtures", fixtureName);
  const rendered = execFileSync(
    "chezmoi",
    ["execute-template", "--source", repoRoot, "--override-data-file", overrideDataPath, "--file", templatePath],
    {
      cwd: repoRoot,
      encoding: "utf8",
      env: {
        ...process.env,
        PATH: `${stubPath}:${process.env.PATH || ""}`
      }
    }
  );
  return rendered;
}

test("software-development balanced renders expected host surfaces", () => {
  const codex = renderTemplate(path.join(repoRoot, "dot_codex", "config.toml.tmpl"), "software-development-balanced.json");
  const cursor = renderTemplate(path.join(repoRoot, "dot_cursor", "mcp.json.tmpl"), "software-development-balanced.json");
  const claude = JSON.parse(renderTemplate(path.join(repoRoot, "dot_claude", "settings.json.tmpl"), "software-development-balanced.json"));

  assert.match(codex, /\[mcp_servers\.shell\]/);
  assert.match(codex, /\[mcp_servers\.azure-devops\]/);
  assert.doesNotMatch(codex, /\[mcp_servers\.http\]/);

  const cursorJson = JSON.parse(cursor);
  assert.ok(cursorJson.mcpServers["MCP_DOCKER"]);
  assert.ok(cursorJson.mcpServers["github"]);
  assert.equal(claude.env.DOTFILES_RUNTIME_PROFILE, "balanced");
  assert.ok(claude.permissions.allow.includes("Bash(git *)"));
});

test("content-creation campaign renders pack-specific outputs", () => {
  const codex = renderTemplate(path.join(repoRoot, "dot_codex", "config.toml.tmpl"), "content-creation-campaign.json");
  const cursor = renderTemplate(path.join(repoRoot, "dot_cursor", "mcp.json.tmpl"), "content-creation-campaign.json");
  const claude = JSON.parse(renderTemplate(path.join(repoRoot, "dot_claude", "settings.json.tmpl"), "content-creation-campaign.json"));
  const packAssets = renderTemplate(path.join(repoRoot, "scripts", "chezmoi", "run_onchange_after_install-claude-pack-assets.sh.tmpl"), "content-creation-campaign.json");

  assert.match(codex, /\[mcp_servers\.firecrawl\]/);
  assert.match(codex, /\[mcp_servers\.fal-ai\]/);
  assert.match(codex, /@bitbonsai\/mcpvault@latest/);

  const cursorJson = JSON.parse(cursor);
  assert.ok(cursorJson.mcpServers["http"]);
  assert.ok(cursorJson.mcpServers["exa"]);
  assert.ok(cursorJson.mcpServers["firecrawl"]);
  assert.equal(claude.env.DOTFILES_RUNTIME_PROFILE, "campaign");
  assert.ok(claude.permissions.allow.includes("WebSearch"));
  assert.match(packAssets, /content-strategist/);
  assert.match(packAssets, /editorial-workflow/);
});
