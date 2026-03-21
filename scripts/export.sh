#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../claude/hooks/scripts/lib.sh
source "$REPO_DIR/claude/hooks/scripts/lib.sh"
LIVE="$HOME/.claude"
REPO="$REPO_DIR/claude"

echo "Exporting live Claude Code config to repo"

for f in ".mcp.json" "settings.json" "CLAUDE.md"; do
  if [ -L "$LIVE/$f" ]; then
    echo "  $f — symlinked, already in sync"
  elif [ -f "$LIVE/$f" ]; then
    cp "$LIVE/$f" "$REPO/$f"
    echo "  Exported $f"
  else
    echo "  No $f found, skipping"
  fi
done

echo ""
echo "Now commit: cd ~/dotfiles-claude && git add -A && git commit -m 'update config from $(get_hostname)' && git push"
