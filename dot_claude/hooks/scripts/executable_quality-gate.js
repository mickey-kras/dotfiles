#!/usr/bin/env node
// Advisory quality checks after edits.
// Hook: PostToolUse (Edit|Write|MultiEdit) - never blocks.

'use strict';

const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const JS_EXTS = new Set(['.js', '.ts', '.jsx', '.tsx']);

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

function repoContext(filePath, cwdHint) {
  const start = path.dirname(filePath || cwdHint || process.cwd());
  const rootMarker = findUp(
    ['.git', 'package.json', 'pyproject.toml', 'biome.json', 'biome.jsonc', 'eslint.config.js', '.eslintrc', '.eslintrc.json'],
    start
  );
  const root = rootMarker ? path.dirname(rootMarker) : start;
  return { root };
}

function runCheck(command, args, cwd) {
  return spawnSync(command, args, {
    cwd,
    timeout: 8000,
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
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
    const { root } = repoContext(filePath, input.cwd);

    if (JS_EXTS.has(ext)) {
      const biomeConfig = findUp(['biome.json', 'biome.jsonc'], root);
      const eslintConfig = findUp(
        ['eslint.config.js', 'eslint.config.cjs', 'eslint.config.mjs', '.eslintrc', '.eslintrc.js', '.eslintrc.cjs', '.eslintrc.json'],
        root
      );
      const biomeBin = existing([path.join(root, 'node_modules', '.bin', 'biome')]);
      const eslintBin = existing([path.join(root, 'node_modules', '.bin', 'eslint')]);

      let result = null;
      if (biomeConfig && biomeBin) {
        result = runCheck(biomeBin, ['check', filePath], root);
      } else if (eslintConfig && eslintBin) {
        result = runCheck(eslintBin, [filePath], root);
      }

      if (result && result.status !== 0) {
        const output = [result.stdout, result.stderr].filter(Boolean).join('\n').trim();
        if (output) {
          process.stderr.write(`\nQuality gate issues in ${filePath}:\n${output}\n`);
        }
      }
    } else if (ext === '.json') {
      try {
        JSON.parse(fs.readFileSync(filePath, 'utf8'));
      } catch (error) {
        process.stderr.write(`\nInvalid JSON in ${filePath}: ${error.message}\n`);
      }
    }
  } catch {
    // Advisory only - never fail.
  }
  process.exit(0);
});
