#!/usr/bin/env node
// Auto-formats JS/TS/JSON/CSS files after Edit or Write.
// Hook: PostToolUse (Edit|Write) — always exits 0 (non-blocking).

'use strict';

const { spawnSync } = require('child_process');
const path = require('path');

const FORMATTABLE = new Set(['.js', '.ts', '.jsx', '.tsx', '.json', '.css', '.scss']);

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
    if (!FORMATTABLE.has(ext)) {
      process.exit(0);
    }

    // Try biome first, fall back to prettier
    const biome = spawnSync('npx', ['biome', 'format', '--write', filePath], {
      timeout: 15000,
      stdio: ['ignore', 'ignore', 'ignore'],
    });

    if (biome.status !== 0) {
      spawnSync('npx', ['prettier', '--write', filePath], {
        timeout: 15000,
        stdio: ['ignore', 'ignore', 'ignore'],
      });
    }
  } catch {
    // Never block on formatter errors
  }
  process.exit(0);
});
