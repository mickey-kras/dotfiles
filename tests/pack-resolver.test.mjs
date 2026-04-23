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
  assert.equal(pack.defaults.profile, "full");
  assert.ok(pack.profiles.full);
  assert.ok(pack.catalogs.mcps.github);
});

test("normalizes hidden settings back to defaults", () => {
  const settings = normalizeSettings(pack, {
    memory_provider: "builtin",
    obsidian_vault_path: "/tmp/vault",
    install_cursor: "enabled"
  });

  assert.deepEqual(settings, {
    memory_provider: "builtin",
    obsidian_vault_path: "",
    install_claude_code: "disabled",
    install_codex: "disabled",
    install_cursor: "enabled",
    install_gemini_cli: "disabled",
    install_droid: "disabled",
    stitch_api_key: "",
    bw_gate_install: "enabled"
  });
});

test("matches the full profile after normalization", () => {
  const full = getProfileSelection(pack, "full");
  full.mcps.enabled = [...full.mcps.enabled].reverse();
  assert.equal(matchProfile(pack, full), "full");
});

test("marks edited settings as custom", () => {
  const full = getProfileSelection(pack, "full");
  full.settings = {
    ...full.settings,
    memory_provider: "builtin",
    obsidian_vault_path: ""
  };

  const resolved = resolveState(pack, {
    pack_id: pack.id,
    profile: {
      selected: "full",
      mode: "preset"
    },
    selection: full
  });

  assert.equal(resolved.profile.mode, "custom");
  assert.equal(resolved.resolved.profile, "custom");
  assert.equal(resolved.resolved.profile_basis, "full");
});

test("derives custom install settings from legacy fields", () => {
  const derived = legacyDataToSelection(pack, {
    runtime_profile: "custom",
    profile_base: "full",
    install_claude_code: "enabled",
    install_cursor: "enabled",
    install_droid: "enabled",
    memory_provider: "obsidian",
    obsidian_vault_path: "/vault",
    stitch_api_key: "test-key"
  });

  assert.equal(derived.profile.selected, "full");
  assert.equal(derived.profile.mode, "custom");
  assert.equal(derived.selection.settings.install_claude_code, "enabled");
  assert.equal(derived.selection.settings.install_cursor, "enabled");
  assert.equal(derived.selection.settings.install_droid, "enabled");
  assert.equal(derived.selection.settings.obsidian_vault_path, "/vault");
  assert.equal(derived.selection.settings.stitch_api_key, "test-key");
});

test("preserves preset parity for the legacy full profile", () => {
  const resolved = resolveLegacyState(pack, {
    runtime_profile: "full",
    memory_provider: "obsidian",
    obsidian_vault_path: "/vault",
    stitch_api_key: "test-key"
  });

  assert.equal(resolved.profile.selected, "full");
  assert.equal(resolved.resolved.profile, "custom");
  assert.equal(resolved.resolved.settings.obsidian_vault_path, "/vault");
  assert.ok(resolved.resolved.permissions.allow.includes("Bash(git *)"));
});

test("flags missing required settings for enabled tools", () => {
  const selection = normalizeSelection(pack, {
    mcps: {
      enabled: ["stitch", "obsidian"]
    },
    settings: {
      memory_provider: "obsidian",
      obsidian_vault_path: ""
    }
  });
  const validation = validateSelection(pack, selection);

  assert.deepEqual(validation.errors, []);
  assert.ok(validation.warnings.includes("MCP stitch requires setting stitch_api_key"));
  assert.ok(validation.warnings.includes("MCP obsidian requires setting obsidian_vault_path"));
});

test("prefers explicit selection state over legacy flat fields", () => {
  const state = stateFromFlatData(pack, {
    capability_pack: "software-development",
    runtime_profile: "full",
    profile_selected: "full",
    profile_mode: "preset",
    selection_enabled_mcps: ["git", "filesystem"],
    selection_enabled_skills: ["writing-plans"],
    selection_enabled_agents: ["planner"],
    selection_enabled_rules: ["testing"],
    selection_enabled_permissions: ["core_read_write"],
    memory_provider: "builtin",
    obsidian_vault_path: "/ignored",
    install_cursor: "enabled",
    install_droid: "enabled"
  });

  assert.equal(state.profile.selected, "full");
  assert.deepEqual(state.selection.mcps.enabled, ["git", "filesystem"]);
  assert.equal(state.selection.settings.obsidian_vault_path, "/ignored");
  assert.equal(state.selection.settings.install_cursor, "enabled");
  assert.equal(state.selection.settings.install_droid, "enabled");
});
