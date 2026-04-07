#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR=""
STATE_FILE=""
GUM_BIN="${GUM_BIN:-}"
PACK_STATE_PY=""
RUNTIME_FILE=""

usage() {
  echo "usage: bootstrap-wizard.sh --source <dir> --state <file> [--gum <path>]" >&2
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
    --gum)
      GUM_BIN="$2"
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
trap 'rm -f "$RUNTIME_FILE"' EXIT

have_gum() {
  [ -n "$GUM_BIN" ] && [ -x "$GUM_BIN" ]
}

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

snap_profile_if_needed() {
  python3 - "$STATE_FILE" "$RUNTIME_FILE" <<'PY'
import json
import sys
from pathlib import Path

state_path = Path(sys.argv[1])
runtime_path = Path(sys.argv[2])
state = json.loads(state_path.read_text(encoding="utf-8"))
runtime = json.loads(runtime_path.read_text(encoding="utf-8"))
matched = runtime["matched_profile"]
if matched:
    state["profile_selected"] = matched
    state["profile_mode"] = "preset"
else:
    state["profile_mode"] = "custom"
state_path.write_text(json.dumps(state, indent=2), encoding="utf-8")
PY
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

set_array_value() {
  local key="$1"
  shift
  python3 - "$STATE_FILE" "$key" "$@" <<'PY'
import json
import sys
from pathlib import Path

state_path = Path(sys.argv[1])
key = sys.argv[2]
values = sys.argv[3:]
state = json.loads(state_path.read_text(encoding="utf-8"))
state[key] = values
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

print_summary() {
  python3 - "$RUNTIME_FILE" <<'PY'
import json
import sys

runtime = json.load(open(sys.argv[1], encoding="utf-8"))
pack = runtime["pack"]
resolved = runtime["resolved"]
matched = runtime["matched_profile"]
state = runtime["state"]

profile_line = matched if matched else f"custom (from {state['profile']['selected']})"
mode_tag = "preset" if matched else "custom"

print("--- Current Configuration ---")
print(f"  Pack:        {pack['label']} ({pack['id']})")
print(f"  Profile:     {profile_line} [{mode_tag}]")
print(f"  MCPs:        {len(resolved['mcps']['enabled'])} enabled")
print(f"  Skills:      {len(resolved['skills']['enabled'])} enabled")
print(f"  Agents:      {len(resolved['agents']['enabled'])} enabled")
print(f"  Rules:       {len(resolved['rules']['enabled'])} enabled")
print(f"  Permissions: {len(resolved['permissions']['enabled'])} groups")

settings_lines = []
for key, value in resolved["settings"].items():
    if value == "":
        continue
    settings_lines.append(f"{key}: {value}")
if settings_lines:
    print(f"  Settings:    {', '.join(settings_lines)}")

warnings = []
for mcp_id in resolved["mcps"]["enabled"]:
    catalog_entry = pack.get("catalogs", {}).get("mcps", {}).get(mcp_id, {})
    if catalog_entry.get("needs_secrets"):
        warnings.append(f"{mcp_id} (needs secrets)")
    if catalog_entry.get("prompt_injection_risk") == "high":
        warnings.append(f"{mcp_id} (high injection risk)")
if warnings:
    unique_warnings = list(dict.fromkeys(warnings))
    print(f"  Warnings:    {', '.join(unique_warnings[:5])}")
print("-----------------------------")
PY
}

choose_pack() {
  if have_gum; then
    local selection
    selection="$(
      python3 - "$SOURCE_DIR" "$PACK_STATE_PY" <<'PY' | "$GUM_BIN" choose --header "Select capability pack"
import json
import subprocess
import sys

source_dir = sys.argv[1]
helper = sys.argv[2]
packs = json.loads(subprocess.check_output([sys.executable, helper, "list-packs", source_dir], text=True))
for pack in packs:
    print(f"{pack['id']} | {pack['label']} | {pack['description']}")
PY
    )"
    [ -n "$selection" ] && printf "%s" "${selection%% | *}"
    return
  fi

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
  if have_gum; then
    local selection
    selection="$(
      python3 - "$RUNTIME_FILE" <<'PY' | "$GUM_BIN" choose --header "Select pack profile"
import json
import sys

runtime = json.load(open(sys.argv[1], encoding="utf-8"))
matched = runtime["matched_profile"]
for profile_id, profile in runtime["pack"]["profiles"].items():
    marker = "*" if matched == profile_id else " "
    print(f"{profile_id} | {marker} {profile['label']} | {profile['description']}")
PY
    )"
    [ -n "$selection" ] && printf "%s" "${selection%% | *}"
    return
  fi

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

edit_catalog() {
  local catalog_key="$1"
  local selection_key="$2"
  refresh_runtime
  if have_gum; then
    mapfile -t selected < <(
      python3 - "$RUNTIME_FILE" "$catalog_key" <<'PY' | "$GUM_BIN" choose --no-limit --header "Select ${catalog_key}"
import json
import sys

runtime = json.load(open(sys.argv[1], encoding="utf-8"))
catalog_key = sys.argv[2]
catalog = runtime["pack"]["catalogs"][catalog_key]
for item_id, item in catalog.items():
    description = item.get("description", "")
    label = item.get("label", item_id)
    print(f"{item_id} | {label} | {description}")
PY
    )
    for i in "${!selected[@]}"; do
      selected[$i]="${selected[$i]%% | *}"
    done
    [ ${#selected[@]} -gt 0 ] && set_array_value "$selection_key" "${selected[@]}"
  else
    python3 - "$RUNTIME_FILE" "$catalog_key" "$selection_key" <<'PY' >&2
import json
import sys

runtime = json.load(open(sys.argv[1], encoding="utf-8"))
catalog_key = sys.argv[2]
selection_key = sys.argv[3]
enabled = set(runtime["state"]["selection"][catalog_key]["enabled"])
for idx, (item_id, item) in enumerate(runtime["pack"]["catalogs"][catalog_key].items(), start=1):
    marker = "x" if item_id in enabled else " "
    label = item.get("label", item_id)
    description = item.get("description", "")
    print(f"{idx}. [{marker}] {label} ({item_id}) - {description}")
PY
    printf "Enter comma-separated numbers or press Enter to keep current: " >&2
    read -r response <&3
    if [ -z "$response" ]; then
      return
    fi
    mapfile -t selected < <(
      python3 - "$RUNTIME_FILE" "$catalog_key" "$response" <<'PY'
import json
import sys

runtime = json.load(open(sys.argv[1], encoding="utf-8"))
catalog_key = sys.argv[2]
raw = sys.argv[3]
ids = list(runtime["pack"]["catalogs"][catalog_key].keys())
for token in raw.split(","):
    token = token.strip()
    if not token:
        continue
    print(ids[int(token) - 1])
PY
    )
    [ ${#selected[@]} -gt 0 ] && set_array_value "$selection_key" "${selected[@]}"
  fi
  refresh_runtime
  snap_profile_if_needed
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
      if have_gum; then
        value="$(
          python3 -c 'import json,sys; data=json.loads(sys.argv[1]); [print(opt["value"]) for opt in data["options"]]' "$setting" | "$GUM_BIN" choose --header "$label"
        )"
      else
        python3 - "$setting" <<'PY' >&2
import json
import sys

data = json.loads(sys.argv[1])
for index, option in enumerate(data["options"], start=1):
    print(f"{index}. {option['label']} ({option['value']})")
PY
        printf "%s [%s]: " "$label" "$current"
        read -r response <&3
        if [ -z "$response" ]; then
          value="$current"
        else
          value="$(python3 -c 'import json,sys; data=json.loads(sys.argv[1]); print(data["options"][int(sys.argv[2])-1]["value"])' "$setting" "$response")"
        fi
      fi
    else
      if have_gum; then
        value="$("$GUM_BIN" input --header "$label" --value "$current")"
      else
        printf "%s [%s]: " "$label" "$current"
        read -r value <&3
        [ -z "$value" ] && value="$current"
      fi
    fi
    set_scalar_value "$key" "$value"
    refresh_runtime
    snap_profile_if_needed
  done < "$RUNTIME_FILE.settings"
  rm -f "$RUNTIME_FILE.settings"
}

run_gum_loop() {
  while true; do
    refresh_runtime
    printf "\n"
    print_summary
    printf "\n"
    local action
    action="$(
      printf '%s\n' \
        "Pack" \
        "Profile" \
        "MCP Servers" \
        "Skills" \
        "Agents" \
        "Rules" \
        "Permission Groups" \
        "Settings" \
        "Apply" \
        "Quit" | "$GUM_BIN" choose --header "Dotfiles setup"
    )"
    case "$action" in
      "Pack")
        local pack_id
        pack_id="$(choose_pack)"
        [ -n "$pack_id" ] && set_profile "$pack_id" "$(python3 - "$SOURCE_DIR" "$PACK_STATE_PY" "$pack_id" <<'PY'
import json
import subprocess
import sys
pack = json.loads(subprocess.check_output([sys.executable, sys.argv[2], "pack", sys.argv[1], sys.argv[3]], text=True))
print(pack["defaults"]["profile"])
PY
)"
        ;;
      "Profile")
        set_profile "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["pack"]["id"])' "$RUNTIME_FILE")" "$(choose_profile)"
        ;;
      "MCP Servers")
        edit_catalog "mcps" "selection_enabled_mcps"
        ;;
      "Skills")
        edit_catalog "skills" "selection_enabled_skills"
        ;;
      "Agents")
        edit_catalog "agents" "selection_enabled_agents"
        ;;
      "Rules")
        edit_catalog "rules" "selection_enabled_rules"
        ;;
      "Permission Groups")
        edit_catalog "permissions" "selection_enabled_permissions"
        ;;
      "Settings")
        edit_settings
        ;;
      "Apply")
        break
        ;;
      *)
        exit 0
        ;;
    esac
  done
}

run_plain_flow() {
  refresh_runtime
  local pack_id profile_id
  pack_id="$(choose_pack)"
  set_profile "$pack_id" "$(python3 - "$SOURCE_DIR" "$PACK_STATE_PY" "$pack_id" <<'PY'
import json
import subprocess
import sys

pack = json.loads(subprocess.check_output([sys.executable, sys.argv[2], "pack", sys.argv[1], sys.argv[3]], text=True))
print(pack["defaults"]["profile"])
PY
)"
  refresh_runtime
  profile_id="$(choose_profile)"
  set_profile "$pack_id" "$profile_id"
  edit_settings
}

state_init
refresh_runtime

if have_gum; then
  run_gum_loop
else
  run_plain_flow
fi
