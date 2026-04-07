import test from "node:test";
import assert from "node:assert/strict";
import path from "node:path";

import {
  getProfileSelection,
  legacyDataToSelection,
  loadPack,
  matchProfile,
  normalizeSelection,
  normalizeSettings,
  resolveLegacyState,
  resolveState,
  stateFromFlatData,
  validateSelection
} from "../scripts/lib/pack-resolver.mjs";

const repoRoot = path.resolve(import.meta.dirname, "..");
const pack = loadPack(repoRoot, "software-development");

test("loads the software-development pack", () => {
  assert.equal(pack.id, "software-development");
  assert.equal(pack.defaults.profile, "balanced");
  assert.ok(pack.profiles.restricted);
  assert.ok(pack.catalogs.mcps.github);
});

test("normalizes hidden settings back to defaults", () => {
  const settings = normalizeSettings(pack, {
    memory_provider: "builtin",
    obsidian_vault_path: "/tmp/vault",
    azure_devops_org: "acme"
  });

  assert.deepEqual(settings, {
    memory_provider: "builtin",
    obsidian_vault_path: "",
    azure_devops_org: "acme"
  });
});

test("matches named profiles after normalization", () => {
  const balanced = getProfileSelection(pack, "balanced");
  balanced.mcps.enabled = [...balanced.mcps.enabled].reverse();
  assert.equal(matchProfile(pack, balanced), "balanced");
});

test("marks edited selections as custom", () => {
  const balanced = getProfileSelection(pack, "balanced");
  balanced.mcps.enabled = balanced.mcps.enabled.filter((id) => id !== "shell");

  const resolved = resolveState(pack, {
    pack_id: pack.id,
    profile: {
      selected: "balanced",
      mode: "preset"
    },
    selection: balanced
  });

  assert.equal(resolved.profile.mode, "custom");
  assert.equal(resolved.resolved.profile, "custom");
  assert.equal(resolved.resolved.profile_basis, "balanced");
});

test("derives a custom selection from legacy fields", () => {
  const derived = legacyDataToSelection(pack, {
    runtime_profile: "custom",
    profile_base: "restricted",
    custom_enabled_mcps: ["shell"],
    custom_enabled_permission_groups: ["git_full"],
    memory_provider: "obsidian",
    obsidian_vault_path: "/vault"
  });

  assert.equal(derived.profile.selected, "restricted");
  assert.equal(derived.profile.mode, "custom");
  assert.ok(derived.selection.mcps.enabled.includes("shell"));
  assert.ok(derived.selection.permissions.enabled.includes("git_full"));
  assert.equal(derived.selection.settings.memory_provider, "obsidian");
  assert.equal(derived.selection.settings.obsidian_vault_path, "/vault");
});

test("preserves preset parity for legacy balanced profile", () => {
  const resolved = resolveLegacyState(pack, {
    runtime_profile: "balanced",
    memory_provider: "builtin",
    obsidian_vault_path: "/ignored"
  });

  assert.equal(resolved.profile.selected, "balanced");
  assert.equal(resolved.profile.mode, "preset");
  assert.equal(resolved.resolved.profile, "balanced");
  assert.equal(resolved.resolved.settings.obsidian_vault_path, "");
  assert.ok(resolved.resolved.permissions.allow.includes("Bash(git *)"));
});

test("flags missing required settings for enabled tools", () => {
  const selection = normalizeSelection(pack, {
    mcps: {
      enabled: ["azure-devops"]
    },
    settings: {
      memory_provider: "builtin"
    }
  });
  const validation = validateSelection(pack, selection);

  assert.deepEqual(validation.errors, []);
  assert.ok(validation.warnings.includes("MCP azure-devops requires setting azure_devops_org"));
});

test("prefers explicit selection state over legacy flat fields", () => {
  const state = stateFromFlatData(pack, {
    capability_pack: "software-development",
    runtime_profile: "open",
    profile_selected: "balanced",
    profile_mode: "preset",
    selection_enabled_mcps: ["git", "filesystem"],
    selection_enabled_skills: ["writing-plans"],
    selection_enabled_agents: ["planner"],
    selection_enabled_rules: ["testing"],
    selection_enabled_permissions: ["core_read_write"],
    memory_provider: "builtin",
    obsidian_vault_path: "/ignored",
    azure_devops_org: "acme"
  });

  assert.equal(state.profile.selected, "balanced");
  assert.deepEqual(state.selection.mcps.enabled, ["git", "filesystem"]);
  assert.equal(state.selection.settings.obsidian_vault_path, "/ignored");
});

// --- Content-creation pack tests ---

const contentPack = loadPack(repoRoot, "content-creation");

test("loads the content-creation pack", () => {
  assert.equal(contentPack.id, "content-creation");
  assert.equal(contentPack.defaults.profile, "studio");
  assert.ok(contentPack.profiles.focused);
  assert.ok(contentPack.profiles.studio);
  assert.ok(contentPack.profiles.campaign);
  assert.ok(contentPack.catalogs.mcps.figma);
});

test("content-creation profiles match their names after normalization", () => {
  for (const profileId of Object.keys(contentPack.profiles)) {
    const selection = getProfileSelection(contentPack, profileId);
    assert.equal(matchProfile(contentPack, selection), profileId, `profile ${profileId} should match itself`);
  }
});

test("content-creation focused profile has no high-risk MCPs", () => {
  const focused = getProfileSelection(contentPack, "focused");
  const highRisk = ["http", "exa", "firecrawl", "fal-ai"];
  for (const mcp of highRisk) {
    assert.ok(!focused.mcps.enabled.includes(mcp), `focused should not include ${mcp}`);
  }
});

test("content-creation campaign has search and generation MCPs", () => {
  const campaign = getProfileSelection(contentPack, "campaign");
  assert.ok(campaign.mcps.enabled.includes("exa"));
  assert.ok(campaign.mcps.enabled.includes("firecrawl"));
  assert.ok(campaign.mcps.enabled.includes("fal-ai"));
});

test("content-creation resolves state with visible_if for obsidian", () => {
  const resolved = resolveState(contentPack, {
    pack_id: "content-creation",
    profile: { selected: "studio", mode: "preset" },
    selection: {
      ...getProfileSelection(contentPack, "studio"),
      settings: { memory_provider: "obsidian", obsidian_vault_path: "/vault", content_workspace: "" }
    }
  });

  assert.equal(resolved.resolved.settings.obsidian_vault_path, "/vault");
  assert.equal(resolved.profile.mode, "custom");
});

test("content-creation validates unknown MCP reference", () => {
  const result = validateSelection(contentPack, {
    mcps: { enabled: ["nonexistent-mcp"] },
    settings: { memory_provider: "builtin" }
  });
  assert.ok(result.errors.some((e) => e.includes("nonexistent-mcp")));
});

// --- Cross-pack tests ---

test("all packs have matching tooling agents and catalog agents", () => {
  for (const p of [pack, contentPack]) {
    const catalogAgents = Object.keys(p.catalogs.agents).sort();
    const toolingAgents = [...p.tooling.claude_agents].sort();
    assert.deepEqual(toolingAgents, catalogAgents, `${p.id} tooling agents should match catalog`);
  }
});

test("all packs have matching tooling skills and catalog skills", () => {
  for (const p of [pack, contentPack]) {
    const catalogSkills = Object.keys(p.catalogs.skills).sort();
    const toolingSkills = [...p.tooling.managed_skills].sort();
    assert.deepEqual(toolingSkills, catalogSkills, `${p.id} tooling skills should match catalog`);
  }
});

test("all profiles reference only valid catalog items", () => {
  for (const p of [pack, contentPack]) {
    for (const [profileId, profile] of Object.entries(p.profiles)) {
      const validation = validateSelection(p, profile.selection);
      assert.deepEqual(validation.errors, [], `${p.id}/${profileId} should have no validation errors`);
    }
  }
});
