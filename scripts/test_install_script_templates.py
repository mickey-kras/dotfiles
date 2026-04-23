#!/usr/bin/env python3
"""Rendering tests for the run_onchange_after_install-* templates."""
import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

import pack_state

SOURCE_DIR = Path(__file__).resolve().parent.parent
CHEZMOI_SCRIPTS_DIR = SOURCE_DIR / "scripts" / "chezmoi"

INSTALL_TEMPLATES = [
    "run_onchange_after_install-claude-mcps.sh.tmpl",
    "run_onchange_after_install-claude-pack-assets.sh.tmpl",
    "run_onchange_after_install-managed-skills.sh.tmpl",
    "run_onchange_after_install-bw-gate.sh.tmpl",
    "run_onchange_after_install-obsidian.sh.tmpl",
]


def _render(template_path: Path, override_data: dict) -> str:
    if not shutil.which("chezmoi"):
        raise unittest.SkipTest("chezmoi not installed")
    with tempfile.NamedTemporaryFile(
        "w", suffix=".json", delete=False, encoding="utf-8"
    ) as handle:
        json.dump(override_data, handle)
        handle.flush()
        data_path = handle.name
    try:
        result = subprocess.run(
            [
                "chezmoi",
                "execute-template",
                "--source",
                str(SOURCE_DIR),
                "--override-data-file",
                data_path,
            ],
            input=template_path.read_text(encoding="utf-8"),
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout
    finally:
        Path(data_path).unlink(missing_ok=True)


def _full_state() -> dict:
    pack = pack_state.load_pack(str(SOURCE_DIR), "software-development")
    selection = pack["profiles"]["full"]["selection"]
    return {
        "capability_pack": "software-development",
        "pack_id": "software-development",
        "profile_selected": "full",
        "profile_mode": "preset",
        "runtime_profile": "full",
        "profile_base": "full",
        "selection_enabled_mcps": selection["mcps"]["enabled"],
        "selection_enabled_skills": selection["skills"]["enabled"],
        "selection_enabled_agents": selection["agents"]["enabled"],
        "selection_enabled_rules": selection["rules"]["enabled"],
        "selection_enabled_permissions": selection["permissions"]["enabled"],
        "memory_provider": "obsidian",
        "obsidian_vault_path": "/Users/mikhailkrasilnikov/Notes",
        "install_claude_code": "disabled",
        "install_codex": "disabled",
        "install_cursor": "disabled",
        "install_gemini_cli": "disabled",
        "install_droid": "disabled",
        "stitch_api_key": "test-stitch-key",
        "bw_gate_install": "enabled",
    }


class TestInstallScriptTemplates(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not shutil.which("chezmoi"):
            raise unittest.SkipTest("chezmoi not installed")
        if not shutil.which("bash"):
            raise unittest.SkipTest("bash not installed")
        cls.state = _full_state()
        cls.rendered = {
            name: _render(CHEZMOI_SCRIPTS_DIR / name, cls.state)
            for name in INSTALL_TEMPLATES
        }

    def test_all_templates_exist(self):
        for name in INSTALL_TEMPLATES:
            self.assertTrue((CHEZMOI_SCRIPTS_DIR / name).exists(), name)

    def test_rendered_scripts_pass_bash_syntax_check(self):
        for name, content in self.rendered.items():
            with self.subTest(template=name):
                with tempfile.NamedTemporaryFile(
                    "w", suffix=".sh", delete=False, encoding="utf-8"
                ) as handle:
                    handle.write(content)
                    handle.flush()
                    script_path = handle.name
                try:
                    result = subprocess.run(
                        ["bash", "-n", script_path],
                        capture_output=True,
                        text=True,
                    )
                    self.assertEqual(
                        result.returncode,
                        0,
                        f"bash -n rejected {name}:\n{result.stderr}",
                    )
                finally:
                    Path(script_path).unlink(missing_ok=True)

    def test_variable_bindings_are_on_their_own_lines(self):
        expected_per_template = {
            "run_onchange_after_install-claude-mcps.sh.tmpl": [
                'HOME_SLASHED="',
                'MEMORY_PROVIDER="',
                'STITCH_API_KEY="',
            ],
            "run_onchange_after_install-claude-pack-assets.sh.tmpl": [
                'HOME_SLASHED="',
                'PACK_CLAUDE_DIR="',
            ],
            "run_onchange_after_install-managed-skills.sh.tmpl": [
                'HOME_SLASHED="',
                'MANAGED_SKILLS_DIR="',
            ],
            "run_onchange_after_install-bw-gate.sh.tmpl": [
                'HOME_SLASHED="',
                'BW_GATE_INSTALL="',
                'BUNDLE_ID="',
            ],
            "run_onchange_after_install-obsidian.sh.tmpl": [
                'HOME_SLASHED="',
                'MEMORY_PROVIDER="',
                'OBSIDIAN_VAULT_PATH="',
                'OBSIDIAN_SELECTED="',
                'MANAGED_CONFIG="',
            ],
        }
        for name, expected in expected_per_template.items():
            with self.subTest(template=name):
                content = self.rendered[name]
                for marker in expected:
                    matching = [line for line in content.splitlines() if marker in line]
                    self.assertTrue(matching, f"{name}: no line contains {marker!r}")
                    for line in matching:
                        stripped = line.lstrip()
                        self.assertTrue(
                            stripped.startswith(marker.split('="')[0]),
                            f"{name}: {marker!r} is not at the start of its line: {line!r}",
                        )

    def test_mcps_array_contains_full_profile_entries(self):
        content = self.rendered["run_onchange_after_install-claude-mcps.sh.tmpl"]
        for mcp in self.state["selection_enabled_mcps"]:
            self.assertIn(f'"{mcp}"', content, f"rendered mcps script is missing {mcp}")

    def test_agents_and_rules_arrays_contain_full_entries(self):
        content = self.rendered["run_onchange_after_install-claude-pack-assets.sh.tmpl"]
        for agent in self.state["selection_enabled_agents"]:
            self.assertIn(f'"{agent}"', content, f"missing agent {agent}")
        for rule in self.state["selection_enabled_rules"]:
            self.assertIn(f'"{rule}"', content, f"missing rule {rule}")

    def test_managed_skills_array_contains_full_entries(self):
        content = self.rendered["run_onchange_after_install-managed-skills.sh.tmpl"]
        for skill in self.state["selection_enabled_skills"]:
            self.assertIn(f'"{skill}"', content, f"missing skill {skill}")

    def test_obsidian_script_tracks_managed_plugins(self):
        content = self.rendered["run_onchange_after_install-obsidian.sh.tmpl"]
        self.assertIn("obsidian-local-rest-api", content)
        self.assertIn("community-plugins.json", content)
        self.assertIn("plugin_versions", content)
        self.assertIn("Obsidian vault reconciled", content)

    def test_no_template_placeholders_leak_into_rendered_output(self):
        for name, content in self.rendered.items():
            with self.subTest(template=name):
                self.assertNotIn("{{", content, f"{name}: unrendered `{{{{` in output")
                self.assertNotIn("}}", content, f"{name}: unrendered `}}}}` in output")


if __name__ == "__main__":
    unittest.main()
