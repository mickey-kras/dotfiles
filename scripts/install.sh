#!/usr/bin/env bash
set -euo pipefail

# Cross-platform installer for dotfiles-claude
# Works on: macOS, Linux (Debian/Ubuntu/Fedora/Arch), WSL2

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$REPO_DIR/claude"
TARGET="${CLAUDE_HOME:-$HOME/.claude}"
BACKUP="$HOME/.claude-backup-$(date +%Y%m%d-%H%M%S)"

# --- Detect platform ---
detect_platform() {
  case "$(uname -s)" in
    Darwin)  echo "macos" ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
      else
        echo "linux"
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)  echo "windows" ;;
    *)  echo "unknown" ;;
  esac
}

PLATFORM=$(detect_platform)

echo "Claude Code dotfiles installer"
echo "  Platform: $PLATFORM"
echo "  Source:   $SOURCE"
echo "  Target:   $TARGET"
echo ""

# --- Check dependencies ---
MISSING=()
command -v git  >/dev/null 2>&1 || MISSING+=("git")
command -v jq   >/dev/null 2>&1 || MISSING+=("jq")
command -v node >/dev/null 2>&1 || MISSING+=("node")
command -v npx  >/dev/null 2>&1 || MISSING+=("npx")

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "Missing dependencies: ${MISSING[*]}"
  echo ""
  case "$PLATFORM" in
    macos)
      echo "  Install with: brew install ${MISSING[*]}"
      ;;
    linux|wsl)
      # Map tool names to distro package names per package manager.
      # Each manager has its own verified mapping.
      map_pkgs() {
        local mgr="$1"; shift
        local pkgs=()
        for dep in "$@"; do
          case "$mgr" in
            apt-get)
              case "$dep" in
                node|npx) pkgs+=("nodejs" "npm") ;;
                *)        pkgs+=("$dep") ;;
              esac ;;
            dnf)
              case "$dep" in
                node|npx) pkgs+=("nodejs" "npm") ;;
                *)        pkgs+=("$dep") ;;
              esac ;;
            pacman)
              case "$dep" in
                node|npx) pkgs+=("nodejs" "npm") ;;
                *)        pkgs+=("$dep") ;;
              esac ;;
          esac
        done
        # Deduplicate
        printf '%s\n' "${pkgs[@]}" | sort -u | tr '\n' ' '
      }
      if command -v apt-get >/dev/null 2>&1; then
        echo "  Install with: sudo apt-get install -y $(map_pkgs apt-get "${MISSING[@]}")"
      elif command -v dnf >/dev/null 2>&1; then
        echo "  Install with: sudo dnf install -y $(map_pkgs dnf "${MISSING[@]}")"
      elif command -v pacman >/dev/null 2>&1; then
        echo "  Install with: sudo pacman -S $(map_pkgs pacman "${MISSING[@]}")"
      else
        echo "  Install these packages using your system package manager: ${MISSING[*]}"
      fi
      ;;
    windows)
      echo "  Install with: winget install ${MISSING[*]}"
      echo "  Or use: choco install ${MISSING[*]}"
      ;;
  esac
  echo ""
  read -p "Continue anyway? (y/N) " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]] || exit 1
fi

# --- Create target directory ---
mkdir -p "$TARGET"

# --- Symlink config files ---
ITEMS=("CLAUDE.md" "settings.json" ".mcp.json" "rules" "skills" "agents" "hooks")
backed_up=false

for item in "${ITEMS[@]}"; do
  src="$SOURCE/$item"
  dst="$TARGET/$item"

  [ ! -e "$src" ] && continue

  # Back up existing non-symlink files
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    if [ "$backed_up" = false ]; then
      mkdir -p "$BACKUP"
      backed_up=true
      echo "  Backing up existing files to $BACKUP"
    fi
    cp -r "$dst" "$BACKUP/"
    rm -rf "$dst"
  elif [ -L "$dst" ]; then
    rm "$dst"
  fi

  # On Windows/MSYS, symlinks may not work — fall back to copy
  if [ "$PLATFORM" = "windows" ]; then
    cp -r "$src" "$dst"
    echo "  Copied $item -> $dst"
  else
    ln -s "$src" "$dst"
    echo "  Linked $item -> $dst"
  fi
done

# --- Create settings.local.json template if missing ---
if [ ! -f "$TARGET/settings.local.json" ]; then
  cat > "$TARGET/settings.local.json" << 'EOF'
{
  "env": {}
}
EOF
  chmod 600 "$TARGET/settings.local.json"
  echo "  Created settings.local.json template (local-only, gitignored)"
fi

# --- Make hook scripts executable ---
if [ -d "$SOURCE/hooks/scripts" ]; then
  chmod +x "$SOURCE/hooks/scripts/"*.sh 2>/dev/null || true
  echo "  Made hook scripts executable"
fi

# --- Validate JSON files ---
if command -v jq >/dev/null 2>&1; then
  ALL_VALID=true
  for f in settings.json .mcp.json; do
    if [ -f "$SOURCE/$f" ]; then
      if ! jq empty "$SOURCE/$f" 2>/dev/null; then
        echo "  WARNING: $f is invalid JSON!"
        ALL_VALID=false
      fi
    fi
  done
  if [ "$ALL_VALID" = true ]; then
    echo "  JSON validation passed"
  fi
fi

echo ""
echo "Done! $TARGET now points to your dotfiles repo."
echo ""

# --- Prompt for secrets setup ---
if [ -f "$REPO_DIR/scripts/setup-secrets.sh" ]; then
  echo "Run 'scripts/setup-secrets.sh' to configure API keys for this machine."
fi
