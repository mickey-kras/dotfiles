import fs from "node:fs";
import path from "node:path";

import YAML from "yaml";

const DEFAULT_PACK_ID = "software-development";

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

function sortUnique(values = []) {
  return [...new Set((values || []).filter(Boolean))].sort();
}

function loadYaml(filePath) {
  return YAML.parse(fs.readFileSync(filePath, "utf8"));
}

function loadPackFile(repoRoot, packId = DEFAULT_PACK_ID) {
  return path.join(repoRoot, "packs", packId, "pack.yaml");
}

export function loadPack(repoRoot, packId = DEFAULT_PACK_ID) {
  const packPath = loadPackFile(repoRoot, packId);
  const pack = loadYaml(packPath);
  pack.path = packPath;
  return pack;
}

export function stateFromFlatData(pack, flatData = {}) {
  const selectedProfile = flatData.profile_selected;
  const selectedMode = flatData.profile_mode;

  if (selectedProfile) {
    return {
      pack_id: flatData.pack_id || flatData.capability_pack || pack.id,
      profile: {
        selected: selectedProfile,
        mode: selectedMode || "preset"
      },
      selection: {
        mcps: {
          enabled: flatData.selection_enabled_mcps || []
        },
        skills: {
          enabled: flatData.selection_enabled_skills || []
        },
        agents: {
          enabled: flatData.selection_enabled_agents || []
        },
        rules: {
          enabled: flatData.selection_enabled_rules || []
        },
        permissions: {
          enabled: flatData.selection_enabled_permissions || []
        },
        settings: {
          memory_provider: flatData.memory_provider,
          obsidian_vault_path: flatData.obsidian_vault_path,
          azure_devops_org: flatData.azure_devops_org,
          content_workspace: flatData.content_workspace
        }
      }
    };
  }

  return legacyDataToSelection(pack, flatData);
}

export function defaultSettings(pack) {
  const defaults = {};
  for (const [settingId, schema] of Object.entries(pack.settings_schema || {})) {
    defaults[settingId] = schema.default ?? "";
  }
  return defaults;
}

function isSettingVisible(pack, settingId, settings) {
  const schema = (pack.settings_schema || {})[settingId];
  if (!schema || !schema.visible_if) {
    return true;
  }

  return Object.entries(schema.visible_if).every(([dependencyKey, dependencyValue]) => {
    return settings[dependencyKey] === dependencyValue;
  });
}

export function normalizeSettings(pack, rawSettings = {}) {
  const defaults = defaultSettings(pack);
  const merged = { ...defaults, ...(rawSettings || {}) };

  for (const settingId of Object.keys(defaults)) {
    if (!isSettingVisible(pack, settingId, merged)) {
      merged[settingId] = defaults[settingId];
    }
  }

  return merged;
}

export function getProfileSelection(pack, profileId) {
  const profile = (pack.profiles || {})[profileId];
  if (!profile) {
    throw new Error(`Unknown profile: ${profileId}`);
  }

  return clone(profile.selection || {});
}

function normalizeEnabledSection(selection, sectionId) {
  const enabled = selection?.[sectionId]?.enabled || [];
  return { enabled: sortUnique(enabled) };
}

export function normalizeSelection(pack, rawSelection = {}) {
  const selection = {
    mcps: normalizeEnabledSection(rawSelection, "mcps"),
    skills: normalizeEnabledSection(rawSelection, "skills"),
    agents: normalizeEnabledSection(rawSelection, "agents"),
    rules: normalizeEnabledSection(rawSelection, "rules"),
    permissions: normalizeEnabledSection(rawSelection, "permissions"),
    settings: normalizeSettings(pack, rawSelection.settings || {})
  };

  return selection;
}

function stableStringify(value) {
  return JSON.stringify(value);
}

export function matchProfile(pack, rawSelection) {
  const candidate = normalizeSelection(pack, rawSelection);

  for (const profileId of Object.keys(pack.profiles || {})) {
    const profileSelection = normalizeSelection(pack, getProfileSelection(pack, profileId));
    if (stableStringify(candidate) === stableStringify(profileSelection)) {
      return profileId;
    }
  }

  return null;
}

export function validateSelection(pack, rawSelection) {
  const selection = normalizeSelection(pack, rawSelection);
  const errors = [];
  const warnings = [];

  for (const [sectionId, catalog] of Object.entries(pack.catalogs || {})) {
    if (sectionId === "permissions") {
      continue;
    }

    const enabledIds = selection[sectionId]?.enabled || [];
    for (const id of enabledIds) {
      if (!(catalog || {})[id]) {
        errors.push(`Unknown ${sectionId} id: ${id}`);
      }
    }
  }

  for (const permissionId of selection.permissions.enabled) {
    if (!((pack.catalogs || {}).permissions || {})[permissionId]) {
      errors.push(`Unknown permissions id: ${permissionId}`);
    }
  }

  for (const [settingId] of Object.entries(pack.settings_schema || {})) {
    if (!(settingId in selection.settings)) {
      errors.push(`Missing setting value: ${settingId}`);
    }
  }

  for (const [sectionId, catalog] of Object.entries((pack.catalogs || {}).mcps || {})) {
    if (!selection.mcps.enabled.includes(sectionId)) {
      continue;
    }

    for (const requiredSettingId of catalog.requires?.settings || []) {
      if (!selection.settings[requiredSettingId]) {
        warnings.push(`MCP ${sectionId} requires setting ${requiredSettingId}`);
      }
    }
  }

  return { errors, warnings, selection };
}

function removeValues(values, valuesToRemove = []) {
  const removals = new Set(valuesToRemove || []);
  return values.filter((value) => !removals.has(value));
}

export function legacyDataToSelection(pack, legacyData = {}) {
  const defaultProfile = pack.defaults?.profile || "balanced";
  const runtimeProfile = legacyData.runtime_profile || defaultProfile;
  const baseProfile = legacyData.profile_base || pack.defaults?.profile || "balanced";
  const profileId = runtimeProfile === "custom" ? baseProfile : runtimeProfile;

  const selection = getProfileSelection(pack, profileId);

  if (runtimeProfile === "custom") {
    selection.mcps.enabled = sortUnique(removeValues([
      ...(selection.mcps?.enabled || []),
      ...(legacyData.custom_enabled_mcps || [])
    ], legacyData.custom_disabled_mcps || []));

    selection.permissions.enabled = sortUnique(removeValues([
      ...(selection.permissions?.enabled || []),
      ...(legacyData.custom_enabled_permission_groups || [])
    ], legacyData.custom_disabled_permission_groups || []));
  }

  selection.settings = {
    ...(selection.settings || {}),
    memory_provider: legacyData.memory_provider || selection.settings?.memory_provider,
    obsidian_vault_path: legacyData.obsidian_vault_path || selection.settings?.obsidian_vault_path,
    azure_devops_org: legacyData.azure_devops_org || selection.settings?.azure_devops_org
  };

  return {
    pack_id: pack.id,
    profile: {
      selected: profileId,
      mode: runtimeProfile === "custom" ? "custom" : "preset"
    },
    selection
  };
}

function allowEntriesForPermissions(pack, permissionIds) {
  const permissionsCatalog = (pack.catalogs || {}).permissions || {};
  const allow = [];

  for (const permissionId of permissionIds) {
    const permission = permissionsCatalog[permissionId];
    if (!permission) {
      continue;
    }

    allow.push(...(permission.allow || []));
  }

  return sortUnique(allow);
}

function resolvedHardBans(pack, profileId) {
  const hardBans = pack.guardrails?.hard_bans || {};
  return sortUnique([...(hardBans.shared || []), ...(hardBans[profileId] || [])]);
}

export function resolveState(pack, inputState) {
  const requestedProfileId = inputState?.profile?.selected || pack.defaults?.profile || "balanced";
  const requestedMode = inputState?.profile?.mode || "preset";
  const normalizedSelection = normalizeSelection(pack, inputState?.selection || {});
  const matchedProfile = matchProfile(pack, normalizedSelection);
  const mode = matchedProfile ? "preset" : "custom";
  const selectedProfile = matchedProfile || requestedProfileId;
  const effectiveProfile = requestedMode === "custom" && !matchedProfile ? requestedProfileId : selectedProfile;
  const guardrailProfile = mode === "preset" ? selectedProfile : "custom";

  return {
    pack_id: pack.id,
    profile: {
      selected: selectedProfile,
      mode
    },
    pack: {
      id: pack.id,
      label: pack.label,
      description: pack.description,
      tooling: pack.tooling || {}
    },
    selection: normalizedSelection,
    resolved: {
      pack_id: pack.id,
      profile: mode === "preset" ? selectedProfile : "custom",
      profile_basis: effectiveProfile,
      mcps: normalizedSelection.mcps,
      skills: normalizedSelection.skills,
      agents: normalizedSelection.agents,
      rules: normalizedSelection.rules,
      permissions: {
        enabled: normalizedSelection.permissions.enabled,
        allow: allowEntriesForPermissions(pack, normalizedSelection.permissions.enabled),
        deny: resolvedHardBans(pack, guardrailProfile)
      },
      settings: normalizedSelection.settings
    }
  };
}

export function resolveLegacyState(pack, legacyData = {}) {
  const selectionState = legacyDataToSelection(pack, legacyData);
  return resolveState(pack, selectionState);
}
