#!/usr/bin/env bash
set -euo pipefail

# One-command bootstrap for macOS / Linux / WSL / Windows (Git Bash)
# Usage: bash <(curl -sL https://raw.githubusercontent.com/mickey-kras/dotfiles/main/scripts/bootstrap.sh)

REPO="mickey-kras/dotfiles"

is_windows_gitbash() {
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) return 0 ;;
    *) return 1 ;;
  esac
}

# --- Colors ---
C='\033[1;36m'  # cyan
G='\033[1;32m'  # green
Y='\033[1;33m'  # yellow
D='\033[0;90m'  # dim
B='\033[1;37m'  # bold white
RED='\033[1;31m' # red
R='\033[0m'     # reset

# --- Logo ---
printf "${C}"
printf '  ____        _    __ _ _            \n'
printf ' |  _ \\  ___ | |_ / _(_) | ___  ___ \n'
printf ' | | | |/ _ \\| __| |_| | |/ _ \\/ __|\n'
printf ' | |_| | (_) | |_|  _| | |  __/\\__ \\\n'
printf ' |____/ \\___/ \\__|_| |_|_|\\___||___/\n'
printf "${R}\n"
printf "${B}              .dotfiles${R}\n"
printf "${D}  Claude Code - Cursor - Codex${R}\n\n"

# --- Install chezmoi if missing ---
if ! command -v chezmoi >/dev/null 2>&1; then
  printf "${Y}>${R} Installing chezmoi...\n"
  if [[ "$(uname -s)" == "Darwin" ]]; then
    brew install chezmoi
  elif is_windows_gitbash && command -v winget.exe >/dev/null 2>&1; then
    winget.exe install -e --id twpayne.chezmoi --accept-package-agreements --accept-source-agreements
  elif is_windows_gitbash && command -v choco >/dev/null 2>&1; then
    choco install chezmoi -y
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
  printf "  ${G}+${R} chezmoi installed\n"
else
  printf "  ${G}+${R} chezmoi $(chezmoi --version 2>/dev/null | head -c 30)\n"
fi

# --- Check dependencies ---
MISSING=()
command -v git  >/dev/null 2>&1 || MISSING+=("git")
command -v node >/dev/null 2>&1 || MISSING+=("node")
command -v npx  >/dev/null 2>&1 || MISSING+=("npx")
command -v uvx  >/dev/null 2>&1 || MISSING+=("uvx")

if [ ${#MISSING[@]} -gt 0 ]; then
  printf "\n${Y}!${R}  Missing: ${MISSING[*]}\n"
  printf "   Some MCPs require node/npx/uvx.\n\n"
fi

# --- Detect AI tools ---
printf "\n${B}Detected tools:${R}\n"
command -v claude >/dev/null 2>&1 && printf "  ${G}+${R} Claude Code\n" || printf "  ${D}x Claude Code (not found)${R}\n"
{ [ -d "$HOME/.cursor" ] || [ -d "/Applications/Cursor.app" ]; } && printf "  ${G}+${R} Cursor\n" || printf "  ${D}x Cursor (not found)${R}\n"
command -v codex >/dev/null 2>&1 && printf "  ${G}+${R} Codex\n" || printf "  ${D}x Codex (not found)${R}\n"
printf "\n"

RUNTIME_PROFILE="balanced"
CAPABILITY_PACK="software-development"
PROFILE_BASE="balanced"
AZURE_DEVOPS_ORG=""
ENABLE_API_MCPS=false
USER_NAME=""
USER_ROLE_SUMMARY=""
USER_STACK_SUMMARY=""
MEMORY_PROVIDER="builtin"
OBSIDIAN_VAULT_PATH=""
CUSTOM_ENABLED_MCPS=()
CUSTOM_DISABLED_MCPS=()
CUSTOM_ENABLED_PERMISSION_GROUPS=()
CUSTOM_DISABLED_PERMISSION_GROUPS=()

RESTRICTED_MCPS=(playwright context7 figma filesystem git memory thinking github azure-devops)
BALANCED_EXTRA_MCPS=(shell docker process terraform kubernetes)
OPEN_EXTRA_MCPS=(http aws tailscale exa firecrawl fal-ai)

RESTRICTED_PERMISSION_GROUPS=(core_read_write shell_readonly git_safe gh_safe)
BALANCED_EXTRA_PERMISSION_GROUPS=(git_full gh_full dev_runtime local_file_mutation containers infra_local)
OPEN_EXTRA_PERMISSION_GROUPS=(package_runtime cloud_extended secret_tools web_access)

join_by() {
  local delim="$1"; shift
  local first=1 item
  for item in "$@"; do
    if [ "$first" -eq 1 ]; then
      printf "%s" "$item"
      first=0
    else
      printf "%s%s" "$delim" "$item"
    fi
  done
}

contains_word() {
  local needle="$1"; shift
  local item
  for item in "$@"; do
    [ "$item" = "$needle" ] && return 0
  done
  return 1
}

unique_words() {
  awk '!seen[$0]++'
}

detect_existing_value() {
  local key="$1"
  python3 - "$HOME/.config/chezmoi/chezmoi.toml" "$key" <<'PY' 2>/dev/null || true
import re, sys, pathlib
path = pathlib.Path(sys.argv[1])
key = sys.argv[2]
if not path.exists():
    raise SystemExit(0)
text = path.read_text()
m = re.search(r'^\s*%s\s*=\s*"(.*)"\s*$' % re.escape(key), text, re.M)
if m:
    print(m.group(1))
PY
}

profile_summary() {
  local profile="$1"
  case "$profile" in
    restricted)
      printf "restricted: remote work systems, no local/system risk by default\n"
      printf "  MCPs: %s\n" "$(join_by ', ' "${RESTRICTED_MCPS[@]}")"
      ;;
    balanced)
      printf "balanced: restricted plus practical local execution and containers\n"
      printf "  MCPs: %s\n" "$(join_by ', ' "${RESTRICTED_MCPS[@]}" "${BALANCED_EXTRA_MCPS[@]}")"
      ;;
    open)
      printf "open: balanced plus cloud, web, and high-injection MCPs\n"
      printf "  MCPs: %s\n" "$(join_by ', ' "${RESTRICTED_MCPS[@]}" "${BALANCED_EXTRA_MCPS[@]}" "${OPEN_EXTRA_MCPS[@]}")"
      ;;
    custom)
      printf "custom: curated MCP catalog and permission groups, user-selected\n"
      ;;
  esac
}

pick_with_gum() {
  local prompt="$1"; shift
  gum choose --header "$prompt" "$@"
}

pick_many_with_gum() {
  local prompt="$1"; shift
  gum choose --no-limit --header "$prompt" "$@"
}

effective_mcps() {
  local profile="$1" base="$2"
  local values=()
  case "$profile" in
    restricted) values=("${RESTRICTED_MCPS[@]}") ;;
    balanced) values=("${RESTRICTED_MCPS[@]}" "${BALANCED_EXTRA_MCPS[@]}") ;;
    open) values=("${RESTRICTED_MCPS[@]}" "${BALANCED_EXTRA_MCPS[@]}" "${OPEN_EXTRA_MCPS[@]}") ;;
    custom)
      case "$base" in
        restricted) values=("${RESTRICTED_MCPS[@]}") ;;
        balanced) values=("${RESTRICTED_MCPS[@]}" "${BALANCED_EXTRA_MCPS[@]}") ;;
        open) values=("${RESTRICTED_MCPS[@]}" "${BALANCED_EXTRA_MCPS[@]}" "${OPEN_EXTRA_MCPS[@]}") ;;
        *) values=("${RESTRICTED_MCPS[@]}" "${BALANCED_EXTRA_MCPS[@]}") ;;
      esac
      values+=("${CUSTOM_ENABLED_MCPS[@]}")
      local item filtered=()
      for item in "${values[@]}"; do
        if ! contains_word "$item" "${CUSTOM_DISABLED_MCPS[@]}"; then
          filtered+=("$item")
        fi
      done
      values=("${filtered[@]}")
      ;;
  esac
  printf "%s\n" "${values[@]}" | unique_words
}

effective_permission_groups() {
  local profile="$1" base="$2"
  local values=()
  case "$profile" in
    restricted) values=("${RESTRICTED_PERMISSION_GROUPS[@]}") ;;
    balanced) values=("${RESTRICTED_PERMISSION_GROUPS[@]}" "${BALANCED_EXTRA_PERMISSION_GROUPS[@]}") ;;
    open) values=("${RESTRICTED_PERMISSION_GROUPS[@]}" "${BALANCED_EXTRA_PERMISSION_GROUPS[@]}" "${OPEN_EXTRA_PERMISSION_GROUPS[@]}") ;;
    custom)
      case "$base" in
        restricted) values=("${RESTRICTED_PERMISSION_GROUPS[@]}") ;;
        balanced) values=("${RESTRICTED_PERMISSION_GROUPS[@]}" "${BALANCED_EXTRA_PERMISSION_GROUPS[@]}") ;;
        open) values=("${RESTRICTED_PERMISSION_GROUPS[@]}" "${BALANCED_EXTRA_PERMISSION_GROUPS[@]}" "${OPEN_EXTRA_PERMISSION_GROUPS[@]}") ;;
        *) values=("${RESTRICTED_PERMISSION_GROUPS[@]}" "${BALANCED_EXTRA_PERMISSION_GROUPS[@]}") ;;
      esac
      values+=("${CUSTOM_ENABLED_PERMISSION_GROUPS[@]}")
      local item filtered=()
      for item in "${values[@]}"; do
        if ! contains_word "$item" "${CUSTOM_DISABLED_PERMISSION_GROUPS[@]}"; then
          filtered+=("$item")
        fi
      done
      values=("${filtered[@]}")
      ;;
  esac
  printf "%s\n" "${values[@]}" | unique_words
}

default_memory_provider_for_profile() {
  local profile="$1"
  if [ "$profile" = "restricted" ]; then
    printf "builtin"
  else
    printf "obsidian"
  fi
}

EXISTING_MEMORY_PROVIDER="$(detect_existing_value memory_provider)"
EXISTING_OBSIDIAN_VAULT="$(detect_existing_value obsidian_vault_path)"

if command -v gum >/dev/null 2>&1; then
  printf "${B}Profile Selection${R}\n\n"
  profile_summary restricted
  profile_summary balanced
  profile_summary open
  profile_summary custom
  printf "\n"
  RUNTIME_PROFILE="$(pick_with_gum "Select runtime profile" restricted balanced open custom)"
  CAPABILITY_PACK="$(pick_with_gum "Select capability pack" software-development)"
  DEFAULT_MEMORY_PROVIDER="${EXISTING_MEMORY_PROVIDER:-$(default_memory_provider_for_profile "$RUNTIME_PROFILE")}"
  if [ "$DEFAULT_MEMORY_PROVIDER" = "obsidian" ]; then
    MEMORY_PROVIDER="$(pick_with_gum "Select memory provider" obsidian builtin)"
  else
    MEMORY_PROVIDER="$(pick_with_gum "Select memory provider" builtin obsidian)"
  fi
  if [ "$MEMORY_PROVIDER" = "obsidian" ]; then
    OBSIDIAN_VAULT_PATH="$(gum input --header "Obsidian vault path" --value "${EXISTING_OBSIDIAN_VAULT:-}")"
  fi
else
  if [[ "$(uname -s)" == "Darwin" ]] && command -v brew >/dev/null 2>&1; then
    printf "${B}Optional dependency${R}\n"
    printf "  gum provides the richer TUI installer flow.\n"
    printf "${B}Install gum with Homebrew for future setup runs? [y/N]: ${R}"
    read -r INSTALL_GUM
    if [ "$INSTALL_GUM" = "y" ] || [ "$INSTALL_GUM" = "Y" ]; then
      brew install gum || true
    fi
  fi
  printf "${B}Runtime profile [restricted/balanced/open/custom] (default: balanced): ${R}"
  read -r RUNTIME_PROFILE
  [ -z "$RUNTIME_PROFILE" ] && RUNTIME_PROFILE="balanced"
  CAPABILITY_PACK="software-development"
  DEFAULT_MEMORY_PROVIDER="${EXISTING_MEMORY_PROVIDER:-$(default_memory_provider_for_profile "$RUNTIME_PROFILE")}"
  if [ "$DEFAULT_MEMORY_PROVIDER" = "builtin" ]; then
    printf "${B}Memory provider [builtin/obsidian] (default: builtin): ${R}"
  else
    printf "${B}Memory provider [obsidian/builtin] (default: obsidian): ${R}"
  fi
  read -r MEMORY_PROVIDER
  if [ -z "$MEMORY_PROVIDER" ]; then
    MEMORY_PROVIDER="$DEFAULT_MEMORY_PROVIDER"
  fi
  if [ "$MEMORY_PROVIDER" = "obsidian" ]; then
    printf "${B}Obsidian vault path [%s]: ${R}" "${EXISTING_OBSIDIAN_VAULT}"
    read -r OBSIDIAN_VAULT_PATH
    [ -z "$OBSIDIAN_VAULT_PATH" ] && OBSIDIAN_VAULT_PATH="$EXISTING_OBSIDIAN_VAULT"
  fi
fi

case "$RUNTIME_PROFILE" in
  restricted|balanced|open|custom) ;;
  *)
    printf "  ${Y}>${R} Unknown runtime profile - defaulting to balanced\n"
    RUNTIME_PROFILE="balanced"
    ;;
esac

if [ "$RUNTIME_PROFILE" = "custom" ]; then
  if command -v gum >/dev/null 2>&1; then
    PROFILE_BASE="$(pick_with_gum "Select custom base profile" restricted balanced open)"
    mapfile -t CUSTOM_ENABLED_MCPS < <(pick_many_with_gum "Select MCPs to enable on top of base profile" "${RESTRICTED_MCPS[@]}" "${BALANCED_EXTRA_MCPS[@]}" "${OPEN_EXTRA_MCPS[@]}" | sort -u)
    mapfile -t CUSTOM_ENABLED_PERMISSION_GROUPS < <(pick_many_with_gum "Select permission groups to enable on top of base profile" \
      core_read_write shell_readonly git_safe gh_safe git_full gh_full dev_runtime local_file_mutation containers infra_local package_runtime cloud_extended secret_tools web_access | sort -u)
  else
    printf "${B}Custom base profile [restricted/balanced/open] (default: balanced): ${R}"
    read -r PROFILE_BASE
    [ -z "$PROFILE_BASE" ] && PROFILE_BASE="balanced"
    printf "${B}Custom enabled MCPs (space-separated, curated catalog only): ${R}"
    read -r CUSTOM_MCP_INPUT
    for item in $CUSTOM_MCP_INPUT; do CUSTOM_ENABLED_MCPS+=("$item"); done
    printf "${B}Custom enabled permission groups (space-separated): ${R}"
    read -r CUSTOM_PG_INPUT
    for item in $CUSTOM_PG_INPUT; do CUSTOM_ENABLED_PERMISSION_GROUPS+=("$item"); done
  fi
fi

detect_existing_name() {
  local file
  for file in "$HOME/.claude/CLAUDE.md" "$HOME/.codex/AGENTS.md"; do
    if [ -f "$file" ]; then
      sed -n 's/^- Name: \([^.]*\)\..*/\1/p' "$file" | head -n1
      return 0
    fi
  done
  return 1
}

EXISTING_NAME="$(detect_existing_name || true)"
if [ -n "$EXISTING_NAME" ]; then
  printf "${B}Reuse existing display name '${EXISTING_NAME}'? [Y/n]: ${R}"
  read -r REUSE_NAME
  if [ -z "$REUSE_NAME" ] || [ "$REUSE_NAME" = "y" ] || [ "$REUSE_NAME" = "Y" ]; then
    USER_NAME="$EXISTING_NAME"
  fi
fi

if [ -z "$USER_NAME" ]; then
  printf "${B}Display name for generated instructions: ${R}"
  read -r USER_NAME
fi

if [ -z "$USER_NAME" ]; then
  USER_NAME="$(whoami)"
fi

if [ "$MEMORY_PROVIDER" = "obsidian" ] && [ -z "$OBSIDIAN_VAULT_PATH" ]; then
  printf "  ${Y}>${R} Obsidian selected without a vault path - falling back to builtin memory\n"
  MEMORY_PROVIDER="builtin"
fi

EXISTING_ROLE="$(detect_existing_value user_role_summary)"
if [ -n "$EXISTING_ROLE" ]; then
  USER_ROLE_SUMMARY="$EXISTING_ROLE"
else
  USER_ROLE_SUMMARY="Full-stack software engineer focused on distributed systems, product delivery, and practical AI-assisted development."
fi
if command -v gum >/dev/null 2>&1; then
  USER_ROLE_SUMMARY="$(gum input --header "Role summary" --value "$USER_ROLE_SUMMARY")"
else
  printf "${B}Role summary [%s]: ${R}" "$USER_ROLE_SUMMARY"
  read -r ROLE_INPUT
  [ -n "$ROLE_INPUT" ] && USER_ROLE_SUMMARY="$ROLE_INPUT"
fi

EXISTING_STACK="$(detect_existing_value user_stack_summary)"
if [ -n "$EXISTING_STACK" ]; then
  USER_STACK_SUMMARY="$EXISTING_STACK"
else
  USER_STACK_SUMMARY="C#/.NET, Python, Go, TypeScript, React, Angular; cloud and platform work across Azure, AWS, GCP, Cloudflare, and DigitalOcean."
fi
if command -v gum >/dev/null 2>&1; then
  USER_STACK_SUMMARY="$(gum input --header "Stack summary" --value "$USER_STACK_SUMMARY")"
else
  printf "${B}Stack summary [%s]: ${R}" "$USER_STACK_SUMMARY"
  read -r STACK_INPUT
  [ -n "$STACK_INPUT" ] && USER_STACK_SUMMARY="$STACK_INPUT"
fi

EXISTING_AZDO="$(detect_existing_value azure_devops_org)"
if [ -n "$EXISTING_AZDO" ]; then
  AZURE_DEVOPS_ORG="$EXISTING_AZDO"
fi
if command -v gum >/dev/null 2>&1; then
  AZURE_DEVOPS_ORG="$(gum input --header "Azure DevOps org name (optional)" --value "$AZURE_DEVOPS_ORG")"
else
  printf "${B}Azure DevOps org name [%s]: ${R}" "$AZURE_DEVOPS_ORG"
  read -r AZDO_INPUT
  [ -n "$AZDO_INPUT" ] && AZURE_DEVOPS_ORG="$AZDO_INPUT"
fi

case "$RUNTIME_PROFILE" in
  restricted)
    ENABLE_API_MCPS=false
    ;;
  balanced)
    ENABLE_API_MCPS=false
    ;;
  open)
    ENABLE_API_MCPS=true
    ;;
  custom)
    if contains_word aws "${CUSTOM_ENABLED_MCPS[@]}" || contains_word tailscale "${CUSTOM_ENABLED_MCPS[@]}" || contains_word exa "${CUSTOM_ENABLED_MCPS[@]}" || contains_word firecrawl "${CUSTOM_ENABLED_MCPS[@]}" || contains_word fal-ai "${CUSTOM_ENABLED_MCPS[@]}"; then
      ENABLE_API_MCPS=true
    fi
    ;;
esac

printf "\n${B}Planned configuration${R}\n"
printf "  Runtime profile: ${C}%s${R}\n" "$RUNTIME_PROFILE"
printf "  Capability pack: ${C}%s${R}\n" "$CAPABILITY_PACK"
printf "  Display name: ${C}%s${R}\n" "$USER_NAME"
printf "  Role: ${D}%s${R}\n" "$USER_ROLE_SUMMARY"
printf "  Stack: ${D}%s${R}\n" "$USER_STACK_SUMMARY"
printf "  Memory provider: ${C}%s${R}\n" "$MEMORY_PROVIDER"
if [ "$MEMORY_PROVIDER" = "obsidian" ] && [ -n "$OBSIDIAN_VAULT_PATH" ]; then
  printf "  Obsidian vault: ${D}%s${R}\n" "$OBSIDIAN_VAULT_PATH"
fi
if [ -n "$AZURE_DEVOPS_ORG" ]; then
  printf "  Azure DevOps org: ${C}%s${R}\n" "$AZURE_DEVOPS_ORG"
fi
if [ "$RUNTIME_PROFILE" = "custom" ]; then
  printf "  Custom base: ${C}%s${R}\n" "$PROFILE_BASE"
  printf "  Custom enabled MCPs: ${D}%s${R}\n" "$(join_by ', ' "${CUSTOM_ENABLED_MCPS[@]}")"
  printf "  Custom enabled permission groups: ${D}%s${R}\n" "$(join_by ', ' "${CUSTOM_ENABLED_PERMISSION_GROUPS[@]}")"
fi
mapfile -t EFFECTIVE_MCPS < <(effective_mcps "$RUNTIME_PROFILE" "$PROFILE_BASE")
mapfile -t EFFECTIVE_PERMISSION_GROUPS < <(effective_permission_groups "$RUNTIME_PROFILE" "$PROFILE_BASE")
printf "  Effective MCPs: ${D}%s${R}\n" "$(join_by ', ' "${EFFECTIVE_MCPS[@]}")"
printf "  Permission groups: ${D}%s${R}\n" "$(join_by ', ' "${EFFECTIVE_PERMISSION_GROUPS[@]}")"

if command -v gum >/dev/null 2>&1; then
  gum confirm "Apply this profile?" || exit 0
else
  printf "${B}Apply this profile? [Y/n]: ${R}"
  read -r APPLY_CONFIRM
  if [ "$APPLY_CONFIRM" = "n" ] || [ "$APPLY_CONFIRM" = "N" ]; then
    exit 0
  fi
fi

# --- Write chezmoi config (Bitwarden-backed MCPs disabled for initial apply) ---
printf "\n${D}Writing chezmoi config...${R}\n"
mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.toml <<TOML
[data]
  user_name = "${USER_NAME}"
  user_role_summary = "${USER_ROLE_SUMMARY}"
  user_stack_summary = "${USER_STACK_SUMMARY}"
  runtime_profile = "${RUNTIME_PROFILE}"
  capability_pack = "${CAPABILITY_PACK}"
  profile_base = "${PROFILE_BASE}"
  custom_enabled_mcps = [$(for i in "${CUSTOM_ENABLED_MCPS[@]}"; do printf '"%s",' "$i"; done | sed 's/,$//')]
  custom_disabled_mcps = []
  custom_enabled_permission_groups = [$(for i in "${CUSTOM_ENABLED_PERMISSION_GROUPS[@]}"; do printf '"%s",' "$i"; done | sed 's/,$//')]
  custom_disabled_permission_groups = []
  enable_api_mcps = ${ENABLE_API_MCPS}
  memory_provider = "${MEMORY_PROVIDER}"
  obsidian_vault_path = "${OBSIDIAN_VAULT_PATH}"
  azure_devops_org = "${AZURE_DEVOPS_ORG}"
TOML
printf "  ${G}+${R} Config saved to ~/.config/chezmoi/chezmoi.toml\n"

# --- Clear stale chezmoi state and source for a clean init ---
CHEZMOI_SRC="${HOME}/.local/share/chezmoi"
DOTFILES_DIR="${HOME}/dotfiles"
# Remove symlink or stale clone so chezmoi init starts fresh
[ -L "$CHEZMOI_SRC" ] && rm -f "$CHEZMOI_SRC"
[ -d "$CHEZMOI_SRC" ] && rm -rf "$CHEZMOI_SRC"
# Remove cached promptOnce answers so our config values take effect
rm -f "${HOME}/.config/chezmoi/chezmoistate.boltdb"
rm -f "${HOME}/.config/chezmoi/chezmoistate"

# --- Init + apply (fresh clone - Bitwarden-backed MCPs deferred until Bitwarden is ready) ---
printf "\n${B}Applying dotfiles...${R}\n"
if ! chezmoi init --apply "git@github.com:${REPO}.git" 2>/dev/null; then
  printf "  ${Y}>${R} SSH clone failed - falling back to HTTPS\n"
  chezmoi init --apply "https://github.com/${REPO}.git"
fi

# --- Consolidate source: ~/dotfiles + symlink ---
if [ -d "$CHEZMOI_SRC" ] && [ ! -L "$CHEZMOI_SRC" ]; then
  if [ -d "$DOTFILES_DIR" ]; then
    # User already has a working copy - point chezmoi at it
    rm -rf "$CHEZMOI_SRC"
  else
    mv "$CHEZMOI_SRC" "$DOTFILES_DIR"
  fi
  ln -s "$DOTFILES_DIR" "$CHEZMOI_SRC"
  printf "  ${G}+${R} Source linked: %s -> %s\n" "$CHEZMOI_SRC" "$DOTFILES_DIR"
fi

# --- Bitwarden setup (if Bitwarden-backed MCPs enabled) ---
if [ "$ENABLE_API_MCPS" = "true" ]; then
  if ! command -v bw >/dev/null 2>&1; then
    printf "\n${B}Bitwarden CLI required for Bitwarden-backed MCPs${R}\n"
    printf "${B}Install now? [Y/n]: ${R}"
    read -r BW_INSTALL
    if [ "$BW_INSTALL" != "n" ] && [ "$BW_INSTALL" != "N" ]; then
      if [[ "$(uname -s)" == "Darwin" ]] && command -v brew >/dev/null 2>&1; then
        brew install bitwarden-cli
      elif is_windows_gitbash && command -v winget.exe >/dev/null 2>&1; then
        winget.exe install -e --id Bitwarden.CLI --accept-package-agreements --accept-source-agreements
      elif is_windows_gitbash && command -v choco >/dev/null 2>&1; then
        choco install bitwarden-cli -y
      elif command -v npm >/dev/null 2>&1; then
        npm install -g @bitwarden/cli
      elif command -v apt-get >/dev/null 2>&1; then
        sudo snap install bw
      else
        printf "  ${RED}x${R} Could not detect a supported package manager.\n"
        printf "  Install manually: ${C}https://bitwarden.com/help/cli/${R}\n\n"
      fi
    fi
  fi

  if command -v bw >/dev/null 2>&1; then
    printf "\n${B}Bitwarden login & unlock${R}\n"
    if "$HOME/.local/bin/bw-login"; then
      export BW_SESSION="$(cat "$HOME/.bw_session")"
      printf "  ${G}+${R} Vault unlocked\n"

      # --- Ensure required Bitwarden items exist ---
      BW_ITEMS=("exa-api-key:Exa:https://exa.ai" "firecrawl-api-key:Firecrawl:https://firecrawl.dev" "fal-api-key:fal.ai:https://fal.ai")
      ITEMS_MISSING=false
      for entry in "${BW_ITEMS[@]}"; do
        ITEM_NAME="${entry%%:*}"
        if ! bw get password "$ITEM_NAME" >/dev/null 2>&1; then
          ITEMS_MISSING=true
          break
        fi
      done

      if [ "$ITEMS_MISSING" = "true" ]; then
        printf "\n${B}API key setup${R}\n"
        printf "  ${D}Create free accounts and paste API keys below.${R}\n"
        printf "  ${D}Press Enter to skip any service.${R}\n\n"
        for entry in "${BW_ITEMS[@]}"; do
          ITEM_NAME="${entry%%:*}"
          REST="${entry#*:}"
          ITEM_LABEL="${REST%%:*}"
          ITEM_URL="${REST#*:}"
          if bw get password "$ITEM_NAME" >/dev/null 2>&1; then
            printf "  ${G}+${R} %s - already configured\n" "$ITEM_LABEL"
          else
            printf "  ${C}%s${R} ${D}(%s)${R}\n" "$ITEM_LABEL" "$ITEM_URL"
            printf "  API key: "
            read -r API_KEY
            if [ -n "$API_KEY" ]; then
              TEMPLATE=$(bw get template item)
              echo "$TEMPLATE" | \
                jq --arg name "$ITEM_NAME" --arg pw "$API_KEY" \
                  '.name = $name | .login.password = $pw | .type = 1' | \
                bw encode | bw create item >/dev/null 2>&1
              if bw get password "$ITEM_NAME" >/dev/null 2>&1; then
                printf "  ${G}+${R} %s saved\n" "$ITEM_LABEL"
              else
                printf "  ${RED}x${R} Failed to save %s - add manually later\n" "$ITEM_LABEL"
              fi
            else
              printf "  ${Y}>${R} Skipped %s\n" "$ITEM_LABEL"
            fi
          fi
        done
        bw sync >/dev/null 2>&1
      fi

      # Enable Bitwarden-backed MCPs in config and re-apply without dropping the selected profile state.
      cat > ~/.config/chezmoi/chezmoi.toml <<TOML
[data]
  user_name = "${USER_NAME}"
  user_role_summary = "${USER_ROLE_SUMMARY}"
  user_stack_summary = "${USER_STACK_SUMMARY}"
  runtime_profile = "${RUNTIME_PROFILE}"
  capability_pack = "${CAPABILITY_PACK}"
  profile_base = "${PROFILE_BASE}"
  custom_enabled_mcps = [$(for i in "${CUSTOM_ENABLED_MCPS[@]}"; do printf '"%s",' "$i"; done | sed 's/,$//')]
  custom_disabled_mcps = []
  custom_enabled_permission_groups = [$(for i in "${CUSTOM_ENABLED_PERMISSION_GROUPS[@]}"; do printf '"%s",' "$i"; done | sed 's/,$//')]
  custom_disabled_permission_groups = []
  enable_api_mcps = true
  memory_provider = "${MEMORY_PROVIDER}"
  obsidian_vault_path = "${OBSIDIAN_VAULT_PATH}"
  azure_devops_org = "${AZURE_DEVOPS_ORG}"
TOML
      printf "\n${B}Re-applying dotfiles with Bitwarden-backed MCPs...${R}\n"
      chezmoi apply
      printf "  ${G}+${R} Bitwarden-backed MCPs configured\n"
    else
      printf "  ${RED}x${R} Failed to unlock vault.\n"
      printf "  Run manually: ${C}bw-login && export BW_SESSION=\$(cat ~/.bw_session) && chezmoi apply${R}\n\n"
    fi
  else
    printf "\n${Y}!${R}  Skipping Bitwarden-backed MCPs - install Bitwarden CLI later and run:\n"
    printf "  ${C}bw-login && export BW_SESSION=\$(cat ~/.bw_session) && chezmoi apply${R}\n\n"
  fi
fi

# --- Done ---
mkdir -p "${HOME}/Dev"

printf "\n${G}+ Done!${R}\n\n"
printf "${B}Verify:${R}\n"
printf "  ${C}claude mcp list${R}            # Claude Code MCPs\n"
printf "  ${C}cat ~/.cursor/mcp.json${R}     # Cursor MCPs\n"
printf "  ${C}cat ~/.codex/config.toml${R}   # Codex config\n"
printf "  ${C}cat ~/.codex/AGENTS.md${R}    # Codex global instructions\n"
printf "  ${C}ls ~/.claude/agents/${R}       # Agents\n\n"
printf "  ${C}bw-login${R}                   # Refresh Bitwarden session file\n\n"
printf "${D}Update later: dotfiles-update${R}\n"
printf "${D}Make sure ~/.local/bin is in your PATH${R}\n"
