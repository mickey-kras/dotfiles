#!/usr/bin/env bash
set -euo pipefail

# One-command bootstrap for macOS / Linux / WSL / Windows (Git Bash)
# Usage: bash <(curl -sL https://raw.githubusercontent.com/mickey-kras/dotfiles/main/scripts/bootstrap.sh)

REPO="mickey-kras/dotfiles"
GUM_BIN=""
BOOTSTRAP_SOURCE=""
BOOTSTRAP_TEMP_SOURCE=""
STATE_FILE=""
CONFIG_STATE_JSON=""

is_windows_gitbash() {
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) return 0 ;;
    *) return 1 ;;
  esac
}

resolve_gum_bin() {
  local resolved="" resolved_dir="" candidate="" search_root=""
  if command -v gum >/dev/null 2>&1; then
    GUM_BIN="$(command -v gum)"
    return 0
  fi

  if is_windows_gitbash; then
    if command -v where.exe >/dev/null 2>&1; then
      resolved="$(where.exe gum.exe 2>/dev/null | tr -d '\r' | head -n1 || true)"
      if [ -n "$resolved" ]; then
        resolved_dir="$(dirname "$resolved")"
        PATH="$resolved_dir:$PATH"
        export PATH
        GUM_BIN="$resolved"
        return 0
      fi
    fi

    for candidate in \
      "${LOCALAPPDATA:-}/Microsoft/WinGet/Links/gum.exe" \
      "${LOCALAPPDATA:-}/Microsoft/WindowsApps/gum.exe" \
      "${USERPROFILE:-}/AppData/Local/Microsoft/WinGet/Links/gum.exe" \
      "${USERPROFILE:-}/AppData/Local/Microsoft/WindowsApps/gum.exe"
    do
      if [ -n "$candidate" ] && [ -x "$candidate" ]; then
        resolved_dir="$(dirname "$candidate")"
        PATH="$resolved_dir:$PATH"
        export PATH
        GUM_BIN="$candidate"
        return 0
      fi
    done

    for search_root in \
      "${LOCALAPPDATA:-}/Microsoft/WinGet/Packages" \
      "${USERPROFILE:-}/AppData/Local/Microsoft/WinGet/Packages" \
      "/c/Program Files/WinGet/Packages"
    do
      if [ -d "$search_root" ]; then
        resolved="$(find "$search_root" -type f -iname 'gum.exe' 2>/dev/null | head -n1 || true)"
        if [ -n "$resolved" ]; then
          resolved_dir="$(dirname "$resolved")"
          PATH="$resolved_dir:$PATH"
          export PATH
          GUM_BIN="$resolved"
          return 0
        fi
      fi
    done
  fi

  GUM_BIN=""
  return 1
}

install_gum_if_supported() {
  if resolve_gum_bin; then
    return 0
  fi

  printf "${Y}>${R} Installing gum for interactive setup...\n"
  if [[ "$(uname -s)" == "Darwin" ]] && command -v brew >/dev/null 2>&1; then
    brew install gum || true
  elif is_windows_gitbash && command -v winget.exe >/dev/null 2>&1; then
    winget.exe install -e --id charmbracelet.gum --accept-package-agreements --accept-source-agreements || true
  elif is_windows_gitbash && command -v choco >/dev/null 2>&1; then
    choco install gum -y || true
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm gum || true
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y gum || true
  fi

  if resolve_gum_bin; then
    printf "  ${G}+${R} gum installed\n"
    return 0
  fi

  printf "  ${Y}>${R} gum unavailable - falling back to plain prompts\n"
  return 1
}

prepare_bootstrap_source() {
  local script_dir="" repo_root=""
  script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  repo_root="$(CDPATH= cd -- "$script_dir/.." && pwd)"
  if [ -d "$repo_root/packs" ] && [ -f "$repo_root/scripts/bootstrap-wizard.sh" ]; then
    BOOTSTRAP_SOURCE="$repo_root"
    return 0
  fi

  if ! command -v git >/dev/null 2>&1; then
    printf "  ${RED}x${R} git is required to load pack metadata for setup.\n"
    exit 1
  fi

  BOOTSTRAP_TEMP_SOURCE="$(mktemp -d)"
  if git clone --depth 1 "https://github.com/${REPO}.git" "$BOOTSTRAP_TEMP_SOURCE" >/dev/null 2>&1; then
    BOOTSTRAP_SOURCE="$BOOTSTRAP_TEMP_SOURCE"
    return 0
  fi

  printf "  ${RED}x${R} Failed to fetch dotfiles source for setup.\n"
  exit 1
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
USER_NAME=""
USER_ROLE_SUMMARY=""
USER_STACK_SUMMARY=""
MEMORY_PROVIDER="builtin"
OBSIDIAN_VAULT_PATH=""
CONTENT_WORKSPACE=""
CUSTOM_ENABLED_MCPS=()
CUSTOM_DISABLED_MCPS=()
CUSTOM_ENABLED_PERMISSION_GROUPS=()
CUSTOM_DISABLED_PERMISSION_GROUPS=()

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

detect_existing_azdo_org() {
  local value=""
  value="$(detect_existing_value azure_devops_org)"
  if [ -n "$value" ]; then
    printf "%s" "$value"
    return 0
  fi

  python3 - <<'PY' 2>/dev/null || true
import re
from pathlib import Path

paths = [
    Path.home() / ".codex" / "config.toml",
    Path.home() / ".cursor" / "mcp.json",
    Path.home() / ".claude.json",
]

patterns = [
    re.compile(r'@azure-devops/mcp@[^"]*"\s*,\s*"([^"]+)"'),
    re.compile(r'"azure-devops"\s*:\s*\{.*?"args"\s*:\s*\[[^\]]*"([^"]+)"\s*\]', re.S),
]

for path in paths:
    if not path.exists():
        continue
    text = path.read_text(errors="ignore")
    for pattern in patterns:
        match = pattern.search(text)
        if match and match.group(1):
            print(match.group(1))
            raise SystemExit(0)
PY
}

json_value() {
  local file="$1"
  local key="$2"
  python3 - "$file" "$key" <<'PY'
import json
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
value = data[sys.argv[2]]
if isinstance(value, bool):
    print("true" if value else "false")
elif value is None:
    print("")
else:
    print(value)
PY
}

json_array_lines() {
  local file="$1"
  local key="$2"
  python3 - "$file" "$key" <<'PY'
import json
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
for item in data.get(sys.argv[2], []):
    print(item)
PY
}

write_chezmoi_config() {
  python3 - "$CONFIG_STATE_JSON" "$USER_NAME" "$USER_ROLE_SUMMARY" "$USER_STACK_SUMMARY" > "$HOME/.config/chezmoi/chezmoi.toml" <<'PY'
import json
import sys
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
config["user_name"] = sys.argv[2]
config["user_role_summary"] = sys.argv[3]
config["user_stack_summary"] = sys.argv[4]

order = [
    "user_name",
    "user_role_summary",
    "user_stack_summary",
    "runtime_profile",
    "capability_pack",
    "profile_base",
    "profile_selected",
    "profile_mode",
    "custom_enabled_mcps",
    "custom_disabled_mcps",
    "custom_enabled_permission_groups",
    "custom_disabled_permission_groups",
    "selection_enabled_mcps",
    "selection_enabled_skills",
    "selection_enabled_agents",
    "selection_enabled_rules",
    "selection_enabled_permissions",
    "memory_provider",
    "obsidian_vault_path",
    "azure_devops_org",
    "content_workspace",
]

def toml_quote(value):
    return json.dumps(value)

def toml_array(values):
    return "[" + ",".join(json.dumps(value) for value in values) + "]"

print("[data]")
for key in order:
    value = config.get(key, "")
    if isinstance(value, list):
        print(f"  {key} = {toml_array(value)}")
    else:
        print(f"  {key} = {toml_quote(value)}")
PY
}

install_gum_if_supported || true
prepare_bootstrap_source

STATE_FILE="$(mktemp)"
CONFIG_STATE_JSON="$(mktemp)"

if [ -n "$GUM_BIN" ]; then
  bash "$BOOTSTRAP_SOURCE/scripts/bootstrap-wizard.sh" --source "$BOOTSTRAP_SOURCE" --state "$STATE_FILE" --gum "$GUM_BIN"
else
  bash "$BOOTSTRAP_SOURCE/scripts/bootstrap-wizard.sh" --source "$BOOTSTRAP_SOURCE" --state "$STATE_FILE"
fi

python3 "$BOOTSTRAP_SOURCE/scripts/pack_state.py" legacy-config "$BOOTSTRAP_SOURCE" "$STATE_FILE" > "$CONFIG_STATE_JSON"

RUNTIME_PROFILE="$(json_value "$CONFIG_STATE_JSON" runtime_profile)"
CAPABILITY_PACK="$(json_value "$CONFIG_STATE_JSON" capability_pack)"
PROFILE_BASE="$(json_value "$CONFIG_STATE_JSON" profile_base)"
MEMORY_PROVIDER="$(json_value "$CONFIG_STATE_JSON" memory_provider)"
OBSIDIAN_VAULT_PATH="$(json_value "$CONFIG_STATE_JSON" obsidian_vault_path)"
AZURE_DEVOPS_ORG="$(json_value "$CONFIG_STATE_JSON" azure_devops_org)"
CONTENT_WORKSPACE="$(json_value "$CONFIG_STATE_JSON" content_workspace)"
mapfile -t CUSTOM_ENABLED_MCPS < <(json_array_lines "$CONFIG_STATE_JSON" custom_enabled_mcps)
mapfile -t CUSTOM_DISABLED_MCPS < <(json_array_lines "$CONFIG_STATE_JSON" custom_disabled_mcps)
mapfile -t CUSTOM_ENABLED_PERMISSION_GROUPS < <(json_array_lines "$CONFIG_STATE_JSON" custom_enabled_permission_groups)
mapfile -t CUSTOM_DISABLED_PERMISSION_GROUPS < <(json_array_lines "$CONFIG_STATE_JSON" custom_disabled_permission_groups)
mapfile -t EFFECTIVE_MCPS < <(json_array_lines "$CONFIG_STATE_JSON" selection_enabled_mcps)
mapfile -t EFFECTIVE_PERMISSION_GROUPS < <(json_array_lines "$CONFIG_STATE_JSON" selection_enabled_permissions)

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
  if [ -n "$GUM_BIN" ]; then
    if "$GUM_BIN" confirm "Reuse existing display name '${EXISTING_NAME}'?"; then
      USER_NAME="$EXISTING_NAME"
    fi
  else
    printf "${B}Reuse existing display name '${EXISTING_NAME}'? [Y/n]: ${R}"
    read -r REUSE_NAME
    if [ -z "$REUSE_NAME" ] || [ "$REUSE_NAME" = "y" ] || [ "$REUSE_NAME" = "Y" ]; then
      USER_NAME="$EXISTING_NAME"
    fi
  fi
fi

if [ -z "$USER_NAME" ]; then
  if [ -n "$GUM_BIN" ]; then
    USER_NAME="$("$GUM_BIN" input --header "Display name for generated instructions" --value "$USER_NAME")"
  else
    printf "${B}Display name for generated instructions: ${R}"
    read -r USER_NAME
  fi
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
if [ -n "$GUM_BIN" ]; then
  USER_ROLE_SUMMARY="$("$GUM_BIN" input --header "Role summary" --value "$USER_ROLE_SUMMARY")"
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
if [ -n "$GUM_BIN" ]; then
  USER_STACK_SUMMARY="$("$GUM_BIN" input --header "Stack summary" --value "$USER_STACK_SUMMARY")"
else
  printf "${B}Stack summary [%s]: ${R}" "$USER_STACK_SUMMARY"
  read -r STACK_INPUT
  [ -n "$STACK_INPUT" ] && USER_STACK_SUMMARY="$STACK_INPUT"
fi

EXISTING_AZDO="$(detect_existing_azdo_org)"
if [ -n "$EXISTING_AZDO" ]; then
  AZURE_DEVOPS_ORG="$EXISTING_AZDO"
fi
if [ -n "$GUM_BIN" ]; then
  AZURE_DEVOPS_ORG="$("$GUM_BIN" input --header "Azure DevOps org name (optional)" --value "$AZURE_DEVOPS_ORG")"
else
  printf "${B}Azure DevOps org name [%s]: ${R}" "$AZURE_DEVOPS_ORG"
  read -r AZDO_INPUT
  [ -n "$AZDO_INPUT" ] && AZURE_DEVOPS_ORG="$AZDO_INPUT"
fi
python3 - "$CONFIG_STATE_JSON" "$AZURE_DEVOPS_ORG" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
data["azure_devops_org"] = sys.argv[2]
path.write_text(json.dumps(data, indent=2), encoding="utf-8")
PY

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
if [ -n "$CONTENT_WORKSPACE" ]; then
  printf "  Content workspace: ${D}%s${R}\n" "$CONTENT_WORKSPACE"
fi
if [ "$RUNTIME_PROFILE" = "custom" ]; then
  printf "  Custom base: ${C}%s${R}\n" "$PROFILE_BASE"
  printf "  Custom enabled MCPs: ${D}%s${R}\n" "$(join_by ', ' "${CUSTOM_ENABLED_MCPS[@]}")"
  printf "  Custom enabled permission groups: ${D}%s${R}\n" "$(join_by ', ' "${CUSTOM_ENABLED_PERMISSION_GROUPS[@]}")"
fi
NEEDS_BITWARDEN=false
if contains_word github "${EFFECTIVE_MCPS[@]}" || contains_word aws "${EFFECTIVE_MCPS[@]}" || contains_word tailscale "${EFFECTIVE_MCPS[@]}" || contains_word exa "${EFFECTIVE_MCPS[@]}" || contains_word firecrawl "${EFFECTIVE_MCPS[@]}" || contains_word fal-ai "${EFFECTIVE_MCPS[@]}"; then
  NEEDS_BITWARDEN=true
fi
printf "  Effective MCPs: ${D}%s${R}\n" "$(join_by ', ' "${EFFECTIVE_MCPS[@]}")"
printf "  Permission groups: ${D}%s${R}\n" "$(join_by ', ' "${EFFECTIVE_PERMISSION_GROUPS[@]}")"

MISSING=()
command -v git  >/dev/null 2>&1 || MISSING+=("git")
command -v node >/dev/null 2>&1 || MISSING+=("node")
command -v npx  >/dev/null 2>&1 || MISSING+=("npx")
if contains_word http "${EFFECTIVE_MCPS[@]}" || contains_word aws "${EFFECTIVE_MCPS[@]}"; then
  command -v uvx >/dev/null 2>&1 || MISSING+=("uvx")
fi

if [ ${#MISSING[@]} -gt 0 ]; then
  printf "  ${Y}>${R} Missing tools: ${MISSING[*]}\n"
  if contains_word uvx "${MISSING[@]}"; then
    printf "  ${D}uvx is only needed for MCPs in profiles that include http or aws.${R}\n"
  fi
fi

if [ -n "$GUM_BIN" ]; then
  "$GUM_BIN" confirm "Apply this profile?" || exit 0
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
write_chezmoi_config
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

# --- Bitwarden setup (if selected MCPs need Bitwarden) ---
if [ "$NEEDS_BITWARDEN" = "true" ]; then
  if ! command -v bw >/dev/null 2>&1; then
    printf "\n${B}Bitwarden CLI required for Bitwarden-backed MCPs${R}\n"
    BW_INSTALL="y"
    if [ -n "$GUM_BIN" ]; then
      "$GUM_BIN" confirm "Install Bitwarden CLI now?" || BW_INSTALL="n"
    else
      printf "${B}Install now? [Y/n]: ${R}"
      read -r BW_INSTALL
    fi
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
      BW_ITEMS=()
      if contains_word exa "${EFFECTIVE_MCPS[@]}"; then
        BW_ITEMS+=("exa-api-key:Exa:https://exa.ai")
      fi
      if contains_word firecrawl "${EFFECTIVE_MCPS[@]}"; then
        BW_ITEMS+=("firecrawl-api-key:Firecrawl:https://firecrawl.dev")
      fi
      if contains_word fal-ai "${EFFECTIVE_MCPS[@]}"; then
        BW_ITEMS+=("fal-api-key:fal.ai:https://fal.ai")
      fi
      ITEMS_MISSING=false
      if [ ${#BW_ITEMS[@]} -gt 0 ]; then
        for entry in "${BW_ITEMS[@]}"; do
          ITEM_NAME="${entry%%:*}"
          if ! bw get password "$ITEM_NAME" >/dev/null 2>&1; then
            ITEMS_MISSING=true
            break
          fi
        done
      fi

      if [ "$ITEMS_MISSING" = "true" ] && [ ${#BW_ITEMS[@]} -gt 0 ]; then
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

      # Re-apply without dropping the selected profile state once Bitwarden is ready.
      write_chezmoi_config
      printf "\n${B}Re-applying dotfiles with Bitwarden-backed MCPs...${R}\n"
      chezmoi apply
      printf "  ${G}+${R} Bitwarden-backed MCPs configured\n"
    else
      printf "  ${RED}x${R} Failed to unlock vault.\n"
      printf "  bw-login should prompt for your Bitwarden master password and write ~/.bw_session.\n"
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
