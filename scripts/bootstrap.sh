#!/usr/bin/env bash
set -euo pipefail

# One-command bootstrap for macOS / Linux / WSL / Windows (Git Bash)
# Usage: bash <(curl -sL https://raw.githubusercontent.com/mickey-kras/dotfiles/main/scripts/bootstrap.sh)

REPO="mickey-kras/dotfiles"
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
fi

# --- Install .NET SDK if missing (required for the setup wizard TUI) ---
if ! command -v dotnet >/dev/null 2>&1 || ! dotnet --list-sdks 2>/dev/null | grep -q '^10\.'; then
  printf "${Y}>${R} Installing .NET 10 SDK...\n"
  if [[ "$(uname -s)" == "Darwin" ]] && command -v brew >/dev/null 2>&1; then
    brew install dotnet@10 || brew install dotnet || true
  elif is_windows_gitbash && command -v winget.exe >/dev/null 2>&1; then
    winget.exe install -e --id Microsoft.DotNet.SDK.10 --accept-package-agreements --accept-source-agreements || true
  elif is_windows_gitbash && command -v choco >/dev/null 2>&1; then
    choco install dotnet-sdk -y || true
  elif command -v apt-get >/dev/null 2>&1; then
    curl -fsSL https://dot.net/v1/dotnet-install.sh | bash -s -- --channel 10.0 --install-dir "$HOME/.dotnet" || true
    export PATH="$HOME/.dotnet:$PATH"
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y dotnet-sdk-10.0 || true
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm dotnet-sdk || true
  else
    curl -fsSL https://dot.net/v1/dotnet-install.sh | bash -s -- --channel 10.0 --install-dir "$HOME/.dotnet" || true
    export PATH="$HOME/.dotnet:$PATH"
  fi
  if ! command -v dotnet >/dev/null 2>&1; then
    printf "  ${Y}>${R} .NET SDK not available - wizard will fall back to plain prompts\n"
  fi
fi

RUNTIME_PROFILE="full"
CAPABILITY_PACK="software-development"
PROFILE_BASE="full"
USER_NAME=""
USER_ROLE_SUMMARY=""
USER_STACK_SUMMARY=""
MEMORY_PROVIDER="obsidian"
OBSIDIAN_VAULT_PATH=""
STITCH_API_KEY=""
INSTALL_CLAUDE_CODE="disabled"
INSTALL_CODEX="disabled"
INSTALL_CURSOR="disabled"
INSTALL_GEMINI_CLI="disabled"
INSTALL_DROID="disabled"
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

setting_enabled() {
  [ "${1:-disabled}" = "enabled" ]
}

have_claude_code() {
  command -v claude >/dev/null 2>&1
}

have_codex() {
  command -v codex >/dev/null 2>&1
}

have_cursor() {
  if command -v cursor-agent >/dev/null 2>&1 || command -v cursor >/dev/null 2>&1; then
    return 0
  fi
  if [ -d "/Applications/Cursor.app" ]; then
    return 0
  fi
  if is_windows_gitbash && { command -v cursor-agent.exe >/dev/null 2>&1 || command -v cursor.exe >/dev/null 2>&1; }; then
    return 0
  fi
  return 1
}

have_gemini_cli() {
  command -v gemini >/dev/null 2>&1
}

have_droid() {
  command -v droid >/dev/null 2>&1
}

have_obsidian() {
  if [ -d "/Applications/Obsidian.app" ] || command -v obsidian >/dev/null 2>&1; then
    return 0
  fi
  if is_windows_gitbash && command -v obsidian.exe >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

install_claude_code_cli() {
  if have_claude_code; then
    printf "  ${G}+${R} Claude Code already installed\n"
    return 0
  fi

  printf "  ${Y}>${R} Installing Claude Code CLI...\n"
  if is_windows_gitbash && command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -Command "irm https://claude.ai/install.ps1 | iex" >/dev/null 2>&1 || true
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL https://claude.ai/install.sh | bash || true
  elif [[ "$(uname -s)" == "Darwin" ]] && command -v brew >/dev/null 2>&1; then
    brew install --cask claude-code || true
  fi

  if have_claude_code; then
    printf "  ${G}+${R} Claude Code installed\n"
  else
    printf "  ${Y}>${R} Claude Code install did not complete - continue manually if needed\n"
  fi
}

install_codex_cli() {
  if have_codex; then
    printf "  ${G}+${R} Codex already installed\n"
    return 0
  fi

  printf "  ${Y}>${R} Installing Codex CLI...\n"
  if command -v npm >/dev/null 2>&1; then
    npm install -g @openai/codex || true
  elif [[ "$(uname -s)" == "Darwin" ]] && command -v brew >/dev/null 2>&1; then
    brew install --cask codex || true
  fi

  if have_codex; then
    printf "  ${G}+${R} Codex installed\n"
  else
    printf "  ${Y}>${R} Codex install did not complete - continue manually if needed\n"
  fi
}

install_cursor_cli() {
  if have_cursor; then
    printf "  ${G}+${R} Cursor already installed\n"
    return 0
  fi

  printf "  ${Y}>${R} Installing Cursor CLI...\n"
  if command -v curl >/dev/null 2>&1; then
    curl https://cursor.com/install -fsS | bash || true
  elif is_windows_gitbash && command -v winget.exe >/dev/null 2>&1; then
    winget.exe install -e --id Cursor.Cursor --accept-package-agreements --accept-source-agreements || true
  fi

  if have_cursor; then
    printf "  ${G}+${R} Cursor installed\n"
  else
    printf "  ${Y}>${R} Cursor install did not complete - continue manually if needed\n"
  fi
}

install_gemini_cli() {
  if have_gemini_cli; then
    printf "  ${G}+${R} Gemini CLI already installed\n"
    return 0
  fi

  printf "  ${Y}>${R} Installing Gemini CLI...\n"
  if command -v brew >/dev/null 2>&1 && ! is_windows_gitbash; then
    brew install gemini-cli || true
  elif command -v npm >/dev/null 2>&1; then
    npm install -g @google/gemini-cli || true
  fi

  if have_gemini_cli; then
    printf "  ${G}+${R} Gemini CLI installed\n"
  else
    printf "  ${Y}>${R} Gemini CLI install did not complete - continue manually if needed\n"
  fi
}

install_droid_cli() {
  if have_droid; then
    printf "  ${G}+${R} Droid already installed\n"
    return 0
  fi

  printf "  ${Y}>${R} Installing Droid CLI...\n"
  if is_windows_gitbash && command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -Command "irm https://app.factory.ai/cli/windows | iex" >/dev/null 2>&1 || true
  elif command -v curl >/dev/null 2>&1; then
    curl -fsSL https://app.factory.ai/cli | sh || true
  elif command -v npm >/dev/null 2>&1; then
    npm install -g droid || true
  fi

  if have_droid; then
    printf "  ${G}+${R} Droid installed\n"
  else
    printf "  ${Y}>${R} Droid install did not complete - continue manually if needed\n"
  fi
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

detect_existing_obsidian_vault_path() {
  local value=""
  value="$(detect_existing_value obsidian_vault_path)"
  if [ -n "$value" ]; then
    printf "%s" "$value"
    return 0
  fi

  python3 - <<'PY' 2>/dev/null || true
import json
import re
from pathlib import Path

paths = [
    Path.home() / ".gemini" / "settings.json",
    Path.home() / ".factory" / "mcp.json",
    Path.home() / ".claude.json",
    Path.home() / ".cursor" / "mcp.json",
]

for path in paths:
    if not path.exists():
        continue
    try:
        data = json.loads(path.read_text())
    except Exception:
        continue
    servers = data.get("mcpServers") or {}
    for server_name in ("obsidian", "memory"):
        server = servers.get(server_name) or {}
        env = server.get("env") or {}
        vault_path = env.get("OBSIDIAN_VAULT_PATH")
        if vault_path:
            print(vault_path)
            raise SystemExit(0)

toml_path = Path.home() / ".codex" / "config.toml"
if toml_path.exists():
    match = re.search(r'OBSIDIAN_VAULT_PATH\s*=\s*"([^"]+)"', toml_path.read_text(errors="ignore"))
    if match:
        print(match.group(1))
        raise SystemExit(0)

mac_default = Path.home() / "Library" / "Mobile Documents" / "iCloud~md~obsidian" / "Documents" / "memory-vault"
if (mac_default.parent).exists():
    print(str(mac_default))
    raise SystemExit(0)

print(str(Path.home() / "Obsidian" / "memory-vault"))
PY
}

detect_existing_stitch_api_key() {
  local value=""
  value="$(detect_existing_value stitch_api_key)"
  if [ -n "$value" ]; then
    printf "%s" "$value"
    return 0
  fi

  python3 - <<'PY' 2>/dev/null || true
import json
from pathlib import Path

paths = [
    Path.home() / ".gemini" / "settings.json",
    Path.home() / ".factory" / "mcp.json",
]

for path in paths:
    if not path.exists():
        continue
    try:
        data = json.loads(path.read_text())
    except Exception:
        continue
    server = (data.get("mcpServers") or {}).get("stitch") or {}
    headers = server.get("headers") or {}
    api_key = headers.get("X-Goog-Api-Key")
    if api_key:
        print(api_key)
        raise SystemExit(0)
PY
}

detect_existing_server_env_secret() {
  local server_name="$1"
  local env_name="$2"
  python3 - "$server_name" "$env_name" <<'PY' 2>/dev/null || true
import json
import re
import sys
from pathlib import Path

server_name = sys.argv[1]
env_name = sys.argv[2]

json_paths = [
    Path.home() / ".claude.json",
    Path.home() / ".gemini" / "settings.json",
    Path.home() / ".factory" / "mcp.json",
]

for path in json_paths:
    if not path.exists():
        continue
    try:
        data = json.loads(path.read_text())
    except Exception:
        continue
    server = (data.get("mcpServers") or {}).get(server_name) or {}
    env = server.get("env") or {}
    value = env.get(env_name)
    if value:
        print(value)
        raise SystemExit(0)

toml_path = Path.home() / ".codex" / "config.toml"
if toml_path.exists():
    text = toml_path.read_text(errors="ignore")
    pattern = re.compile(
        rf'\[mcp_servers\.{re.escape(server_name)}\](?P<body>.*?)(?:\n\[|\Z)',
        re.S,
    )
    match = pattern.search(text)
    if match:
        env_match = re.search(
            rf'{re.escape(env_name)}\s*=\s*"([^"]+)"',
            match.group('body'),
        )
        if env_match:
            print(env_match.group(1))
            raise SystemExit(0)
PY
}

detect_existing_obsidian_api_key() {
  local value=""
  value="$(detect_existing_server_env_secret obsidian OBSIDIAN_API_KEY)"
  if [ -n "$value" ]; then
    printf "%s" "$value"
    return 0
  fi

  python3 - <<'PY' 2>/dev/null || true
import json
from pathlib import Path

path = Path.home() / "Library" / "Mobile Documents" / "iCloud~md~obsidian" / "Documents" / "memory-vault" / ".obsidian" / "plugins" / "obsidian-local-rest-api" / "data.json"
if path.exists():
    data = json.loads(path.read_text())
    value = data.get("apiKey")
    if value:
        print(value)
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
  python3 - "$CONFIG_STATE_JSON" "$USER_NAME" "$USER_ROLE_SUMMARY" "$USER_STACK_SUMMARY" "$MEMORY_PROVIDER" "$OBSIDIAN_VAULT_PATH" "$INSTALL_CLAUDE_CODE" "$INSTALL_CODEX" "$INSTALL_CURSOR" "$INSTALL_GEMINI_CLI" "$INSTALL_DROID" "$STITCH_API_KEY" > "$HOME/.config/chezmoi/chezmoi.toml" <<'PY'
import json
import sys
from pathlib import Path

config = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
config["user_name"] = sys.argv[2]
config["user_role_summary"] = sys.argv[3]
config["user_stack_summary"] = sys.argv[4]
config["memory_provider"] = sys.argv[5]
config["obsidian_vault_path"] = sys.argv[6]
config["install_claude_code"] = sys.argv[7]
config["install_codex"] = sys.argv[8]
config["install_cursor"] = sys.argv[9]
config["install_gemini_cli"] = sys.argv[10]
config["install_droid"] = sys.argv[11]
config["stitch_api_key"] = sys.argv[12]

order = [
    "user_name",
    "user_role_summary",
    "user_stack_summary",
    "selection_enabled_mcps",
    "selection_enabled_skills",
    "selection_enabled_agents",
    "selection_enabled_rules",
    "selection_enabled_permissions",
    "memory_provider",
    "obsidian_vault_path",
    "install_claude_code",
    "install_codex",
    "install_cursor",
    "install_gemini_cli",
    "install_droid",
    "stitch_api_key",
    "bw_gate_install",
]

bool_keys = set()

def toml_quote(value):
    return json.dumps(value)

def toml_array(values):
    return "[" + ",".join(json.dumps(value) for value in values) + "]"

print("[data]")
for key in order:
    value = config.get(key, "")
    if key in bool_keys:
        print(f"  {key} = {'true' if value else 'false'}")
    elif isinstance(value, list):
        print(f"  {key} = {toml_array(value)}")
    else:
        print(f"  {key} = {toml_quote(value)}")
PY
}

prepare_bootstrap_source

STATE_FILE="$(mktemp)"
CONFIG_STATE_JSON="$(mktemp)"
trap 'rm -f "$STATE_FILE" "$CONFIG_STATE_JSON"' EXIT

bash "$BOOTSTRAP_SOURCE/scripts/bootstrap-wizard.sh" --source "$BOOTSTRAP_SOURCE" --state "$STATE_FILE"

python3 "$BOOTSTRAP_SOURCE/scripts/pack_state.py" legacy-config "$BOOTSTRAP_SOURCE" "$STATE_FILE" > "$CONFIG_STATE_JSON"

MEMORY_PROVIDER="$(json_value "$CONFIG_STATE_JSON" memory_provider)"
OBSIDIAN_VAULT_PATH="$(json_value "$CONFIG_STATE_JSON" obsidian_vault_path)"
INSTALL_CLAUDE_CODE="$(json_value "$CONFIG_STATE_JSON" install_claude_code)"
INSTALL_CODEX="$(json_value "$CONFIG_STATE_JSON" install_codex)"
INSTALL_CURSOR="$(json_value "$CONFIG_STATE_JSON" install_cursor)"
INSTALL_GEMINI_CLI="$(json_value "$CONFIG_STATE_JSON" install_gemini_cli)"
INSTALL_DROID="$(json_value "$CONFIG_STATE_JSON" install_droid)"
STITCH_API_KEY="$(json_value "$CONFIG_STATE_JSON" stitch_api_key)"

EFFECTIVE_MCPS=()
while IFS= read -r line; do
  [ -n "$line" ] && EFFECTIVE_MCPS+=("$line")
done < <(json_array_lines "$CONFIG_STATE_JSON" selection_enabled_mcps)

# User profile fields now come from the wizard Settings tab
USER_NAME="$(json_value "$CONFIG_STATE_JSON" user_name 2>/dev/null || true)"
USER_ROLE_SUMMARY="$(json_value "$CONFIG_STATE_JSON" user_role_summary 2>/dev/null || true)"
USER_STACK_SUMMARY="$(json_value "$CONFIG_STATE_JSON" user_stack_summary 2>/dev/null || true)"

if [ -z "$USER_NAME" ]; then
  USER_NAME="$(whoami)"
fi

if [ -z "$OBSIDIAN_VAULT_PATH" ]; then
  OBSIDIAN_VAULT_PATH="$(detect_existing_obsidian_vault_path)"
fi

if [ "$MEMORY_PROVIDER" = "obsidian" ] && [ -z "$OBSIDIAN_VAULT_PATH" ]; then
  printf "  ${Y}>${R} Obsidian selected without a vault path - falling back to builtin memory\n"
  MEMORY_PROVIDER="builtin"
fi

if [ -z "$STITCH_API_KEY" ]; then
  STITCH_API_KEY="$(detect_existing_stitch_api_key)"
fi

printf "\n${B}Planned configuration${R}\n"
printf "  Display name: ${C}%s${R}\n" "$USER_NAME"
printf "  Role: ${D}%s${R}\n" "$USER_ROLE_SUMMARY"
printf "  Stack: ${D}%s${R}\n" "$USER_STACK_SUMMARY"
printf "  Memory provider: ${C}%s${R}\n" "$MEMORY_PROVIDER"
if [ "$MEMORY_PROVIDER" = "obsidian" ] && [ -n "$OBSIDIAN_VAULT_PATH" ]; then
  printf "  Obsidian vault: ${D}%s${R}\n" "$OBSIDIAN_VAULT_PATH"
fi
if [ -n "$STITCH_API_KEY" ]; then
  printf "  Stitch API key: ${D}configured${R}\n"
else
  printf "  Stitch API key: ${D}not configured${R}\n"
fi
OPTIONAL_INSTALLS=()
if setting_enabled "$INSTALL_CLAUDE_CODE"; then OPTIONAL_INSTALLS+=("claude"); fi
if setting_enabled "$INSTALL_CODEX"; then OPTIONAL_INSTALLS+=("codex"); fi
if setting_enabled "$INSTALL_CURSOR"; then OPTIONAL_INSTALLS+=("cursor"); fi
if setting_enabled "$INSTALL_GEMINI_CLI"; then OPTIONAL_INSTALLS+=("gemini"); fi
if setting_enabled "$INSTALL_DROID"; then OPTIONAL_INSTALLS+=("droid"); fi
if [ ${#OPTIONAL_INSTALLS[@]} -gt 0 ]; then
  printf "  Optional installs: ${D}%s${R}\n" "$(join_by ', ' "${OPTIONAL_INSTALLS[@]}")"
else
  printf "  Optional installs: ${D}none${R}\n"
fi
NEEDS_BITWARDEN=false
if contains_word github "${EFFECTIVE_MCPS[@]}" || contains_word aws "${EFFECTIVE_MCPS[@]}" || contains_word tailscale "${EFFECTIVE_MCPS[@]}" || contains_word obsidian "${EFFECTIVE_MCPS[@]}" || contains_word magic "${EFFECTIVE_MCPS[@]}" || contains_word replicate "${EFFECTIVE_MCPS[@]}"; then
  NEEDS_BITWARDEN=true
fi
printf "  Effective MCPs: ${D}%s${R}\n" "$(join_by ', ' "${EFFECTIVE_MCPS[@]}")"

MISSING=()
command -v git  >/dev/null 2>&1 || MISSING+=("git")
command -v node >/dev/null 2>&1 || MISSING+=("node")
command -v npx  >/dev/null 2>&1 || MISSING+=("npx")
if contains_word http "${EFFECTIVE_MCPS[@]}" || contains_word aws "${EFFECTIVE_MCPS[@]}"; then
  command -v uvx >/dev/null 2>&1 || MISSING+=("uvx")
fi
if contains_word firebase "${EFFECTIVE_MCPS[@]}"; then
  command -v firebase >/dev/null 2>&1 || MISSING+=("firebase")
fi

if [ ${#MISSING[@]} -gt 0 ]; then
  printf "  ${Y}>${R} Missing tools: ${MISSING[*]}\n"
  if contains_word uvx "${MISSING[@]}"; then
    printf "  ${D}uvx is only needed when the selected MCP set includes http or aws.${R}\n"
  fi
fi

printf "\n"

# --- Optional tool installs ---
printf "${B}Installing selected tools${R}\n"
if setting_enabled "$INSTALL_CLAUDE_CODE"; then
  install_claude_code_cli
fi
if setting_enabled "$INSTALL_CODEX"; then
  install_codex_cli
fi
if setting_enabled "$INSTALL_CURSOR"; then
  install_cursor_cli
fi
if setting_enabled "$INSTALL_GEMINI_CLI"; then
  install_gemini_cli
fi
if setting_enabled "$INSTALL_DROID"; then
  install_droid_cli
fi
if [ "$MEMORY_PROVIDER" = "obsidian" ] && ! have_obsidian; then
  printf "  ${D}Obsidian will be installed during chezmoi apply if it is still missing.${R}\n"
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
      BW_ITEMS=()
      if contains_word magic "${EFFECTIVE_MCPS[@]}"; then
        BW_ITEMS+=("magic-api-key:Magic:https://21st.dev")
      fi
      if contains_word replicate "${EFFECTIVE_MCPS[@]}"; then
        BW_ITEMS+=("replicate-api-token:Replicate:https://replicate.com")
      fi
      if contains_word obsidian "${EFFECTIVE_MCPS[@]}"; then
        BW_ITEMS+=("Obsidian Local REST API:Obsidian Local REST API:https://127.0.0.1:27124")
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
        printf "  ${D}Create free accounts or reuse the existing local config and paste any missing keys below.${R}\n"
        printf "  ${D}Press Enter to skip any service.${R}\n\n"
        for entry in "${BW_ITEMS[@]}"; do
          ITEM_NAME="${entry%%:*}"
          REST="${entry#*:}"
          ITEM_LABEL="${REST%%:*}"
          ITEM_URL="${REST#*:}"
          if bw get password "$ITEM_NAME" >/dev/null 2>&1; then
            printf "  ${G}+${R} %s - already configured\n" "$ITEM_LABEL"
          else
            EXISTING_SECRET=""
            case "$ITEM_NAME" in
              magic-api-key)
                EXISTING_SECRET="$(detect_existing_server_env_secret magic API_KEY)"
                ;;
              replicate-api-token)
                EXISTING_SECRET="$(detect_existing_server_env_secret replicate REPLICATE_API_TOKEN)"
                ;;
              "Obsidian Local REST API")
                EXISTING_SECRET="$(detect_existing_obsidian_api_key)"
                ;;
            esac

            if [ -n "$EXISTING_SECRET" ]; then
              TEMPLATE=$(bw get template item)
              echo "$TEMPLATE" | \
                jq --arg name "$ITEM_NAME" --arg pw "$EXISTING_SECRET" \
                  '.name = $name | .login.password = $pw | .type = 1' | \
                bw encode | bw create item >/dev/null 2>&1
              if bw get password "$ITEM_NAME" >/dev/null 2>&1; then
                printf "  ${G}+${R} %s imported from existing local config\n" "$ITEM_LABEL"
                continue
              fi
            fi

            printf "  ${C}%s${R} ${D}(%s)${R}\n" "$ITEM_LABEL" "$ITEM_URL"
            printf "  API key: "
            read -rs API_KEY
            printf "\n"
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
      # The run_onchange_ install scripts hash their own rendered content,
      # which doesn't depend on whether Bitwarden is unlocked - so chezmoi
      # would normally skip them on the second apply and secret-backed MCPs
      # would never register. Clear the specific entryState entries so the
      # managed install scripts rerun exactly once with secrets available.
      for script_entry in install-claude-mcps.sh install-claude-pack-assets.sh install-managed-skills.sh install-bw-gate.sh install-obsidian.sh; do
        chezmoi state delete --bucket=entryState --key="$HOME/scripts/chezmoi/$script_entry" >/dev/null 2>&1 || true
      done
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
