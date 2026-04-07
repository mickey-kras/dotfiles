#!/usr/bin/env python3
import json
import subprocess
import sys
import tempfile
from pathlib import Path


def run_chezmoi(source_dir, template_text, override_data=None):
    command = ["chezmoi", "execute-template", "--source", str(source_dir)]
    temp_path = None
    if override_data is not None:
        handle = tempfile.NamedTemporaryFile(
            "w", suffix=".json", encoding="utf-8", delete=False
        )
        json.dump(override_data, handle)
        handle.flush()
        handle.close()
        temp_path = handle.name
        command.extend(["--override-data-file", temp_path])
    try:
        result = subprocess.run(
            command,
            input=template_text,
            text=True,
            capture_output=True,
            check=True,
        )
        return result.stdout
    finally:
        if temp_path is not None:
            Path(temp_path).unlink(missing_ok=True)


def load_pack(source_dir, pack_id):
    template = '{{ include %s | fromYaml | toJson }}' % json.dumps(
        f"packs/{pack_id}/pack.yaml"
    )
    return json.loads(run_chezmoi(source_dir, template))


def resolved_state(source_dir, state):
    template = '{{ includeTemplate "templates/resolved-state.json" . }}'
    return json.loads(run_chezmoi(source_dir, template, override_data=state))


def normalize_selection(pack, selection):
    normalized = {
        "mcps": {"enabled": sorted(set(selection["mcps"]["enabled"]))},
        "skills": {"enabled": sorted(set(selection["skills"]["enabled"]))},
        "agents": {"enabled": sorted(set(selection["agents"]["enabled"]))},
        "rules": {"enabled": sorted(set(selection["rules"]["enabled"]))},
        "permissions": {"enabled": sorted(set(selection["permissions"]["enabled"]))},
        "settings": {},
    }

    settings_schema = pack["settings_schema"]
    settings = {
        **pack["defaults"]["selection"]["settings"],
        **selection["settings"],
    }
    for setting_name, schema in settings_schema.items():
        value = settings.get(setting_name, schema.get("default"))
        visible_if = schema.get("visible_if")
        if visible_if:
            visible = all(settings.get(key) == expected for key, expected in visible_if.items())
            if not visible:
                value = schema.get("default")
        normalized["settings"][setting_name] = value
    return normalized


def find_matching_profile(pack, resolved):
    actual = normalize_selection(pack, resolved["state"]["selection"])
    for profile_name, profile in pack["profiles"].items():
        expected = normalize_selection(pack, profile["selection"])
        if actual == expected:
            return profile_name
    return ""


def build_bootstrap_state(source_dir, state):
    resolved = resolved_state(source_dir, state)
    pack = resolved["pack"]
    matched_profile = find_matching_profile(pack, resolved)
    return {
        "pack": pack,
        "resolved": resolved["resolved"],
        "state": resolved["state"],
        "matched_profile": matched_profile,
    }


def legacy_config(source_dir, state):
    bootstrap_state = build_bootstrap_state(source_dir, state)
    pack = bootstrap_state["pack"]
    resolved = bootstrap_state["resolved"]
    current_state = bootstrap_state["state"]
    matched_profile = bootstrap_state["matched_profile"]

    selected_profile = current_state["profile"]["selected"]
    profile_mode = "preset" if matched_profile else "custom"
    runtime_profile = matched_profile or "custom"
    profile_base = matched_profile or selected_profile

    base_profile = pack["profiles"][profile_base]["selection"]
    mcps = set(resolved["mcps"]["enabled"])
    base_mcps = set(base_profile["mcps"]["enabled"])
    permissions = set(resolved["permissions"]["enabled"])
    base_permissions = set(base_profile["permissions"]["enabled"])

    return {
        "capability_pack": resolved["pack_id"],
        "runtime_profile": runtime_profile,
        "profile_base": profile_base,
        "profile_selected": matched_profile or selected_profile,
        "profile_mode": profile_mode,
        "custom_enabled_mcps": sorted(mcps - base_mcps),
        "custom_disabled_mcps": sorted(base_mcps - mcps),
        "custom_enabled_permission_groups": sorted(permissions - base_permissions),
        "custom_disabled_permission_groups": sorted(base_permissions - permissions),
        "selection_enabled_mcps": resolved["mcps"]["enabled"],
        "selection_enabled_skills": resolved["skills"]["enabled"],
        "selection_enabled_agents": resolved["agents"]["enabled"],
        "selection_enabled_rules": resolved["rules"]["enabled"],
        "selection_enabled_permissions": resolved["permissions"]["enabled"],
        "memory_provider": resolved["settings"].get("memory_provider", "builtin"),
        "obsidian_vault_path": resolved["settings"].get("obsidian_vault_path", ""),
        "azure_devops_org": resolved["settings"].get("azure_devops_org", ""),
        "content_workspace": resolved["settings"].get("content_workspace", ""),
        "matched_profile": matched_profile,
    }


def list_packs(source_dir):
    packs_dir = Path(source_dir) / "packs"
    results = []
    for path in sorted(packs_dir.iterdir()):
        if not path.is_dir():
            continue
        pack_file = path / "pack.yaml"
        if not pack_file.exists():
            continue
        pack = load_pack(source_dir, path.name)
        results.append(
            {
                "id": pack["id"],
                "label": pack["label"],
                "description": pack["description"],
                "default_profile": pack["defaults"]["profile"],
            }
        )
    return sorted(results, key=lambda pack: (pack["id"] != "software-development", pack["id"]))


def usage():
    print(
        "usage: pack_state.py <list-packs|pack|bootstrap-state|legacy-config> <source_dir> [arg]",
        file=sys.stderr,
    )
    raise SystemExit(1)


def main():
    if len(sys.argv) < 3:
        usage()

    command = sys.argv[1]
    source_dir = Path(sys.argv[2])

    if command == "list-packs":
        print(json.dumps(list_packs(source_dir), indent=2))
        return

    if command == "pack":
        if len(sys.argv) != 4:
            usage()
        print(json.dumps(load_pack(source_dir, sys.argv[3]), indent=2))
        return

    if command == "bootstrap-state":
        if len(sys.argv) != 4:
            usage()
        state = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))
        print(json.dumps(build_bootstrap_state(source_dir, state), indent=2))
        return

    if command == "legacy-config":
        if len(sys.argv) != 4:
            usage()
        state = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))
        print(json.dumps(legacy_config(source_dir, state), indent=2))
        return

    usage()


if __name__ == "__main__":
    main()
