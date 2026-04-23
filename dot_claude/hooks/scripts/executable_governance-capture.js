#!/usr/bin/env node
// Managed shell governance hook.
// Hook: PreToolUse (Bash) - blocks secrets everywhere and stops obviously destructive commands.

'use strict';

const SECRET_PATTERNS = [
  /AKIA[0-9A-Z]{16}/,
  /AWS[_A-Z]*KEY/,
  /ghp_[A-Za-z0-9]{20,}/,
  /github_pat_[A-Za-z0-9_]{20,}/,
  /sk-[A-Za-z0-9]{20,}/,
  /-----BEGIN [A-Z ]*PRIVATE KEY-----/,
  /Authorization:\s*Bearer\s+[A-Za-z0-9._-]+/i,
];

const HARD_BLOCK_ALL = [
  /rm\s+-rf\s+\/($|\s)/,
  /\bdd\s+if=\/dev\/zero\b/,
  /\bmkfs(\.\w+)?\b/,
];

const HARD_BLOCK_PLATFORM = [
  /\bsudo\b/,
  /\bsu\b/,
  /\bgit\s+push\b.*\s--force(?:-with-lease)?\b/,
  /\bDROP\s+(?:TABLE|DATABASE)\b/i,
];

const WARN_PATTERNS = [
  { pattern: /\.env\b/, message: 'Warning: command references .env content.' },
  { pattern: /\bcredentials\b/i, message: 'Warning: command references credentials.' },
  { pattern: /\.pem\b/, message: 'Warning: command references a private key file.' },
  { pattern: /\bDROP\s+(?:TABLE|DATABASE)\b/i, message: 'Warning: destructive database command detected.' },
  { pattern: /\bgit\s+push\b.*\s--force(?:-with-lease)?\b/, message: 'Warning: force-push detected.' },
];

function fail(message) {
  process.stderr.write(message + '\n');
  process.exit(2);
}

function warn(message) {
  process.stderr.write(message + '\n');
}

const chunks = [];
process.stdin.on('data', (c) => chunks.push(c));
process.stdin.on('end', () => {
  try {
    const input = JSON.parse(Buffer.concat(chunks).toString());
    const cmd = input.tool_input?.command || '';

    if (!cmd) {
      process.exit(0);
    }

    for (const pattern of SECRET_PATTERNS) {
      if (pattern.test(cmd)) {
        fail('Blocked: command appears to contain a secret or API key. Never embed credentials directly in shell commands.');
      }
    }

    for (const pattern of HARD_BLOCK_ALL) {
      if (pattern.test(cmd)) {
        fail('Blocked: command matches a high-risk destructive pattern.');
      }
    }

    for (const pattern of HARD_BLOCK_PLATFORM) {
      if (pattern.test(cmd)) {
        fail('Blocked: command matches a managed high-risk pattern.');
      }
    }

    for (const rule of WARN_PATTERNS) {
      if (rule.pattern.test(cmd)) {
        warn(rule.message);
      }
    }
  } catch {
    // Parse error - allow the command to proceed.
  }

  process.exit(0);
});
