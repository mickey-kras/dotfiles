#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

import { getProfileSelection, loadPack } from "./pack-resolver.mjs";

function parseArgs(argv) {
  const parsed = { _: [] };

  for (let index = 2; index < argv.length; index += 1) {
    const token = argv[index];
    if (!token.startsWith("--")) {
      parsed._.push(token);
      continue;
    }

    const key = token.slice(2);
    const value = argv[index + 1];
    parsed[key] = value;
    index += 1;
  }

  return parsed;
}

function listPackIds(repoRoot) {
  return fs
    .readdirSync(path.join(repoRoot, "packs"), { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && fs.existsSync(path.join(repoRoot, "packs", entry.name, "pack.yaml")))
    .map((entry) => entry.name)
    .sort();
}

function printLines(values) {
  process.stdout.write(`${values.join("\n")}\n`);
}

const args = parseArgs(process.argv);
const repoRoot = args["repo-root"] || process.cwd();
const command = args._[0];

if (!command) {
  throw new Error("command is required");
}

if (command === "list-packs") {
  const lines = listPackIds(repoRoot).map((packId) => {
    const pack = loadPack(repoRoot, packId);
    return [pack.id, pack.label, pack.description].join("\t");
  });
  printLines(lines);
  process.exit(0);
}

const packId = args["pack-id"];
if (!packId) {
  throw new Error("--pack-id is required");
}

const pack = loadPack(repoRoot, packId);

if (command === "list-profiles") {
  const lines = Object.entries(pack.profiles || {}).map(([profileId, profile]) => {
    return [profileId, profile.label || profileId, profile.description || ""].join("\t");
  });
  printLines(lines);
  process.exit(0);
}

if (command === "list-catalog") {
  const section = args.section;
  const catalog = (pack.catalogs || {})[section] || {};
  const lines = Object.entries(catalog).map(([id, entry]) => {
    return [id, entry.label || id, entry.description || ""].join("\t");
  });
  printLines(lines);
  process.exit(0);
}

if (command === "profile-items") {
  const profileId = args.profile || pack.defaults?.profile;
  const section = args.section;
  const selection = getProfileSelection(pack, profileId);
  printLines(selection?.[section]?.enabled || []);
  process.exit(0);
}

if (command === "setting-default") {
  const profileId = args.profile || pack.defaults?.profile;
  const settingId = args.setting;
  const selection = getProfileSelection(pack, profileId);
  const value = selection?.settings?.[settingId] ?? pack.defaults?.selection?.settings?.[settingId] ?? pack.settings_schema?.[settingId]?.default ?? "";
  process.stdout.write(`${value}\n`);
  process.exit(0);
}

if (command === "list-settings") {
  const lines = Object.entries(pack.settings_schema || {}).map(([id, schema]) => {
    const visibleIf = schema.visible_if ? Object.entries(schema.visible_if).map(([key, value]) => `${key}=${value}`).join(",") : "";
    const options = (schema.options || []).map((option) => option.value).join(",");
    return [id, schema.type || "string", schema.label || id, schema.default ?? "", visibleIf, options].join("\t");
  });
  printLines(lines);
  process.exit(0);
}

throw new Error(`Unknown command: ${command}`);
