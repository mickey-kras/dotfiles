#!/usr/bin/env node
// Runs lightweight linting on edited files.
// Hook: PostToolUse (Edit|Write) — always exits 0 (advisory only).

'use strict';

const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const JS_EXTS = new Set(['.js', '.ts', '.jsx', '.tsx']);

const chunks = [];
process.stdin.on('data', (c) => chunks.push(c));
process.stdin.on('end', () => {
  try {
    const input = JSON.parse(Buffer.concat(chunks).toString());
    const filePath = input.tool_input?.file_path || input.tool_input?.path || '';

    if (!filePath) {
      process.exit(0);
    }

    const ext = path.extname(filePath).toLowerCase();

    if (JS_EXTS.has(ext)) {
      // Try biome first, fall back to eslint
      const biome = spawnSync('npx', ['biome', 'check', filePath], {
        timeout: 10000,
        encoding: 'utf8',
        stdio: ['ignore', 'pipe', 'pipe'],
      });

      if (biome.status !== 0 && biome.status !== null) {
        const eslint = spawnSync('npx', ['eslint', filePath], {
          timeout: 10000,
          encoding: 'utf8',
          stdio: ['ignore', 'pipe', 'pipe'],
        });

        if (eslint.status !== 0 && eslint.stdout) {
          process.stderr.write(`\nLint issues in ${filePath}:\n${eslint.stdout}\n`);
        } else if (biome.stdout) {
          process.stderr.write(`\nLint issues in ${filePath}:\n${biome.stdout}\n`);
        }
      }
    } else if (ext === '.json') {
      // Validate JSON
      try {
        JSON.parse(fs.readFileSync(filePath, 'utf8'));
      } catch (e) {
        process.stderr.write(`\nInvalid JSON in ${filePath}: ${e.message}\n`);
      }
    }
    // .md and other extensions — skip
  } catch {
    // Advisory only — never fail
  }
  process.exit(0);
});
