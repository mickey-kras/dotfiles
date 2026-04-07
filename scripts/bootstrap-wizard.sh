#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR=""
STATE_FILE=""
PACK_STATE_PY=""
RUNTIME_FILE=""

usage() {
  echo "usage: bootstrap-wizard.sh --source <dir> --state <file>" >&2
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --source)
      SOURCE_DIR="$2"
      shift 2
      ;;
    --state)
      STATE_FILE="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

[ -n "$SOURCE_DIR" ] || usage
[ -n "$STATE_FILE" ] || usage
[ -d "$SOURCE_DIR" ] || usage

PACK_STATE_PY="$SOURCE_DIR/scripts/pack_state.py"
RUNTIME_FILE="$(mktemp)"
exec 3<&0
trap 'rm -f "$RUNTIME_FILE" "$RUNTIME_FILE.settings"' EXIT

# ---------------------------------------------------------------------------
# Try the Terminal.Gui C# wizard first
# ---------------------------------------------------------------------------

if command -v dotnet >/dev/null 2>&1; then
  WIZARD_PROJECT="$SOURCE_DIR/scripts/wizard"
  if [ -f "$WIZARD_PROJECT/DotfilesWizard.csproj" ]; then
    if dotnet run --project "$WIZARD_PROJECT" -- --source "$SOURCE_DIR" --state "$STATE_FILE"; then
      exit 0
    fi
    # If dotnet run failed (user quit or build error), check if state was written
    if [ -s "$STATE_FILE" ]; then
      exit 0
    fi
    printf "Terminal UI unavailable, falling back to plain prompts.\n" >&2
  fi
fi

# ---------------------------------------------------------------------------
# Plain-text fallback (no external TUI dependencies)
# ---------------------------------------------------------------------------

state_init() {
  python3 - "$STATE_FILE" "$SOURCE_DIR" "$PACK_STATE_PY" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

state_path = Path(sys.argv[1])
source_dir = sys.argv[2]
helper = sys.argv[3]

if state_path.exists() and state_path.read_text(encoding="utf-8").strip():
    raise SystemExit(0)

packs = json.loads(subprocess.check_output([sys.executable, helper, "list-packs", source_dir], text=True))
default_pack = packs[0]["id"]
pack = json.loads(subprocess.check_output([sys.executable, helper, "pack", source_dir, default_pack], text=True))
default_profile = pack["defaults"]["profile"]
selection = pack["profiles"][default_profile]["selection"]

state = {
    "capability_pack": default_pack,
    "profile_selected": default_profile,
    "profile_mode": "preset",
    "selection_enabled_mcps": selection["mcps"]["enabled"],
    "selection_enabled_skills": selection["skills"]["enabled"],
    "selection_enabled_agents": selection["agents"]["enabled"],
    "selection_enabled_rules": selection["rules"]["enabled"],
    "selection_enabled_permissions": selection["permissions"]["enabled"],
}
state.update(selection["settings"])
state_path.write_text(json.dumps(state, indent=2), encoding="utf-8")
PY
}

refresh_runtime() {
  python3 "$PACK_STATE_PY" bootstrap-state "$SOURCE_DIR" "$STATE_FILE" > "$RUNTIME_FILE"
}

set_profile() {
  local pack_id="$1"
  local profile_id="$2"
  python3 - "$STATE_FILE" "$SOURCE_DIR" "$PACK_STATE_PY" "$pack_id" "$profile_id" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

state_path = Path(sys.argv[1])
source_dir = sys.argv[2]
helper = sys.argv[3]
pack_id = sys.argv[4]
profile_id = sys.argv[5]

pack = json.loads(subprocess.check_output([sys.executable, helper, "pack", source_dir, pack_id], text=True))
selection = pack["profiles"][profile_id]["selection"]
state = {
    "capability_pack": pack_id,
    "profile_selected": profile_id,
    "profile_mode": "preset",
    "selection_enabled_mcps": selection["mcps"]["enabled"],
    "selection_enabled_skills": selection["skills"]["enabled"],
    "selection_enabled_agents": selection["agents"]["enabled"],
    "selection_enabled_rules": selection["rules"]["enabled"],
    "selection_enabled_permissions": selection["permissions"]["enabled"],
}
state.update(selection["settings"])
state_path.write_text(json.dumps(state, indent=2), encoding="utf-8")
PY
}

set_scalar_value() {
  local key="$1"
  local value="$2"
  python3 - "$STATE_FILE" "$key" "$value" <<'PY'
import json
import sys
from pathlib import Path

state_path = Path(sys.argv[1])
key = sys.argv[2]
value = sys.argv[3]
state = json.loads(state_path.read_text(encoding="utf-8"))
state[key] = value
state_path.write_text(json.dumps(state, indent=2), encoding="utf-8")
PY
}

get_default_profile() {
  local pack_id="$1"
  python3 - "$SOURCE_DIR" "$PACK_STATE_PY" "$pack_id" <<'PY'
import json
import subprocess
import sys
pack = json.loads(subprocess.check_output([sys.executable, sys.argv[2], "pack", sys.argv[1], sys.argv[3]], text=True))
print(pack["defaults"]["profile"])
PY
}

choose_pack() {
  python3 - "$SOURCE_DIR" "$PACK_STATE_PY" <<'PY' >&2
import json
import subprocess
import sys

source_dir = sys.argv[1]
helper = sys.argv[2]
packs = json.loads(subprocess.check_output([sys.executable, helper, "list-packs", source_dir], text=True))
for idx, pack in enumerate(packs, start=1):
    print(f"{idx}. {pack['label']} ({pack['id']}) - {pack['description']}")
PY
  printf "Select capability pack number: " >&2
  read -r selection <&3
  python3 - "$SOURCE_DIR" "$PACK_STATE_PY" "$selection" <<'PY'
import json
import subprocess
import sys

source_dir = sys.argv[1]
helper = sys.argv[2]
selection = int(sys.argv[3])
packs = json.loads(subprocess.check_output([sys.executable, helper, "list-packs", source_dir], text=True))
print(packs[selection - 1]["id"])
PY
}

choose_profile() {
  python3 - "$RUNTIME_FILE" <<'PY' >&2
import json
import sys

runtime = json.load(open(sys.argv[1], encoding="utf-8"))
for idx, (profile_id, profile) in enumerate(runtime["pack"]["profiles"].items(), start=1):
    print(f"{idx}. {profile['label']} ({profile_id}) - {profile['description']}")
PY
  printf "Select profile number: " >&2
  read -r selection <&3
  python3 - "$RUNTIME_FILE" "$selection" <<'PY'
import json
import sys

runtime = json.load(open(sys.argv[1], encoding="utf-8"))
selection = int(sys.argv[2])
profile_ids = list(runtime["pack"]["profiles"].keys())
print(profile_ids[selection - 1])
PY
}

edit_settings() {
  refresh_runtime
  python3 - "$RUNTIME_FILE" <<'PY' > "$RUNTIME_FILE.settings"
import json
import sys

runtime = json.load(open(sys.argv[1], encoding="utf-8"))
schema = runtime["pack"]["settings_schema"]
values = runtime["resolved"]["settings"]
for key, meta in schema.items():
    visible_if = meta.get("visible_if")
    if visible_if and not all(values.get(controller) == expected for controller, expected in visible_if.items()):
        continue
    print(json.dumps({
        "key": key,
        "type": meta["type"],
        "label": meta["label"],
        "value": values.get(key, meta.get("default", "")),
        "options": meta.get("options", []),
    }))
PY
  while IFS= read -r setting; do
    local key type label current value
    key="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["key"])' "$setting")"
    type="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["type"])' "$setting")"
    label="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["label"])' "$setting")"
    current="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["value"])' "$setting")"
    if [ "$type" = "enum" ]; then
      python3 - "$setting" <<'PY' >&2
import json
import sys

data = json.loads(sys.argv[1])
for index, option in enumerate(data["options"], start=1):
    print(f"{index}. {option['label']} ({option['value']})")
PY
      printf "%s [%s]: " "$label" "$current" >&2
      read -r response <&3
      if [ -z "$response" ]; then
        value="$current"
      else
        value="$(python3 -c 'import json,sys; data=json.loads(sys.argv[1]); print(data["options"][int(sys.argv[2])-1]["value"])' "$setting" "$response")"
      fi
    else
      printf "%s [%s]: " "$label" "$current" >&2
      read -r value <&3
      [ -z "$value" ] && value="$current"
    fi
    set_scalar_value "$key" "$value"
  done < "$RUNTIME_FILE.settings"
  rm -f "$RUNTIME_FILE.settings"
}

state_init
refresh_runtime

local_pack_id="$(choose_pack)"
set_profile "$local_pack_id" "$(get_default_profile "$local_pack_id")"
refresh_runtime
local_profile_id="$(choose_profile)"
set_profile "$local_pack_id" "$local_profile_id"
edit_settings
