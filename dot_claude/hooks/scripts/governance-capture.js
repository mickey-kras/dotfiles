#!/usr/bin/env node
// Detects potentially dangerous commands and secrets in Bash tool calls.
// Hook: PreToolUse (Bash) — exit 2 to block, exit 0 to allow.
// Active for standard and strict profiles only.

'use strict';

const profile = process.env.ECC_HOOK_PROFILE || '';

const chunks = [];
process.stdin.on('data', (c) => chunks.push(c));
process.stdin.on('end', () => {
  // Only active for standard and strict profiles
  if (profile !== 'standard' && profile !== 'strict') {
    process.exit(0);
  }

  try {
    const input = JSON.parse(Buffer.concat(chunks).toString());
    const cmd = input.tool_input?.command || '';

    if (!cmd) {
      process.exit(0);
    }

    // Check for secrets
    const secretPatterns = [
      /AWS[_A-Z]*KEY/,
      /AKIA[0-9A-Z]{16}/,
      /ghp_[a-zA-Z0-9]{36}/,
      /sk-[a-zA-Z0-9]{20,}/,
    ];

    for (const pattern of secretPatterns) {
      if (pattern.test(cmd)) {
        process.stderr.write(
          'Blocked: command appears to contain a secret or API key. Never embed credentials in commands.\n'
        );
        process.exit(2);
      }
    }

    // Check for destructive commands
    const destructivePatterns = [
      /git push.*--force/,
      /rm -rf \//,
      /DROP\s+(?:TABLE|DATABASE)/i,
      /sudo /,
    ];

    for (const pattern of destructivePatterns) {
      if (pattern.test(cmd)) {
        process.stderr.write(
          `Blocked: potentially destructive command detected. Review and run manually if intended.\n`
        );
        process.exit(2);
      }
    }

    // Check for sensitive file access (advisory only)
    const sensitivePatterns = [/\.env/, /credentials/, /\.pem$/];

    for (const pattern of sensitivePatterns) {
      if (pattern.test(cmd)) {
        process.stderr.write(
          `Warning: command accesses a potentially sensitive file. Proceed with caution.\n`
        );
        break;
      }
    }
  } catch {
    // Parse error — allow the command to proceed
  }
  process.exit(0);
});
