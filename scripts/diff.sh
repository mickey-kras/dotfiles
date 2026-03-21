#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Detect a diff command that supports --color.
# Prefer gdiff (Homebrew GNU diffutils on macOS), then check if system diff
# is GNU (supports --color), otherwise fall back to plain diff.
if command -v gdiff >/dev/null 2>&1; then
  DIFF_CMD="gdiff"
  DIFF_COLOR=true
elif diff --version 2>/dev/null | grep -q "GNU diffutils"; then
  DIFF_CMD="diff"
  DIFF_COLOR=true
else
  DIFF_CMD="diff"
  DIFF_COLOR=false
fi

for f in "CLAUDE.md" "settings.json" ".mcp.json"; do
  live="$HOME/.claude/$f"
  repo="$REPO_DIR/claude/$f"
  if [ -L "$live" ]; then
    echo "  $f — symlinked (always in sync)"
  elif [ ! -f "$live" ]; then
    echo "  $f — not in ~/.claude/"
  elif [ ! -f "$repo" ]; then
    echo "  $f — not in repo"
  elif diff -q "$live" "$repo" > /dev/null 2>&1; then
    echo "  $f — identical"
  else
    echo "  $f — DIFFERS:"
    if [ "$DIFF_COLOR" = true ]; then
      "$DIFF_CMD" --color "$repo" "$live" || true
    else
      "$DIFF_CMD" "$repo" "$live" || true
    fi
  fi
done
