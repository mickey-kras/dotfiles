#!/usr/bin/env node

import { loadPack, resolveState, stateFromFlatData } from "./pack-resolver.mjs";

function parseArgs(argv) {
  const parsed = {};

  for (let index = 2; index < argv.length; index += 2) {
    const key = argv[index];
    const value = argv[index + 1];

    if (!key?.startsWith("--")) {
      throw new Error(`Unexpected argument: ${key || ""}`);
    }

    parsed[key.slice(2)] = value;
  }

  return parsed;
}

const args = parseArgs(process.argv);
const repoRoot = args["repo-root"];
const packId = args["pack-id"] || "software-development";
const data = JSON.parse(args["data-json"] || "{}");

if (!repoRoot) {
  throw new Error("--repo-root is required");
}

const pack = loadPack(repoRoot, packId);
const state = stateFromFlatData(pack, data);
const resolved = resolveState(pack, state);

process.stdout.write(`${JSON.stringify(resolved, null, 2)}\n`);
