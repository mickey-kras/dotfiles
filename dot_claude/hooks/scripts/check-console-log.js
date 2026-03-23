#!/usr/bin/env node
// Scans git-modified JS/TS files for console.log statements.
// Hook: Stop — always exits 0 (advisory only).

'use strict';

const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const JS_EXTS = new Set(['.js', '.ts', '.jsx', '.tsx']);

// Consume stdin (required by hook protocol)
const chunks = [];
process.stdin.on('data', (c) => chunks.push(c));
process.stdin.on('end', () => {
  try {
    // Get modified files from both staged and unstaged
    const cached = spawnSync('git', ['diff', '--cached', '--name-only'], {
      timeout: 5000,
      encoding: 'utf8',
    });
    const unstaged = spawnSync('git', ['diff', '--name-only'], {
      timeout: 5000,
      encoding: 'utf8',
    });

    const files = new Set();
    const addFiles = (output) => {
      if (output && output.stdout) {
        output.stdout.split('\n').filter(Boolean).forEach((f) => files.add(f));
      }
    };
    addFiles(cached);
    addFiles(unstaged);

    const warnings = [];

    for (const file of files) {
      const ext = path.extname(file).toLowerCase();
      if (!JS_EXTS.has(ext)) continue;
      if (file.includes('node_modules/')) continue;
      if (/\.(test|spec)\./.test(file)) continue;

      let content;
      try {
        content = fs.readFileSync(file, 'utf8');
      } catch {
        continue; // File may have been deleted
      }

      const lines = content.split('\n');
      for (let i = 0; i < lines.length; i++) {
        if (lines[i].includes('console.log(')) {
          warnings.push(`  ${file}:${i + 1}`);
        }
      }
    }

    if (warnings.length > 0) {
      process.stderr.write(
        `\nWarning: console.log() found in modified files:\n${warnings.join('\n')}\n`
      );
    }
  } catch {
    // Advisory only — never fail
  }
  process.exit(0);
});
