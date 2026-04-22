import unittest

from helpers import load_fixture, render_template


PROFILE_CASES = {
    "restricted": {
        "runtime_profile": "restricted",
        "capability_pack": "software-development",
        "profile_base": "balanced",
        "custom_enabled_mcps": [],
        "custom_disabled_mcps": [],
        "custom_enabled_permission_groups": [],
        "custom_disabled_permission_groups": [],
        "memory_provider": "builtin",
        "obsidian_vault_path": "",
        "azure_devops_org": "",
    },
    "balanced": {
        "runtime_profile": "balanced",
        "capability_pack": "software-development",
        "profile_base": "balanced",
        "custom_enabled_mcps": [],
        "custom_disabled_mcps": [],
        "custom_enabled_permission_groups": [],
        "custom_disabled_permission_groups": [],
        "memory_provider": "builtin",
        "obsidian_vault_path": "",
        "azure_devops_org": "",
    },
    "open": {
        "runtime_profile": "open",
        "capability_pack": "software-development",
        "profile_base": "balanced",
        "custom_enabled_mcps": [],
        "custom_disabled_mcps": [],
        "custom_enabled_permission_groups": [],
        "custom_disabled_permission_groups": [],
        "memory_provider": "builtin",
        "obsidian_vault_path": "",
        "azure_devops_org": "",
    },
    "custom-balanced": {
        "runtime_profile": "custom",
        "capability_pack": "software-development",
        "profile_base": "balanced",
        "custom_enabled_mcps": ["exa"],
        "custom_disabled_mcps": ["docker"],
        "custom_enabled_permission_groups": ["web_access"],
        "custom_disabled_permission_groups": ["containers"],
        "memory_provider": "obsidian",
        "obsidian_vault_path": "/Users/mikhailkrasilnikov/Notes",
        "azure_devops_org": "acme-platform",
    },
    "content-studio": {
        "runtime_profile": "studio",
        "capability_pack": "content-creation",
        "profile_base": "studio",
        "custom_enabled_mcps": [],
        "custom_disabled_mcps": [],
        "custom_enabled_permission_groups": [],
        "custom_disabled_permission_groups": [],
        "memory_provider": "builtin",
        "obsidian_vault_path": "",
        "content_workspace": "/Users/mikhailkrasilnikov/Content",
        "azure_devops_org": "",
    },
}

CONTENT_PROFILE_CASES = {
    "content-focused": {
        "runtime_profile": "focused",
        "capability_pack": "content-creation",
        "profile_base": "focused",
        "custom_enabled_mcps": [],
        "custom_disabled_mcps": [],
        "custom_enabled_permission_groups": [],
        "custom_disabled_permission_groups": [],
        "memory_provider": "builtin",
        "obsidian_vault_path": "",
        "content_workspace": "",
        "azure_devops_org": "",
    },
    "content-campaign": {
        "runtime_profile": "campaign",
        "capability_pack": "content-creation",
        "profile_base": "campaign",
        "custom_enabled_mcps": [],
        "custom_disabled_mcps": [],
        "custom_enabled_permission_groups": [],
        "custom_disabled_permission_groups": [],
        "memory_provider": "builtin",
        "obsidian_vault_path": "",
        "content_workspace": "/Users/mikhailkrasilnikov/Content",
        "azure_devops_org": "",
    },
}

RESEARCH_PROFILE_CASES = {
    "research-desk": {
        "runtime_profile": "desk",
        "capability_pack": "research-and-strategy",
        "profile_base": "desk",
        "custom_enabled_mcps": [],
        "custom_disabled_mcps": [],
        "custom_enabled_permission_groups": [],
        "custom_disabled_permission_groups": [],
        "memory_provider": "builtin",
        "obsidian_vault_path": "",
        "research_workspace": "",
        "azure_devops_org": "",
    },
    "research-investigation": {
        "runtime_profile": "investigation",
        "capability_pack": "research-and-strategy",
        "profile_base": "investigation",
        "custom_enabled_mcps": [],
        "custom_disabled_mcps": [],
        "custom_enabled_permission_groups": [],
        "custom_disabled_permission_groups": [],
        "memory_provider": "builtin",
        "obsidian_vault_path": "",
        "research_workspace": "/Users/mikhailkrasilnikov/Research",
        "azure_devops_org": "",
    },
}

SNAPSHOTS = {
    "dot_claude/settings.json.tmpl": "claude-settings.json",
    "dot_codex/config.toml.tmpl": "codex-config.toml",
    "dot_cursor/mcp.json.tmpl": "cursor-mcp.json",
    "scripts/chezmoi/run_onchange_after_install-claude-mcps.sh.tmpl": "claude-mcp-reconcile.sh",
}

ALL_CASES = {**PROFILE_CASES, **CONTENT_PROFILE_CASES, **RESEARCH_PROFILE_CASES}


class RenderSnapshotTests(unittest.TestCase):
    def test_snapshots_match_current_templates(self):
        for case_name, override_data in ALL_CASES.items():
            pack_id = override_data.get("capability_pack", "software-development")
            for template_path, fixture_name in SNAPSHOTS.items():
                with self.subTest(case=case_name, template=template_path):
                    actual = render_template(template_path, override_data)
                    expected = load_fixture(
                        f"tests/fixtures/rendered/{pack_id}/{case_name}/{fixture_name}"
                    )
                    self.assertEqual(actual, expected)


if __name__ == "__main__":
    unittest.main()
