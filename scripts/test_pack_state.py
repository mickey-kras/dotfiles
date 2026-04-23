#!/usr/bin/env python3
"""Focused integration tests for pack_state.py using the software-development pack."""
import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

import pack_state

SOURCE_DIR = str(Path(__file__).resolve().parent.parent)


@unittest.skipUnless(shutil.which("chezmoi"), "chezmoi not installed")
class TestListPacks(unittest.TestCase):
    def test_returns_only_supported_pack(self):
        packs = pack_state.list_packs(SOURCE_DIR)
        self.assertEqual(
            packs,
            [
                {
                    "id": "software-development",
                    "label": "Software Development",
                    "description": (
                        "Software delivery pack across planning, implementation, testing, "
                        "review, docs, and incident response."
                    ),
                    "default_profile": "full",
                }
            ],
        )


@unittest.skipUnless(shutil.which("chezmoi"), "chezmoi not installed")
class TestLoadPack(unittest.TestCase):
    def test_loads_software_development(self):
        pack = pack_state.load_pack(SOURCE_DIR, "software-development")
        self.assertEqual(pack["id"], "software-development")
        self.assertEqual(pack["defaults"]["profile"], "full")
        self.assertIn("full", pack["profiles"])
        self.assertIn("mcps", pack["catalogs"])


@unittest.skipUnless(shutil.which("chezmoi"), "chezmoi not installed")
class TestNormalizeSelection(unittest.TestCase):
    def test_sorts_and_deduplicates(self):
        pack = pack_state.load_pack(SOURCE_DIR, "software-development")
        selection = {
            "mcps": {"enabled": ["github", "context7", "github"]},
            "skills": {"enabled": ["writing-plans", "writing-plans", "context-budget"]},
            "agents": {"enabled": []},
            "rules": {"enabled": []},
            "permissions": {"enabled": []},
            "settings": {},
        }
        normalized = pack_state.normalize_selection(pack, selection)

        self.assertEqual(normalized["mcps"]["enabled"], ["context7", "github"])
        self.assertEqual(
            normalized["skills"]["enabled"], ["context-budget", "writing-plans"]
        )

    def test_applies_default_settings(self):
        pack = pack_state.load_pack(SOURCE_DIR, "software-development")
        normalized = pack_state.normalize_selection(
            pack,
            {
                "mcps": {"enabled": []},
                "skills": {"enabled": []},
                "agents": {"enabled": []},
                "rules": {"enabled": []},
                "permissions": {"enabled": []},
                "settings": {},
            },
        )

        for key, schema in pack["settings_schema"].items():
            if schema.get("visible_if"):
                continue
            self.assertIn(key, normalized["settings"])


@unittest.skipUnless(shutil.which("chezmoi"), "chezmoi not installed")
class TestFindMatchingProfile(unittest.TestCase):
    def test_finds_full_profile(self):
        pack = pack_state.load_pack(SOURCE_DIR, "software-development")
        profile_selection = pack["profiles"]["full"]["selection"]
        matched = pack_state.find_matching_profile(
            pack,
            {
                "pack": pack,
                "state": {"selection": profile_selection},
            },
        )
        self.assertEqual(matched, "full")

    def test_returns_empty_for_custom_selection(self):
        pack = pack_state.load_pack(SOURCE_DIR, "software-development")
        matched = pack_state.find_matching_profile(
            pack,
            {
                "pack": pack,
                "state": {
                    "selection": {
                        "mcps": {"enabled": ["github"]},
                        "skills": {"enabled": []},
                        "agents": {"enabled": []},
                        "rules": {"enabled": []},
                        "permissions": {"enabled": []},
                        "settings": {"memory_provider": "builtin"},
                    }
                },
            },
        )
        self.assertEqual(matched, "")


@unittest.skipUnless(shutil.which("chezmoi"), "chezmoi not installed")
class TestLegacyConfig(unittest.TestCase):
    def test_includes_all_pack_settings(self):
        pack = pack_state.load_pack(SOURCE_DIR, "software-development")
        selection = pack["profiles"]["full"]["selection"]
        state = {
            "capability_pack": "software-development",
            "profile_selected": "full",
            "profile_mode": "preset",
            "selection_enabled_mcps": selection["mcps"]["enabled"],
            "selection_enabled_skills": selection["skills"]["enabled"],
            "selection_enabled_agents": selection["agents"]["enabled"],
            "selection_enabled_rules": selection["rules"]["enabled"],
            "selection_enabled_permissions": selection["permissions"]["enabled"],
            "memory_provider": "obsidian",
            "obsidian_vault_path": "/vault",
            "install_claude_code": "enabled",
            "install_codex": "disabled",
            "install_cursor": "enabled",
            "install_gemini_cli": "disabled",
            "install_droid": "enabled",
            "stitch_api_key": "test-key",
            "bw_gate_install": "enabled",
            "user_name": "Test User",
        }

        config = pack_state.legacy_config(SOURCE_DIR, state)

        self.assertEqual(config["runtime_profile"], "custom")
        self.assertEqual(config["memory_provider"], "obsidian")
        self.assertEqual(config["obsidian_vault_path"], "/vault")
        self.assertEqual(config["install_claude_code"], "enabled")
        self.assertEqual(config["install_cursor"], "enabled")
        self.assertEqual(config["install_droid"], "enabled")
        self.assertEqual(config["stitch_api_key"], "test-key")
        self.assertEqual(config["user_name"], "Test User")


@unittest.skipUnless(shutil.which("chezmoi"), "chezmoi not installed")
class TestCliInterface(unittest.TestCase):
    def test_list_packs_cli(self):
        result = subprocess.run(
            ["python3", str(Path(__file__).parent / "pack_state.py"), "list-packs", SOURCE_DIR],
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0)
        packs = json.loads(result.stdout)
        self.assertEqual(len(packs), 1)
        self.assertEqual(packs[0]["id"], "software-development")

    def test_pack_cli(self):
        result = subprocess.run(
            [
                "python3",
                str(Path(__file__).parent / "pack_state.py"),
                "pack",
                SOURCE_DIR,
                "software-development",
            ],
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0)
        pack = json.loads(result.stdout)
        self.assertEqual(pack["defaults"]["profile"], "full")

    def test_bootstrap_state_cli(self):
        pack = pack_state.load_pack(SOURCE_DIR, "software-development")
        selection = pack["profiles"]["full"]["selection"]
        state = {
            "capability_pack": "software-development",
            "profile_selected": "full",
            "profile_mode": "preset",
            "selection_enabled_mcps": selection["mcps"]["enabled"],
            "selection_enabled_skills": selection["skills"]["enabled"],
            "selection_enabled_agents": selection["agents"]["enabled"],
            "selection_enabled_rules": selection["rules"]["enabled"],
            "selection_enabled_permissions": selection["permissions"]["enabled"],
            "memory_provider": "obsidian",
            "obsidian_vault_path": "/vault",
            "stitch_api_key": "test-key",
        }

        with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as handle:
            json.dump(state, handle)
            handle.flush()
            state_path = handle.name
        try:
            result = subprocess.run(
                [
                    "python3",
                    str(Path(__file__).parent / "pack_state.py"),
                    "bootstrap-state",
                    SOURCE_DIR,
                    state_path,
                ],
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0)
            payload = json.loads(result.stdout)
            self.assertEqual(payload["pack"]["id"], "software-development")
            self.assertEqual(payload["resolved"]["settings"]["stitch_api_key"], "test-key")
        finally:
            Path(state_path).unlink(missing_ok=True)


if __name__ == "__main__":
    unittest.main()
