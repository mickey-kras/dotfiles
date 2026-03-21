#!/usr/bin/env bash
set -euo pipefail

# Runs on every Claude Code session start.
# Pulls latest config from repo, re-links if needed, pushes local drift.

REPO_DIR="$HOME/dotfiles-claude"
CLAUDE_DIR="$HOME/.claude"

INPUT=$(cat)
SOURCE=$(echo "$INPUT" | jq -r '.source // "startup"')

# Only run on fresh startup, not resume/compact/clear
if [[ "$SOURCE" != "startup" ]]; then
  exit 0
fi

# Bail if repo doesn't exist
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "dotfiles-claude repo not found at $REPO_DIR" >&2
  exit 0
fi

cd "$REPO_DIR"

# --- Pull latest from remote ---
BEFORE=$(git rev-parse HEAD 2>/dev/null || echo "none")
git fetch origin main --quiet 2>/dev/null || exit 0
git merge origin/main --quiet --ff-only 2>/dev/null || {
  echo "dotfiles-claude: merge conflict — resolve manually: cd ~/dotfiles-claude && git status" >&2
  exit 1
}
AFTER=$(git rev-parse HEAD 2>/dev/null || echo "none")

if [[ "$BEFORE" != "$AFTER" ]]; then
  CHANGES=$(git log --oneline "$BEFORE..$AFTER" 2>/dev/null || echo "new changes")
  echo "dotfiles-claude synced. New commits:" >&2
  echo "$CHANGES" >&2
fi

# --- Check symlinks are intact ---
NEEDS_INSTALL=false
for item in CLAUDE.md settings.json .mcp.json rules skills agents; do
  src="$REPO_DIR/claude/$item"
  dst="$CLAUDE_DIR/$item"
  if [ -e "$src" ] && [ ! -L "$dst" ]; then
    NEEDS_INSTALL=true
    break
  fi
done

if [ "$NEEDS_INSTALL" = true ]; then
  echo "dotfiles-claude: symlinks broken — re-running install.sh" >&2
  "$REPO_DIR/scripts/install.sh" 2>&1 >&2 || true
fi

# --- Push any local drift ---
if ! git diff --quiet claude/ 2>/dev/null || [ -n "$(git ls-files --others --exclude-standard claude/ 2>/dev/null)" ]; then
  echo "dotfiles-claude: local config has uncommitted changes — auto-committing" >&2
  git add claude/
  git commit -m "auto-sync: local config changes from $(hostname -s)" --quiet 2>/dev/null || true
  git push origin main --quiet 2>/dev/null || {
    echo "dotfiles-claude: push failed — will retry next session" >&2
  }
fi

exit 0
