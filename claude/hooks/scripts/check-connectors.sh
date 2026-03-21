#!/usr/bin/env bash
set -euo pipefail

# SessionStart hook: outputs a structured prompt that tells Claude to compare
# its available tools against connectors.json and act on differences.
# Also checks what it CAN check from shell: local MCPs, missing API keys.

REPO_DIR="$HOME/dotfiles-claude"
# shellcheck source=lib.sh
source "$(dirname "$0")/lib.sh"
MANIFEST="$REPO_DIR/claude/connectors.json"
CLAUDE_DIR="$HOME/.claude"
MCP_FILE="$CLAUDE_DIR/.mcp.json"
SECRETS_FILE="$CLAUDE_DIR/settings.local.json"

[ ! -f "$MANIFEST" ] && exit 0

ISSUES=()

# --- Shell-checkable: local MCPs in .mcp.json ---
for name in $(jq -r '.local | keys[]' "$MANIFEST" 2>/dev/null); do
  desc=$(jq -r ".local[\"$name\"].description" "$MANIFEST")

  if [ -f "$MCP_FILE" ]; then
    if ! jq -e ".mcpServers[\"$name\"]" "$MCP_FILE" >/dev/null 2>&1; then
      ISSUES+=("LOCAL_MISSING: $name — $desc")
    fi
  fi

  # Check required secrets
  req_secret=$(jq -r ".local[\"$name\"].requires_secret // empty" "$MANIFEST")
  if [ -n "$req_secret" ]; then
    secret_val=""
    [ -f "$SECRETS_FILE" ] && secret_val=$(jq -r ".env[\"$req_secret\"] // empty" "$SECRETS_FILE" 2>/dev/null || true)
    [ -z "$secret_val" ] && secret_val="${!req_secret:-}"
    if [ -z "$secret_val" ]; then
      secret_url=$(jq -r ".local[\"$name\"].secret_url // empty" "$MANIFEST")
      ISSUES+=("SECRET_MISSING: $req_secret for $name — get from $secret_url")
    fi
  fi
done

# --- Output shell-checkable issues ---
if [ ${#ISSUES[@]} -gt 0 ]; then
  echo "" >&2
  for issue in "${ISSUES[@]}"; do
    echo "  $issue" >&2
  done
  echo "" >&2
fi

# --- Output structured prompt for Claude to check cloud connectors ---
# Claude sees stderr output in its session context.
# This tells Claude exactly what to do with its live tool list.

CLOUD_LIST=$(jq -r '.cloud | to_entries[] | "\(.key): \(.value.description)"' "$MANIFEST" 2>/dev/null)

if [ -n "$CLOUD_LIST" ]; then
  HOSTNAME=$(get_hostname)
  cat >&2 << PROMPT

[CONNECTOR_SYNC] Check your available tools against ~/dotfiles-claude/claude/connectors.json.
Expected cloud connectors:
$(echo "$CLOUD_LIST" | sed 's/^/  /')

Instructions:
- Check if you have tools matching each connector (slack_, gmail_, gcal_, atlassian/jira/confluence_, google_drive_).
- If you have a connector NOT in connectors.json: read the file, add it under "cloud" with "added_from": "$HOSTNAME", write it back. The auto-commit hook will push.
- If connectors.json lists one you DON'T have: tell the user which are missing and offer to help enable them.
- If everything matches: say nothing, proceed normally.
PROMPT
fi

exit 0
