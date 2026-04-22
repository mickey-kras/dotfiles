#!/usr/bin/env python3
"""Rendering tests for the three run_onchange_after_install-* templates.

These scripts are the only thing that actually installs Claude MCPs, pack
assets, and managed skills. A whitespace bug in the template (for example
`{{- ... -}}` collapsing an adjacent variable binding into the previous
line) produces a script that parses but fails at runtime with `unbound
variable`. The original bug that motivated these tests collapsed
`HOME_SLASHED="..."` into the next variable assignment and broke every
fresh bootstrap until it was spotted manually.

We render each template with a realistic software-development/balanced
state and then assert:
  1. `bash -n` accepts the rendered script (syntactic sanity)
  2. structural invariants hold: the variable bindings we rely on are
     each on their own line, nothing is prefixed with `}}`, and the
     MANAGED/DESIRED/AGENT/RULE arrays contain the expected entries.

Requires `chezmoi` on PATH.
"""
import json
import os
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


def _balanced_state() -> dict:
    pack = pack_state.load_pack(str(SOURCE_DIR), "software-development")
    selection = pack["profiles"]["balanced"]["selection"]
    return {
        "capability_pack": "software-development",
        "pack_id": "software-development",
        "profile_selected": "balanced",
        "profile_mode": "preset",
        "runtime_profile": "balanced",
        "profile_base": "balanced",
        "selection_enabled_mcps": selection["mcps"]["enabled"],
        "selection_enabled_skills": selection["skills"]["enabled"],
        "selection_enabled_agents": selection["agents"]["enabled"],
        "selection_enabled_rules": selection["rules"]["enabled"],
        "selection_enabled_permissions": selection["permissions"]["enabled"],
        "memory_provider": "builtin",
        "obsidian_vault_path": "",
        "azure_devops_org": "",
        "content_workspace": "",
    }


class TestInstallScriptTemplates(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not shutil.which("chezmoi"):
            raise unittest.SkipTest("chezmoi not installed")
        if not shutil.which("bash"):
            raise unittest.SkipTest("bash not installed")
        cls.state = _balanced_state()
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
        """Catches the `{{- ... -}}` whitespace-strip bug that collapsed
        HOME_SLASHED="..." into the next variable binding."""
        expected_per_template = {
            "run_onchange_after_install-claude-mcps.sh.tmpl": [
                'HOME_SLASHED="',
                'RUNTIME_PROFILE="',
                'PROFILE_BASE="',
                'AZURE_DEVOPS_ORG="',
                'MEMORY_PROVIDER="',
            ],
            "run_onchange_after_install-claude-pack-assets.sh.tmpl": [
                'HOME_SLASHED="',
                'CAPABILITY_PACK="',
                'PACK_CLAUDE_DIR="',
            ],
            "run_onchange_after_install-managed-skills.sh.tmpl": [
                'HOME_SLASHED="',
                'CAPABILITY_PACK="',
                'MANAGED_SKILLS_DIR="',
            ],
        }
        for name, expected in expected_per_template.items():
            with self.subTest(template=name):
                content = self.rendered[name]
                for marker in expected:
                    matching = [
                        line for line in content.splitlines() if marker in line
                    ]
                    self.assertTrue(
                        matching,
                        f"{name}: no line contains {marker!r}",
                    )
                    for line in matching:
                        # Must start with the variable name, not be glued onto
                        # a template-stripping artifact or a previous binding.
                        stripped = line.lstrip()
                        self.assertTrue(
                            stripped.startswith(marker.split('="')[0]),
                            f"{name}: {marker!r} is not at the start of its line: {line!r}",
                        )

    def test_mcps_array_contains_balanced_profile_entries(self):
        content = self.rendered["run_onchange_after_install-claude-mcps.sh.tmpl"]
        for mcp in self.state["selection_enabled_mcps"]:
            self.assertIn(
                f'"{mcp}"',
                content,
                f"rendered mcps script is missing {mcp}",
            )

    def test_agents_and_rules_arrays_contain_balanced_entries(self):
        content = self.rendered[
            "run_onchange_after_install-claude-pack-assets.sh.tmpl"
        ]
        for agent in self.state["selection_enabled_agents"]:
            self.assertIn(f'"{agent}"', content, f"missing agent {agent}")
        for rule in self.state["selection_enabled_rules"]:
            self.assertIn(f'"{rule}"', content, f"missing rule {rule}")

    def test_managed_skills_array_contains_balanced_entries(self):
        content = self.rendered[
            "run_onchange_after_install-managed-skills.sh.tmpl"
        ]
        for skill in self.state["selection_enabled_skills"]:
            self.assertIn(f'"{skill}"', content, f"missing skill {skill}")

    def test_no_template_placeholders_leak_into_rendered_output(self):
        for name, content in self.rendered.items():
            with self.subTest(template=name):
                self.assertNotIn("{{", content, f"{name}: unrendered `{{{{` in output")
                self.assertNotIn("}}", content, f"{name}: unrendered `}}}}` in output")


if __name__ == "__main__":
    unittest.main()
