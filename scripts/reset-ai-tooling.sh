#!/usr/bin/env bash
set -euo pipefail

# Removes local Claude Code / Claude Desktop / Codex / Cursor state so the
# machine can be treated as if those tools were never installed.
#
# Default mode is dry-run. Pass --yes to actually remove detected files.
# Intended for macOS and Windows via Git Bash.

RUN_MODE="dry-run"
APPDATA="${APPDATA:-}"
LOCALAPPDATA="${LOCALAPPDATA:-}"

case "$(uname -s)" in
  Darwin*) OS_FAMILY="macos" ;;
  MINGW*|MSYS*|CYGWIN*) OS_FAMILY="windows" ;;
  Linux*) OS_FAMILY="linux" ;;
  *) OS_FAMILY="unknown" ;;
esac

C='\033[1;36m'
G='\033[1;32m'
Y='\033[1;33m'
RED='\033[1;31m'
B='\033[1;37m'
D='\033[0;90m'
R='\033[0m'

TARGET_PATHS=()
TARGET_REASONS=()
MANUAL_PATHS=()
MANUAL_REASONS=()
SEEN_PATHS=()

usage() {
  cat <<'EOF'
Usage: reset-ai-tooling.sh [--dry-run] [--yes]

  --dry-run   Preview what would be removed (default)
  --yes       Remove detected files, directories, app bundles, and user-level shims

This script targets local remnants of:
  - Claude Code / Claude Desktop
  - Codex
  - Cursor

It does not remove your dotfiles repo or unrelated package managers.
EOF
}

contains_path() {
  local needle="$1"
  local item
  for item in "${SEEN_PATHS[@]:-}"; do
    [ "$item" = "$needle" ] && return 0
  done
  return 1
}

add_target() {
  local path="$1"
  local reason="$2"
  [ -n "$path" ] || return 0
  [ -e "$path" ] || [ -L "$path" ] || return 0
  if contains_path "$path"; then
    return 0
  fi
  SEEN_PATHS+=("$path")
  TARGET_PATHS+=("$path")
  TARGET_REASONS+=("$reason")
}

add_manual() {
  local path="$1"
  local reason="$2"
  [ -n "$path" ] || return 0
  if contains_path "$path"; then
    return 0
  fi
  SEEN_PATHS+=("$path")
  MANUAL_PATHS+=("$path")
  MANUAL_REASONS+=("$reason")
}

add_glob_targets() {
  local reason="$1"
  shift
  local pattern entry
  shopt -s nullglob
  for pattern in "$@"; do
    for entry in $pattern; do
      add_target "$entry" "$reason"
    done
  done
  shopt -u nullglob
}

command_path() {
  command -v "$1" 2>/dev/null || true
}

realpath_py() {
  python3 - "$1" <<'PY' 2>/dev/null || printf "%s" "$1"
import os, sys
print(os.path.realpath(sys.argv[1]))
PY
}

detect_command_install() {
  local cmd="$1"
  local reason="$2"
  local path
  path="$(command_path "$cmd")"
  [ -n "$path" ] || return 0
  path="$(realpath_py "$path")"

  case "$path" in
    "$HOME"/*)
      add_target "$path" "$reason"
      ;;
    /Applications/*.app/*|"$HOME"/Applications/*.app/*)
      add_manual "$path" "$reason (inside an app bundle; remove the parent app)"
      ;;
    /usr/local/bin/*|/opt/homebrew/bin/*|/opt/homebrew/lib/*)
      add_manual "$path" "$reason (outside home; remove with the package manager that installed it)"
      ;;
    /c/Users/*|/C/Users/*|"$APPDATA"/*|"$LOCALAPPDATA"/*)
      add_target "$path" "$reason"
      ;;
    *)
      add_manual "$path" "$reason (unexpected install path)"
      ;;
  esac
}

kill_processes() {
  case "$OS_FAMILY" in
    macos|linux)
      pkill -x Claude 2>/dev/null || true
      pkill -x Cursor 2>/dev/null || true
      pkill -x codex 2>/dev/null || true
      pkill -f "Claude Code" 2>/dev/null || true
      ;;
    windows)
      taskkill.exe //IM Claude.exe //F >/dev/null 2>&1 || true
      taskkill.exe //IM Cursor.exe //F >/dev/null 2>&1 || true
      taskkill.exe //IM codex.exe //F >/dev/null 2>&1 || true
      taskkill.exe //IM claude.exe //F >/dev/null 2>&1 || true
      ;;
  esac
}

collect_common_targets() {
  add_target "$HOME/.claude" "Claude config and state"
  add_target "$HOME/.claude.json" "Claude CLI MCP state"
  add_target "$HOME/.codex" "Codex config and state"
  add_target "$HOME/.cursor" "Cursor config and state"
  add_target "$HOME/.config/Cursor" "Cursor config"
  add_target "$HOME/.config/Claude" "Claude config"
  add_target "$HOME/.config/Codex" "Codex config"
  add_target "$HOME/.cache/Cursor" "Cursor cache"
  add_target "$HOME/.cache/Claude" "Claude cache"
  add_target "$HOME/.cache/Codex" "Codex cache"

  detect_command_install "claude" "Claude Code CLI shim"
  detect_command_install "codex" "Codex CLI shim"
  detect_command_install "cursor" "Cursor CLI shim"
}

collect_macos_targets() {
  add_target "$HOME/Applications/Claude.app" "Claude Desktop app bundle"
  add_target "$HOME/Applications/Cursor.app" "Cursor app bundle"
  add_target "$HOME/Applications/Claude Code URL Handler.app" "Claude URL handler app bundle"

  if [ -w /Applications ] || [ ! -e /Applications/Claude.app ]; then
    add_target "/Applications/Claude.app" "Claude Desktop app bundle"
    add_target "/Applications/Cursor.app" "Cursor app bundle"
    add_target "/Applications/Claude Code URL Handler.app" "Claude URL handler app bundle"
  else
    [ -e "/Applications/Claude.app" ] && add_manual "/Applications/Claude.app" "Claude Desktop app bundle (requires elevated delete)"
    [ -e "/Applications/Cursor.app" ] && add_manual "/Applications/Cursor.app" "Cursor app bundle (requires elevated delete)"
    [ -e "/Applications/Claude Code URL Handler.app" ] && add_manual "/Applications/Claude Code URL Handler.app" "Claude URL handler app bundle (requires elevated delete)"
  fi

  add_target "$HOME/Library/Application Support/Claude" "Claude Desktop support files"
  add_target "$HOME/Library/Application Support/Cursor" "Cursor support files"

  add_glob_targets "Claude/Cursor cache data" \
    "$HOME/Library/Caches/claude-cli-nodejs" \
    "$HOME/Library/Caches/com.anthropic.claudefordesktop" \
    "$HOME/Library/Caches/com.anthropic.claudefordesktop.ShipIt" \
    "$HOME/Library/Caches/*Cursor*" \
    "$HOME/Library/Caches/*cursor*"

  add_glob_targets "Claude/Cursor logs" \
    "$HOME/Library/Logs/Claude" \
    "$HOME/Library/Logs/*Cursor*" \
    "$HOME/Library/Logs/*cursor*"

  add_glob_targets "Claude/Cursor preferences" \
    "$HOME/Library/Preferences/com.anthropic.claudefordesktop.plist" \
    "$HOME/Library/Preferences/*Cursor*.plist" \
    "$HOME/Library/Preferences/*cursor*.plist"

  add_glob_targets "Claude/Cursor saved application state" \
    "$HOME/Library/Saved Application State/*Claude*" \
    "$HOME/Library/Saved Application State/*Cursor*" \
    "$HOME/Library/Saved Application State/*cursor*"
}

collect_windows_targets() {
  : "${APPDATA:=$HOME/AppData/Roaming}"
  : "${LOCALAPPDATA:=$HOME/AppData/Local}"

  add_target "$APPDATA/Claude" "Claude Desktop roaming data"
  add_target "$APPDATA/Cursor" "Cursor roaming data"
  add_target "$APPDATA/Codex" "Codex roaming data"

  add_glob_targets "Claude/Cursor local app data" \
    "$LOCALAPPDATA/Claude" \
    "$LOCALAPPDATA/Claude*" \
    "$LOCALAPPDATA/Cursor" \
    "$LOCALAPPDATA/Cursor*" \
    "$LOCALAPPDATA/Codex" \
    "$LOCALAPPDATA/Codex*" \
    "$LOCALAPPDATA/Programs/Claude" \
    "$LOCALAPPDATA/Programs/Claude*" \
    "$LOCALAPPDATA/Programs/Cursor" \
    "$LOCALAPPDATA/Programs/Cursor*" \
    "$LOCALAPPDATA/Packages/*Claude*" \
    "$LOCALAPPDATA/Packages/*Cursor*" \
    "$LOCALAPPDATA/Packages/*Codex*"

  add_glob_targets "User-level npm shims" \
    "$APPDATA/npm/claude" \
    "$APPDATA/npm/claude.cmd" \
    "$APPDATA/npm/claude.ps1" \
    "$APPDATA/npm/codex" \
    "$APPDATA/npm/codex.cmd" \
    "$APPDATA/npm/codex.ps1" \
    "$APPDATA/npm/cursor" \
    "$APPDATA/npm/cursor.cmd" \
    "$APPDATA/npm/cursor.ps1"

  add_glob_targets "Desktop and Start Menu shortcuts" \
    "$HOME/Desktop/Claude*.lnk" \
    "$HOME/Desktop/Cursor*.lnk" \
    "$APPDATA/Microsoft/Windows/Start Menu/Programs/Claude*" \
    "$APPDATA/Microsoft/Windows/Start Menu/Programs/Cursor*"
}

print_group() {
  local title="$1"
  shift
  printf "%s%s%s\n" "$B" "$title" "$R"
  if [ "$#" -eq 0 ]; then
    printf "  %snone%s\n" "$D" "$R"
    return
  fi
  local i
  for i in "$@"; do
    printf "  - %s\n" "$i"
  done
}

summarize_targets() {
  local i
  printf "%sDetected cleanup surface%s\n" "$B" "$R"
  printf "  OS family: %s%s%s\n" "$C" "$OS_FAMILY" "$R"
  printf "  Mode: %s%s%s\n\n" "$C" "$RUN_MODE" "$R"

  if [ "${#TARGET_PATHS[@]}" -gt 0 ]; then
    printf "%sRemovable targets%s\n" "$B" "$R"
    for i in "${!TARGET_PATHS[@]}"; do
      printf "  - %s%s%s\n" "$C" "${TARGET_PATHS[$i]}" "$R"
      printf "    %s\n" "${TARGET_REASONS[$i]}"
    done
  else
    printf "%sRemovable targets%s\n  %snone%s\n" "$B" "$R" "$D" "$R"
  fi
  printf "\n"

  if [ "${#MANUAL_PATHS[@]}" -gt 0 ]; then
    printf "%sManual follow-up%s\n" "$B" "$R"
    for i in "${!MANUAL_PATHS[@]}"; do
      printf "  - %s%s%s\n" "$Y" "${MANUAL_PATHS[$i]}" "$R"
      printf "    %s\n" "${MANUAL_REASONS[$i]}"
    done
    printf "\n"
  fi
}

remove_targets() {
  local i path
  kill_processes
  for i in "${!TARGET_PATHS[@]}"; do
    path="${TARGET_PATHS[$i]}"
    if rm -rf -- "$path" 2>/dev/null; then
      printf "  %s+%s removed %s\n" "$G" "$R" "$path"
    else
      printf "  %sx%s failed to remove %s\n" "$RED" "$R" "$path"
    fi
  done
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) RUN_MODE="dry-run" ;;
    --yes) RUN_MODE="delete" ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf "%sUnknown argument:%s %s\n" "$RED" "$R" "$1"
      usage
      exit 1
      ;;
  esac
  shift
done

collect_common_targets
case "$OS_FAMILY" in
  macos) collect_macos_targets ;;
  windows) collect_windows_targets ;;
esac

summarize_targets

if [ "$RUN_MODE" = "dry-run" ]; then
  printf "%sDry-run only.%s Re-run with %s--yes%s to delete the targets above.\n" "$Y" "$R" "$C" "$R"
  exit 0
fi

printf "%sDeleting detected AI tooling state...%s\n" "$B" "$R"
remove_targets

printf "\n%sFinished.%s Re-run with %s--dry-run%s to confirm the machine is clean.\n" "$G" "$R" "$C" "$R"
