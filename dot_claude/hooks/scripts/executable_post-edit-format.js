#!/usr/bin/env node
// Formats edited files when a known local formatter and config are present.
// Hook: PostToolUse (Edit|Write|MultiEdit) - never blocks.

'use strict';

const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const FORMATTABLE = new Set(['.js', '.ts', '.jsx', '.tsx', '.json', '.css', '.scss']);

function findUp(names, startDir) {
  let dir = path.resolve(startDir);
  while (true) {
    for (const name of names) {
      const candidate = path.join(dir, name);
      if (fs.existsSync(candidate)) return candidate;
    }
    const parent = path.dirname(dir);
    if (parent === dir) return null;
    dir = parent;
  }
}

function existing(paths) {
  for (const candidate of paths) {
    if (candidate && fs.existsSync(candidate)) return candidate;
  }
  return null;
}

function repoRoot(filePath, cwdHint) {
  const start = path.dirname(filePath || cwdHint || process.cwd());
  const marker = findUp(['.git', 'package.json', 'biome.json', 'biome.jsonc', 'prettier.config.js', '.prettierrc'], start);
  return marker ? path.dirname(marker) : start;
}

function runFormat(command, args, cwd) {
  return spawnSync(command, args, {
    cwd,
    timeout: 10000,
    stdio: ['ignore', 'ignore', 'ignore'],
  });
}

const chunks = [];
process.stdin.on('data', (c) => chunks.push(c));
process.stdin.on('end', () => {
  try {
    const input = JSON.parse(Buffer.concat(chunks).toString());
    const toolName = input.tool_name || '';
    if (!['Edit', 'Write', 'MultiEdit'].includes(toolName)) {
      process.exit(0);
    }

    const toolInput = input.tool_input || {};
    const filePath = toolInput.file_path || toolInput.path || '';
    if (!filePath) {
      process.exit(0);
    }

    const ext = path.extname(filePath).toLowerCase();
    if (!FORMATTABLE.has(ext)) {
      process.exit(0);
    }

    const root = repoRoot(filePath, input.cwd);
    const biomeConfig = findUp(['biome.json', 'biome.jsonc'], root);
    const prettierConfig = findUp(
      ['.prettierrc', '.prettierrc.json', '.prettierrc.js', '.prettierrc.cjs', 'prettier.config.js', 'prettier.config.cjs', 'prettier.config.mjs'],
      root
    );
    const biomeBin = existing([path.join(root, 'node_modules', '.bin', 'biome')]);
    const prettierBin = existing([path.join(root, 'node_modules', '.bin', 'prettier')]);

    if (biomeConfig && biomeBin) {
      runFormat(biomeBin, ['format', '--write', filePath], root);
      process.exit(0);
    }

    if (prettierConfig && prettierBin) {
      runFormat(prettierBin, ['--write', filePath], root);
    }
  } catch {
    // Formatter failures should never block work.
  }
  process.exit(0);
});
