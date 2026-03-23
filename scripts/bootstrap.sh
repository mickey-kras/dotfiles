#!/usr/bin/env bash
set -euo pipefail

# One-command bootstrap for macOS / Linux / WSL
# Usage: bash <(curl -sL https://raw.githubusercontent.com/mickey-kras/dotfiles-claude/main/scripts/bootstrap.sh)

REPO="mickey-kras/dotfiles-claude"

# --- Colors ---
C='\033[1;36m'  # cyan
G='\033[1;32m'  # green
Y='\033[1;33m'  # yellow
D='\033[0;90m'  # dim
B='\033[1;37m'  # bold white
R='\033[0m'     # reset

# --- Logo ---
printf "${C}"
printf '  __  __ _  __\n'
printf ' |  \/  | |/ /\n'
printf ' | |\/| |   < \n'
printf ' |_|  |_|_|\_\\\n'
printf "${R}\n"
printf "${B}  AI Toolchain Bootstrap${R}\n"
printf "${D}  Claude Code · Cursor · Codex${R}\n\n"

# --- Install chezmoi if missing ---
if ! command -v chezmoi >/dev/null 2>&1; then
  printf "${Y}▸${R} Installing chezmoi...\n"
  if [[ "$(uname -s)" == "Darwin" ]]; then
    brew install chezmoi
  elif command -v apt-get >/dev/null 2>&1; then
    sudo sh -c 'curl -fsLS get.chezmoi.io | sh' && sudo mv ./bin/chezmoi /usr/local/bin/
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y chezmoi
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S chezmoi
  else
    sh -c "$(curl -fsLS get.chezmoi.io)"
    export PATH="$HOME/bin:$PATH"
  fi
  printf "  ${G}✓${R} chezmoi installed\n"
else
  printf "  ${G}✓${R} chezmoi $(chezmoi --version 2>/dev/null | head -c 30)\n"
fi

# --- Check dependencies ---
MISSING=()
command -v git  >/dev/null 2>&1 || MISSING+=("git")
command -v node >/dev/null 2>&1 || MISSING+=("node")
command -v npx  >/dev/null 2>&1 || MISSING+=("npx")

if [ ${#MISSING[@]} -gt 0 ]; then
  printf "\n${Y}⚠${R}  Missing: ${MISSING[*]}\n"
  printf "   MCPs require node/npx.\n\n"
fi

# --- Detect AI tools ---
printf "\n${B}Detected tools:${R}\n"
command -v claude >/dev/null 2>&1 && printf "  ${G}✓${R} Claude Code\n" || printf "  ${D}✗ Claude Code (not found)${R}\n"
{ [ -d "$HOME/.cursor" ] || [ -d "/Applications/Cursor.app" ]; } && printf "  ${G}✓${R} Cursor\n" || printf "  ${D}✗ Cursor (not found)${R}\n"
command -v codex >/dev/null 2>&1 && printf "  ${G}✓${R} Codex\n" || printf "  ${D}✗ Codex (not found)${R}\n"
printf "\n"

# --- MCP Selection ---
printf "${B}MCP Configuration${R}\n\n"

printf "  ${G}✓${R} Playwright        ${D}— Browser automation, E2E testing${R}\n"
printf "  ${G}✓${R} Context7          ${D}— Up-to-date library docs${R}\n"
printf "  ${G}✓${R} Sentry            ${D}— Error tracking, stack traces (OAuth)${R}\n"
printf "  ${G}✓${R} Figma             ${D}— Design-to-code (OAuth)${R}\n"
printf "\n"
printf "  ${B}Optional:${R}\n"
printf "  ${C}[1]${R} Azure DevOps     ${D}— Work items, PRs, pipelines${R}\n"
printf "  ${C}[2]${R} API MCPs         ${D}— Exa, Firecrawl, fal-ai (requires Bitwarden)${R}\n"
printf "\n"

ENABLE_AZURE_DEVOPS=false
AZURE_DEVOPS_ORG=""
ENABLE_API_MCPS=false

printf "${B}Enter numbers to enable (e.g. 1 2), or press Enter for core only: ${R}"
read -r CHOICES

for choice in $CHOICES; do
  case "$choice" in
    1)
      ENABLE_AZURE_DEVOPS=true
      printf "\n${B}Azure DevOps org name: ${R}"
      read -r AZURE_DEVOPS_ORG
      if [ -z "$AZURE_DEVOPS_ORG" ]; then
        printf "  ${Y}▸${R} No org name — skipping Azure DevOps\n"
        ENABLE_AZURE_DEVOPS=false
      else
        printf "  ${G}✓${R} Azure DevOps org: ${C}${AZURE_DEVOPS_ORG}${R}\n"
      fi
      ;;
    2)
      ENABLE_API_MCPS=true
      printf "  ${G}✓${R} API MCPs enabled\n"
      ;;
    *)
      printf "  ${Y}▸${R} Unknown option: $choice (skipped)\n"
      ;;
  esac
done

# --- Write chezmoi config ---
printf "\n${D}Writing chezmoi config...${R}\n"
mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.toml <<TOML
[data]
  enable_api_mcps = ${ENABLE_API_MCPS}
  azure_devops_org = "${AZURE_DEVOPS_ORG}"
TOML
printf "  ${G}✓${R} Config saved to ~/.config/chezmoi/chezmoi.toml\n"

# --- Init + apply (no prompts — config already written) ---
printf "\n${B}Applying dotfiles...${R}\n"
chezmoi init --apply "git@github.com:${REPO}.git"

# --- Bitwarden check (if API MCPs enabled) ---
if [ "$ENABLE_API_MCPS" = "true" ]; then
  if command -v bw >/dev/null 2>&1; then
    printf "\n${Y}▸${R} API MCPs enabled. Unlock your Bitwarden vault:\n"
    printf "  ${C}export BW_SESSION=\$(bw unlock --raw)${R}\n"
    printf "  ${C}chezmoi apply${R}\n\n"
  else
    printf "\n${Y}⚠${R}  API MCPs enabled but Bitwarden CLI not found.\n"
    printf "  Install: ${C}brew install bitwarden-cli${R}\n"
    printf "  Then: ${C}bw login && export BW_SESSION=\$(bw unlock --raw) && chezmoi apply${R}\n\n"
  fi
fi

# --- Done ---
printf "\n${G}✓ Done!${R}\n\n"
printf "${B}Verify:${R}\n"
printf "  ${C}claude mcp list${R}            # Claude Code MCPs\n"
printf "  ${C}cat ~/.cursor/mcp.json${R}     # Cursor MCPs\n"
printf "  ${C}cat ~/.codex/config.toml${R}   # Codex config\n"
printf "  ${C}ls ~/.claude/agents/${R}       # Agents\n\n"
printf "${D}Update later: dotfiles-update${R}\n"
printf "${D}Make sure ~/.local/bin is in your PATH${R}\n"
