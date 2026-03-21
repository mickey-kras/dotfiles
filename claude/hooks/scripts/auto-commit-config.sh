#!/usr/bin/env bash
set -euo pipefail

# Runs after every Write/Edit/Bash tool use.
# If anything in the repo's claude/ dir changed, auto-commits and pushes.

REPO_DIR="$HOME/dotfiles-claude"

# Bail if repo doesn't exist
[ -d "$REPO_DIR/.git" ] || exit 0

cd "$REPO_DIR"

# Quick check — if nothing changed, exit fast (hot path)
CHANGED=$(git diff --name-only claude/ 2>/dev/null || true)
UNTRACKED=$(git ls-files --others --exclude-standard claude/ 2>/dev/null || true)

if [ -z "$CHANGED" ] && [ -z "$UNTRACKED" ]; then
  exit 0
fi

# Build list of what changed for the commit message
ALL_CHANGES=$(printf '%s\n%s' "$CHANGED" "$UNTRACKED" | grep -v '^$' | sort -u)
FILE_LIST=$(echo "$ALL_CHANGES" | head -3 | tr '\n' ', ' | sed 's/,$//')

# Stage, commit, push
git add claude/
git commit -m "auto-sync: ${FILE_LIST} from $(hostname -s)" --quiet 2>/dev/null || exit 0
git push origin main --quiet 2>/dev/null || {
  echo "dotfiles-claude: auto-commit ok but push failed — will retry next session" >&2
  exit 0
}

echo "dotfiles-claude: auto-synced ${FILE_LIST}" >&2
exit 0
