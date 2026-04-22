#!/usr/bin/env node
// Blocks edits to linter and formatter config files.
// Hook: PreToolUse (Edit|Write) - exit 2 to block, exit 0 to allow.

'use strict';

const path = require('path');

const PROTECTED = [
  /\.eslintrc/,
  /eslint\.config\./,
  /\.prettierrc/,
  /prettier\.config\./,
  /biome\.jsonc?$/,
  /\.stylelintrc/,
  /\.markdownlint/,
  /ruff\.toml$/,
  /\.ruff\.toml$/,
  /\.shellcheckrc$/,
];

const chunks = [];
process.stdin.on('data', (c) => chunks.push(c));
process.stdin.on('end', () => {
  try {
    const input = JSON.parse(Buffer.concat(chunks).toString());
    const filePath = input.tool_input?.file_path || input.tool_input?.path || '';
    const basename = path.basename(filePath);

    if (PROTECTED.some((re) => re.test(basename))) {
      process.stderr.write(
        `Blocked: editing ${basename} is not allowed. Fix the code to satisfy the linter instead.`
      );
      process.exit(2);
    }
  } catch {
    // Parse error - allow.
  }
  process.exit(0);
});
