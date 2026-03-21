#!/usr/bin/env bash
set -euo pipefail

# Runs on startup BEFORE sync. Validates config files, checks for
# hardcoded secrets, prompt injection, and missing security protections.
# Exit 2 = block startup (critical). Exit 0 = all clear or warnings only.

REPO_DIR="$HOME/dotfiles-claude"
MCP_FILE="$REPO_DIR/claude/.mcp.json"
SETTINGS_FILE="$REPO_DIR/claude/settings.json"
CLAUDE_MD="$REPO_DIR/claude/CLAUDE.md"
ISSUES=()

# --- MCP Security Checks ---
if [ -f "$MCP_FILE" ]; then
  # Valid JSON?
  if ! jq empty "$MCP_FILE" 2>/dev/null; then
    ISSUES+=("CRITICAL: .mcp.json is invalid JSON — Claude Code will ignore it")
  else
    # Suspicious commands
    while IFS= read -r cmd; do
      [ -z "$cmd" ] && continue
      case "$cmd" in
        *"curl "*|*"wget "*|*"nc "*|*"netcat "*)
          ISSUES+=("WARN: MCP server uses network tool as command: $cmd") ;;
        *"eval "*|*"bash -c"*|*"sh -c"*)
          ISSUES+=("WARN: MCP server uses eval/shell execution: $cmd") ;;
        *"sudo "*|*"su "*)
          ISSUES+=("CRITICAL: MCP server requires elevated privileges: $cmd") ;;
      esac
    done < <(jq -r '.mcpServers[].command // empty' "$MCP_FILE" 2>/dev/null)

    # Hardcoded secrets in env vars
    while IFS= read -r env; do
      [ -z "$env" ] && continue
      VALUE="${env#*=}"
      KEY="${env%%=*}"
      if [[ "$VALUE" =~ ^sk- ]] || [[ "$VALUE" =~ ^ghp_ ]] || [[ "$VALUE" =~ ^xox ]] || [[ "$VALUE" =~ ^glpat- ]]; then
        ISSUES+=("CRITICAL: Hardcoded secret in .mcp.json env var: $KEY — use settings.local.json instead")
      fi
    done < <(jq -r '.mcpServers[] | .env // {} | to_entries[] | "\(.key)=\(.value)"' "$MCP_FILE" 2>/dev/null)

    # Third-party MCP packages (informational)
    while IFS= read -r arg; do
      [ -z "$arg" ] && continue
      if [[ "$arg" == *"mcp"* ]] && [[ "$arg" != "@modelcontextprotocol/"* ]] && [[ "$arg" != "@anthropic/"* ]] && [[ "$arg" != "-y" ]]; then
        ISSUES+=("INFO: Third-party MCP package: $arg — verify it's trusted")
      fi
    done < <(jq -r '.mcpServers[] | .args[]? // empty' "$MCP_FILE" 2>/dev/null)
  fi
fi

# --- Settings Security Checks ---
if [ -f "$SETTINGS_FILE" ]; then
  if ! jq empty "$SETTINGS_FILE" 2>/dev/null; then
    ISSUES+=("CRITICAL: settings.json is invalid JSON")
  else
    DENY=$(jq -r '.permissions.deny[]? // empty' "$SETTINGS_FILE" 2>/dev/null)
    HAS_SUDO=false
    HAS_RMRF=false
    while IFS= read -r rule; do
      [[ "$rule" == *"sudo"* ]] && HAS_SUDO=true
      [[ "$rule" == *"rm -rf /"* ]] && HAS_RMRF=true
    done <<< "$DENY"
    [ "$HAS_SUDO" = false ] && ISSUES+=("WARN: deny list missing sudo protection")
    [ "$HAS_RMRF" = false ] && ISSUES+=("WARN: deny list missing rm -rf / protection")
  fi
fi

# --- CLAUDE.md Checks ---
if [ -f "$CLAUDE_MD" ]; then
  LINE_COUNT=$(wc -l < "$CLAUDE_MD")
  if [ "$LINE_COUNT" -gt 200 ]; then
    ISSUES+=("WARN: CLAUDE.md is $LINE_COUNT lines (max recommended: 200) — Claude may ignore rules at the end")
  fi

  # Prompt injection patterns
  if grep -qiE '(ignore previous|disregard all|you are now|new instructions:|override all|jailbreak)' "$CLAUDE_MD" 2>/dev/null; then
    ISSUES+=("CRITICAL: CLAUDE.md contains potential prompt injection patterns")
  fi

  # Essential sections
  grep -q "Security" "$CLAUDE_MD" 2>/dev/null || ISSUES+=("WARN: CLAUDE.md missing Security section")
fi

# --- Report ---
if [ ${#ISSUES[@]} -eq 0 ]; then
  echo "Security audit passed" >&2
  exit 0
fi

CRITICAL=0
for issue in "${ISSUES[@]}"; do
  echo "  $issue" >&2
  [[ "$issue" == CRITICAL* ]] && CRITICAL=$((CRITICAL + 1))
done

if [ $CRITICAL -gt 0 ]; then
  echo "" >&2
  echo "BLOCKED: $CRITICAL critical issue(s). Fix before proceeding." >&2
  exit 2
fi

# Warnings only — allow but inform
exit 0
