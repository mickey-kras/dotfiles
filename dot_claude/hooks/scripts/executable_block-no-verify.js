#!/usr/bin/env node
// Blocks git commands that use --no-verify.
// Hook: PreToolUse (Bash) - exit 2 to block, exit 0 to allow.

'use strict';

const chunks = [];
process.stdin.on('data', (c) => chunks.push(c));
process.stdin.on('end', () => {
  try {
    const input = JSON.parse(Buffer.concat(chunks).toString());
    const cmd = input.tool_input?.command || '';

    if (/--no-verify/.test(cmd)) {
      process.stderr.write(
        'Blocked: --no-verify is not allowed. Fix the pre-commit issue instead of bypassing it.'
      );
      process.exit(2);
    }
  } catch {
    // Parse error - allow the command to proceed.
  }
  process.exit(0);
});
