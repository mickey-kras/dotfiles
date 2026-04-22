#!/usr/bin/env bash
# Registers and reconciles MCP servers in Claude Code CLI and Claude Desktop App.
# Idempotent and authoritative: keeps the managed set, removes unmanaged extras.
#
# hash: e3c983475559f308071f700dfd083dbb8887c66574b68d3199d33917aa21a6aa

set -euo pipefail

FAILED=0
HOME_SLASHED="/Users/mikhailkrasilnikov"
RUNTIME_PROFILE="custom"
PROFILE_BASE="investigation"
AZURE_DEVOPS_ORG="<no value>"
MEMORY_PROVIDER="builtin"
OBSIDIAN_VAULT_PATH=""

DESIRED_MCP_NAMES=(
  "context7"
  "exa"
  "filesystem"
  "firecrawl"
  "git"
  "http"
  "memory"
  "playwright"
  "process"
  "telegram"
  "thinking"
)

to_cli_name() {
  case "$1" in
    docker) printf "MCP_DOCKER" ;;
    *) printf "%s" "$1" ;;
  esac
}

contains_name() {
  local needle="$1"; shift
  local item
  for item in "$@"; do
    if [ "$item" = "$needle" ]; then
      return 0
    fi
  done
  return 1
}

build_desktop_mcp_json() {
  cat "$HOME/.cursor/mcp.json"
}

print_summary() {
  local title="$1"; shift
  echo "$title"
  if [ "$#" -eq 0 ]; then
    echo "  - none"
    return
  fi
  local item
  for item in "$@"; do
    echo "  - $item"
  done
}

if command -v claude >/dev/null 2>&1; then
  echo "Reconciling Claude Code CLI MCPs..."

  EFFECTIVE_MCP_NAMES=()
  for name in "${DESIRED_MCP_NAMES[@]}"; do
    case "$name" in
      azure-devops)
        [ -n "$AZURE_DEVOPS_ORG" ] && EFFECTIVE_MCP_NAMES+=("$name")
        ;;
      http|aws)
        command -v uvx >/dev/null 2>&1 && EFFECTIVE_MCP_NAMES+=("$name")
        ;;
      github|tailscale|exa|firecrawl|fal-ai|telegram)
        command -v bw >/dev/null 2>&1 && EFFECTIVE_MCP_NAMES+=("$name")
        ;;
      docker)
        command -v docker >/dev/null 2>&1 && EFFECTIVE_MCP_NAMES+=("$name")
        ;;
      *)
        EFFECTIVE_MCP_NAMES+=("$name")
        ;;
    esac
  done

  CURRENT_MCP_NAMES=()
  if [ -f "$HOME/.claude.json" ] && command -v python3 >/dev/null 2>&1; then
    while IFS= read -r name; do
      [ -n "$name" ] && CURRENT_MCP_NAMES+=("$name")
    done < <(
      python3 - <<'PY'
import json, pathlib
p = pathlib.Path.home() / ".claude.json"
if p.exists():
    data = json.loads(p.read_text())
    for key in sorted((data.get("mcpServers") or {}).keys()):
        print(key)
PY
    )
  fi

  KEEP_MCP_NAMES=()
  ADD_MCP_NAMES=()
  REMOVE_MCP_NAMES=()

  for name in "${EFFECTIVE_MCP_NAMES[@]}"; do
    cli_name="$(to_cli_name "$name")"
    if contains_name "$cli_name" "${CURRENT_MCP_NAMES[@]:-}"; then
      KEEP_MCP_NAMES+=("$cli_name")
    else
      ADD_MCP_NAMES+=("$cli_name")
    fi
  done

  for name in "${CURRENT_MCP_NAMES[@]:-}"; do
    if ! contains_name "$name" "${KEEP_MCP_NAMES[@]:-}" && ! contains_name "$name" "${ADD_MCP_NAMES[@]:-}"; then
      REMOVE_MCP_NAMES+=("$name")
    fi
  done

  echo "Runtime profile: $RUNTIME_PROFILE"
  if [ "${#KEEP_MCP_NAMES[@]}" -gt 0 ]; then
    print_summary "Will keep:" "${KEEP_MCP_NAMES[@]}"
  else
    print_summary "Will keep:"
  fi
  if [ "${#ADD_MCP_NAMES[@]}" -gt 0 ]; then
    print_summary "Will add:" "${ADD_MCP_NAMES[@]}"
  else
    print_summary "Will add:"
  fi
  if [ "${#REMOVE_MCP_NAMES[@]}" -gt 0 ]; then
    print_summary "Will remove:" "${REMOVE_MCP_NAMES[@]}"
  else
    print_summary "Will remove:"
  fi

  for name in "${REMOVE_MCP_NAMES[@]:-}"; do
    [ -n "$name" ] || continue
    if claude mcp remove --scope user "$name" >/dev/null 2>&1; then
      echo "  - removed $name"
    else
      echo "  ! failed to remove $name"
      FAILED=$((FAILED + 1))
    fi
  done

  add_mcp() {
    local display="$1"; shift
    if claude mcp remove --scope user "$display" >/dev/null 2>&1; then
      :
    fi
    if claude mcp add --scope user "$@" >/dev/null 2>&1; then
      echo "  + $display"
    else
      echo "  ! $display (failed)"
      FAILED=$((FAILED + 1))
    fi
  }

  if contains_name "playwright" "${EFFECTIVE_MCP_NAMES[@]}"; then
    add_mcp playwright playwright -- npx -y @playwright/mcp@0.0.68
  fi

  if contains_name "context7" "${EFFECTIVE_MCP_NAMES[@]}"; then
    add_mcp context7 --transport http context7 "https://mcp.context7.com/mcp"
  fi

  if contains_name "figma" "${EFFECTIVE_MCP_NAMES[@]}"; then
    add_mcp figma --transport http figma "https://mcp.figma.com/mcp"
  fi

  if contains_name "atlassian" "${EFFECTIVE_MCP_NAMES[@]}"; then
    add_mcp atlassian --transport http atlassian "https://mcp.atlassian.com/v1/mcp"
  fi

  if contains_name "slack" "${EFFECTIVE_MCP_NAMES[@]}"; then
    add_mcp slack --transport http slack "https://mcp.slack.com/mcp"
  fi

  if contains_name "filesystem" "${EFFECTIVE_MCP_NAMES[@]}"; then
    mkdir -p "$HOME/Dev"
    add_mcp filesystem filesystem -- npx -y @modelcontextprotocol/server-filesystem@2026.1.14 "$HOME/Dev"
  fi

  if contains_name "git" "${EFFECTIVE_MCP_NAMES[@]}"; then
    add_mcp git git -- npx -y @cyanheads/git-mcp-server@2.10.5
  fi

  if contains_name "shell" "${EFFECTIVE_MCP_NAMES[@]}"; then
    add_mcp shell shell -- npx -y super-shell-mcp@2.0.15
  fi

  if contains_name "terraform" "${EFFECTIVE_MCP_NAMES[@]}"; then
    add_mcp terraform terraform -- npx -y terraform-mcp-server@0.13.0
  fi

  if contains_name "kubernetes" "${EFFECTIVE_MCP_NAMES[@]}"; then
    add_mcp kubernetes kubernetes -- npx -y mcp-server-kubernetes@3.4.0
  fi

  if contains_name "process" "${EFFECTIVE_MCP_NAMES[@]}"; then
    add_mcp process process -- npx -y @ai-capabilities-suite/mcp-process@1.5.10
  fi

  if contains_name "thinking" "${EFFECTIVE_MCP_NAMES[@]}"; then
    add_mcp thinking thinking -- npx -y @modelcontextprotocol/server-sequential-thinking@2025.12.18
  fi

  if contains_name "memory" "${EFFECTIVE_MCP_NAMES[@]}"; then
    if [ "$MEMORY_PROVIDER" = "obsidian" ] && [ -n "$OBSIDIAN_VAULT_PATH" ]; then
      add_mcp memory memory -- npx -y @bitbonsai/mcpvault@latest "$OBSIDIAN_VAULT_PATH"
    else
    add_mcp memory memory -- npx -y @modelcontextprotocol/server-memory@2026.1.26
    fi
  fi

  if contains_name "http" "${EFFECTIVE_MCP_NAMES[@]}"; then
    if command -v uvx >/dev/null 2>&1; then
      add_mcp http http -- uvx mcp-server-fetch==2025.4.7
    else
      echo "  ! http (uvx not found)"
      FAILED=$((FAILED + 1))
    fi
  fi

  if contains_name "github" "${EFFECTIVE_MCP_NAMES[@]}"; then
    if command -v bw >/dev/null 2>&1; then
      add_mcp github github -- node "$HOME/.local/bin/bw-mcp" mcp-github GITHUB_PERSONAL_ACCESS_TOKEN=password -- npx -y @modelcontextprotocol/server-github@2025.4.8
    else
      echo "  ! github (Bitwarden CLI not found)"
      FAILED=$((FAILED + 1))
    fi
  fi

  if contains_name "azure-devops" "${EFFECTIVE_MCP_NAMES[@]}"; then
    if [ -n "$AZURE_DEVOPS_ORG" ]; then
      add_mcp azure-devops azure-devops -- npx -y @azure-devops/mcp@2.5.0 "$AZURE_DEVOPS_ORG"
    else
      echo "  ! azure-devops (org not configured)"
      FAILED=$((FAILED + 1))
    fi
  fi

  if contains_name "aws" "${EFFECTIVE_MCP_NAMES[@]}"; then
    if command -v bw >/dev/null 2>&1 && command -v uvx >/dev/null 2>&1; then
      add_mcp aws aws -- node "$HOME/.local/bin/bw-mcp" mcp-aws AWS_ACCESS_KEY_ID=AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY=AWS_SECRET_ACCESS_KEY -- uvx awslabs.aws-api-mcp-server==1.3.26
    else
      echo "  ! aws (Bitwarden CLI or uvx not found)"
      FAILED=$((FAILED + 1))
    fi
  fi

  if contains_name "tailscale" "${EFFECTIVE_MCP_NAMES[@]}"; then
    if command -v bw >/dev/null 2>&1; then
      add_mcp tailscale tailscale -- node "$HOME/.local/bin/bw-mcp" mcp-tailscale TAILSCALE_API_KEY=password,TAILSCALE_TAILNET=TAILSCALE_TAILNET -- npx -y @hexsleeves/tailscale-mcp-server@0.3.2
    else
      echo "  ! tailscale (Bitwarden CLI not found)"
      FAILED=$((FAILED + 1))
    fi
  fi

  if contains_name "exa" "${EFFECTIVE_MCP_NAMES[@]}"; then
    if command -v bw >/dev/null 2>&1; then
      add_mcp exa exa -- node "$HOME/.local/bin/bw-mcp" exa-api-key EXA_API_KEY=password -- npx -y exa-mcp-server@3.1.9
    else
      echo "  ! exa (Bitwarden CLI not found)"
      FAILED=$((FAILED + 1))
    fi
  fi

  if contains_name "firecrawl" "${EFFECTIVE_MCP_NAMES[@]}"; then
    if command -v bw >/dev/null 2>&1; then
      add_mcp firecrawl firecrawl -- node "$HOME/.local/bin/bw-mcp" firecrawl-api-key FIRECRAWL_API_KEY=password -- npx -y firecrawl-mcp@3.11.0
    else
      echo "  ! firecrawl (Bitwarden CLI not found)"
      FAILED=$((FAILED + 1))
    fi
  fi

  if contains_name "fal-ai" "${EFFECTIVE_MCP_NAMES[@]}"; then
    if command -v bw >/dev/null 2>&1; then
      add_mcp fal-ai fal-ai -- node "$HOME/.local/bin/bw-mcp" fal-api-key FAL_KEY=password -- npx -y fal-ai-mcp-server@2.1.4
    else
      echo "  ! fal-ai (Bitwarden CLI not found)"
      FAILED=$((FAILED + 1))
    fi
  fi

  if contains_name "telegram" "${EFFECTIVE_MCP_NAMES[@]}"; then
    if command -v bw >/dev/null 2>&1; then
      add_mcp telegram telegram -- node "$HOME/.local/bin/bw-mcp" mcp-telegram TELEGRAM_BOT_TOKEN=password -- npx -y @iqai/mcp-telegram@latest
    else
      echo "  ! telegram (Bitwarden CLI not found)"
      FAILED=$((FAILED + 1))
    fi
  fi

  if contains_name "docker" "${EFFECTIVE_MCP_NAMES[@]}"; then
    if command -v docker >/dev/null 2>&1; then
      add_mcp MCP_DOCKER MCP_DOCKER -- docker mcp gateway run
    else
      echo "  ! MCP_DOCKER (docker not found)"
      FAILED=$((FAILED + 1))
    fi
  fi
else
  echo "claude CLI not found - skipping Claude Code MCP setup"
fi

if [ "$(uname -s)" = "Darwin" ]; then
  CLAUDE_DESKTOP_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
elif [ -n "${APPDATA:-}" ]; then
  CLAUDE_DESKTOP_CONFIG="$APPDATA/Claude/claude_desktop_config.json"
else
  CLAUDE_DESKTOP_CONFIG="$HOME/.config/Claude/claude_desktop_config.json"
fi

if [ -f "$CLAUDE_DESKTOP_CONFIG" ]; then
  echo ""
  echo "Reconciling Claude Desktop MCPs..."
  if command -v python3 >/dev/null 2>&1; then
    MCP_SERVERS_JSON="$(build_desktop_mcp_json)"
    python3 -c '
import json, sys
config_path = sys.argv[1]
new_mcps = json.loads(sys.argv[2])
with open(config_path, "r") as f:
    config = json.load(f)
config["mcpServers"] = new_mcps["mcpServers"]
with open(config_path, "w") as f:
    json.dump(config, f, indent=2)
    f.write("\n")
print("  + Claude Desktop MCPs updated")
' "$CLAUDE_DESKTOP_CONFIG" "$MCP_SERVERS_JSON"
  else
    echo "  ! python3 not found - skipping Claude Desktop config"
    FAILED=$((FAILED + 1))
  fi
else
  echo ""
  echo "Claude Desktop not found - skipping"
fi

echo ""
if [ "$FAILED" -eq 0 ]; then
  echo "MCP reconciliation complete."
else
  echo "$FAILED item(s) failed during MCP reconciliation."
fi

exit 0
