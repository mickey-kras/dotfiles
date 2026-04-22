#!/usr/bin/env node
// Suggests /compact after a threshold of tool calls per session.
// Hook: PostToolUse - always exits 0.

'use strict';

const fs = require('fs');
const path = require('path');
const os = require('os');

const THRESHOLD = parseInt(process.env.ECC_COMPACT_THRESHOLD, 10) || 50;
const REMINDER_INTERVAL = 25;
const sessionId = process.env.CLAUDE_SESSION_ID || 'default';
const counterDir = path.join(os.tmpdir(), 'claude-hooks');
const counterFile = path.join(counterDir, `compact-${sessionId}.count`);

try {
  fs.mkdirSync(counterDir, { recursive: true });

  let count = 0;
  try {
    count = parseInt(fs.readFileSync(counterFile, 'utf8'), 10) || 0;
  } catch {}

  count += 1;
  fs.writeFileSync(counterFile, String(count));

  if (count === THRESHOLD) {
    process.stderr.write(
      `\nHint: ${count} tool calls in this session. Consider /compact to preserve context quality.\n`
    );
  } else if (count > THRESHOLD && (count - THRESHOLD) % REMINDER_INTERVAL === 0) {
    process.stderr.write(
      `\nHint: ${count} tool calls in this session. Running /compact would likely help.\n`
    );
  }
} catch {
  // Counter errors should never block work.
}

process.stdin.resume();
process.stdin.on('end', () => process.exit(0));
