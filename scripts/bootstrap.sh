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
printf ' |  \\/  | |/ /\n'
printf ' | |\\/| |   < \n'
printf ' |_|  |_|_|\\_\\\n'
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
  printf "   Some MCPs and hooks require node/npx.\n\n"
fi

# --- Check for AI tools ---
printf "\n${B}Detected tools:${R}\n"
command -v claude >/dev/null 2>&1 && printf "  ${G}✓${R} Claude Code\n" || printf "  ${D}✗ Claude Code (not found)${R}\n"
{ [ -d "$HOME/.cursor" ] || [ -d "/Applications/Cursor.app" ]; } && printf "  ${G}✓${R} Cursor\n" || printf "  ${D}✗ Cursor (not found)${R}\n"
command -v codex >/dev/null 2>&1 && printf "  ${G}✓${R} Codex\n" || printf "  ${D}✗ Codex (not found)${R}\n"
printf "\n"

# --- Init + apply ---
printf "${B}Running chezmoi init + apply...${R}\n"
printf "${D}You'll be prompted for: email, machine type, hook profile, API MCPs.${R}\n"
printf "${D}No API keys needed for core setup — OAuth MCPs auth in browser on first use.${R}\n\n"
chezmoi init --apply "git@github.com:${REPO}.git"

# --- Bitwarden check (if API MCPs enabled) ---
if grep -q 'enable_api_mcps = true' ~/.config/chezmoi/chezmoi.toml 2>/dev/null; then
  if command -v bw >/dev/null 2>&1; then
    printf "${Y}▸${R} API-key MCPs enabled. Make sure your Bitwarden vault is unlocked:\n"
    printf "  ${C}export BW_SESSION=\$(bw unlock --raw)${R}\n"
    printf "  ${C}chezmoi apply${R}\n\n"
  else
    printf "${Y}⚠${R}  API-key MCPs enabled but Bitwarden CLI not found.\n"
    printf "  Install: ${C}npm install -g @bitwarden/cli${R}\n"
    printf "  Then: ${C}bw login && export BW_SESSION=\$(bw unlock --raw) && chezmoi apply${R}\n\n"
  fi
fi

# --- Done ---
printf "\n${G}✓ Done!${R}\n\n"
printf "  OAuth MCPs (Context7, GitHub, Vercel) will prompt in\n"
printf "  your browser the first time you use them.\n\n"
printf "${B}Verify:${R}\n"
printf "  ${C}claude mcp list${R}            # Claude Code MCPs\n"
printf "  ${C}cat ~/.cursor/mcp.json${R}     # Cursor MCPs\n"
printf "  ${C}cat ~/.codex/config.toml${R}   # Codex config\n"
printf "  ${C}ls ~/.claude/rules/${R}        # Rules\n"
printf "  ${C}ls ~/.claude/agents/${R}       # Agents\n"
printf "  ${C}ls ~/.claude/hooks/${R}        # Hooks\n\n"
printf "${D}Update later: chezmoi update${R}\n"
