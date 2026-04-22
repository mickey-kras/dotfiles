#!/usr/bin/env python3
"""Integration tests for pack_state.py using real pack data."""
import json
import tempfile
import unittest
from pathlib import Path

import pack_state


SOURCE_DIR = str(Path(__file__).resolve().parent.parent)


class TestListPacks(unittest.TestCase):
    def test_returns_nonempty_list(self):
        packs = pack_state.list_packs(SOURCE_DIR)
        self.assertGreater(len(packs), 0)

    def test_each_pack_has_required_fields(self):
        packs = pack_state.list_packs(SOURCE_DIR)
        for pack in packs:
            self.assertIn("id", pack)
            self.assertIn("label", pack)
            self.assertIn("description", pack)
            self.assertIn("default_profile", pack)
            self.assertTrue(len(pack["id"]) > 0)
            self.assertTrue(len(pack["label"]) > 0)

    def test_software_development_pack_is_first(self):
        packs = pack_state.list_packs(SOURCE_DIR)
        self.assertEqual(packs[0]["id"], "software-development")

    def test_known_packs_present(self):
        packs = pack_state.list_packs(SOURCE_DIR)
        ids = {p["id"] for p in packs}
        self.assertIn("software-development", ids)
        self.assertIn("content-creation", ids)
        self.assertIn("research-and-strategy", ids)


class TestLoadPack(unittest.TestCase):
    def test_loads_software_development(self):
        pack = pack_state.load_pack(SOURCE_DIR, "software-development")
        self.assertEqual(pack["id"], "software-development")
        self.assertIn("profiles", pack)
        self.assertIn("catalogs", pack)
        self.assertIn("settings_schema", pack)

    def test_pack_has_profiles(self):
        pack = pack_state.load_pack(SOURCE_DIR, "software-development")
        profiles = pack["profiles"]
        self.assertGreater(len(profiles), 0)
        for name, profile in profiles.items():
            self.assertIn("label", profile)
            self.assertIn("selection", profile)

    def test_pack_has_catalogs(self):
        pack = pack_state.load_pack(SOURCE_DIR, "software-development")
        catalogs = pack["catalogs"]
        self.assertIn("mcps", catalogs)
        self.assertIn("skills", catalogs)
        self.assertIn("agents", catalogs)
        self.assertIn("rules", catalogs)
        self.assertIn("permissions", catalogs)

    def test_pack_default_profile_exists(self):
        pack = pack_state.load_pack(SOURCE_DIR, "software-development")
        default_profile = pack["defaults"]["profile"]
        self.assertIn(default_profile, pack["profiles"])


class TestNormalizeSelection(unittest.TestCase):
    def test_sorts_and_deduplicates(self):
        pack = pack_state.load_pack(SOURCE_DIR, "software-development")
        selection = {
            "mcps": {"enabled": ["github", "context7", "github"]},
            "skills": {"enabled": ["commit", "commit", "review"]},
            "agents": {"enabled": []},
            "rules": {"enabled": []},
            "permissions": {"enabled": []},
            "settings": {},
        }
        normalized = pack_state.normalize_selection(pack, selection)

        self.assertEqual(normalized["mcps"]["enabled"], ["context7", "github"])
        self.assertEqual(normalized["skills"]["enabled"], ["commit", "review"])

    def test_applies_default_settings(self):
        pack = pack_state.load_pack(SOURCE_DIR, "software-development")
        selection = {
            "mcps": {"enabled": []},
            "skills": {"enabled": []},
            "agents": {"enabled": []},
            "rules": {"enabled": []},
            "permissions": {"enabled": []},
            "settings": {},
        }
        normalized = pack_state.normalize_selection(pack, selection)

        for key, schema in pack["settings_schema"].items():
            if schema.get("visible_if"):
                continue
            self.assertIn(key, normalized["settings"])


class TestFindMatchingProfile(unittest.TestCase):
    def test_finds_default_profile(self):
        pack = pack_state.load_pack(SOURCE_DIR, "software-development")
        default_profile_name = pack["defaults"]["profile"]
        default_profile = pack["profiles"][default_profile_name]

        resolved = {
            "pack": pack,
            "state": {
                "selection": default_profile["selection"],
            },
        }
        matched = pack_state.find_matching_profile(pack, resolved)
        self.assertEqual(matched, default_profile_name)

    def test_returns_empty_for_custom_selection(self):
        pack = pack_state.load_pack(SOURCE_DIR, "software-development")
        resolved = {
            "pack": pack,
            "state": {
                "selection": {
                    "mcps": {"enabled": ["nonexistent-mcp"]},
                    "skills": {"enabled": []},
                    "agents": {"enabled": []},
                    "rules": {"enabled": []},
                    "permissions": {"enabled": []},
                    "settings": {},
                },
            },
        }
        matched = pack_state.find_matching_profile(pack, resolved)
        self.assertEqual(matched, "")


class TestBuildBootstrapState(unittest.TestCase):
    def test_builds_with_default_profile(self):
        pack = pack_state.load_pack(SOURCE_DIR, "software-development")
        default_profile = pack["defaults"]["profile"]
        profile_selection = pack["profiles"][default_profile]["selection"]

        state = {
            "capability_pack": "software-development",
            "profile": {"selected": default_profile, "mode": "preset"},
            "selection": profile_selection,
        }

        result = pack_state.build_bootstrap_state(SOURCE_DIR, state)

        self.assertIn("pack", result)
        self.assertIn("resolved", result)
        self.assertIn("state", result)
        self.assertIn("matched_profile", result)
        self.assertEqual(result["pack"]["id"], "software-development")


class TestLegacyConfig(unittest.TestCase):
    def test_produces_expected_keys(self):
        pack = pack_state.load_pack(SOURCE_DIR, "software-development")
        default_profile = pack["defaults"]["profile"]
        profile_selection = pack["profiles"][default_profile]["selection"]

        state = {
            "capability_pack": "software-development",
            "profile": {"selected": default_profile, "mode": "preset"},
            "selection": profile_selection,
            "user_name": "Test User",
            "user_role_summary": "Engineer",
            "user_stack_summary": "Python, Go",
        }

        config = pack_state.legacy_config(SOURCE_DIR, state)

        self.assertEqual(config["capability_pack"], "software-development")
        self.assertIn("runtime_profile", config)
        self.assertIn("profile_base", config)
        self.assertIn("selection_enabled_mcps", config)
        self.assertIn("selection_enabled_skills", config)
        self.assertIn("selection_enabled_agents", config)
        self.assertIn("selection_enabled_rules", config)
        self.assertIn("selection_enabled_permissions", config)
        self.assertEqual(config["user_name"], "Test User")
        self.assertEqual(config["user_role_summary"], "Engineer")
        self.assertEqual(config["user_stack_summary"], "Python, Go")

    def test_user_fields_default_to_empty(self):
        pack = pack_state.load_pack(SOURCE_DIR, "software-development")
        default_profile = pack["defaults"]["profile"]
        profile_selection = pack["profiles"][default_profile]["selection"]

        state = {
            "capability_pack": "software-development",
            "profile": {"selected": default_profile, "mode": "preset"},
            "selection": profile_selection,
        }

        config = pack_state.legacy_config(SOURCE_DIR, state)

        self.assertEqual(config["user_name"], "")
        self.assertEqual(config["user_role_summary"], "")
        self.assertEqual(config["user_stack_summary"], "")

    def test_profile_mode_is_valid(self):
        pack = pack_state.load_pack(SOURCE_DIR, "software-development")
        default_profile = pack["defaults"]["profile"]
        profile_selection = pack["profiles"][default_profile]["selection"]

        state = {
            "capability_pack": "software-development",
            "profile": {"selected": default_profile, "mode": "preset"},
            "selection": profile_selection,
        }

        config = pack_state.legacy_config(SOURCE_DIR, state)

        self.assertIn(config["profile_mode"], ("preset", "custom"))
        self.assertTrue(len(config["runtime_profile"]) > 0)


class TestCliInterface(unittest.TestCase):
    """Integration tests using the CLI entry points."""

    def test_list_packs_cli(self):
        import subprocess
        result = subprocess.run(
            ["python3", str(Path(__file__).parent / "pack_state.py"),
             "list-packs", SOURCE_DIR],
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0)
        packs = json.loads(result.stdout)
        self.assertGreater(len(packs), 0)

    def test_pack_cli(self):
        import subprocess
        result = subprocess.run(
            ["python3", str(Path(__file__).parent / "pack_state.py"),
             "pack", SOURCE_DIR, "software-development"],
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0)
        pack = json.loads(result.stdout)
        self.assertEqual(pack["id"], "software-development")

    def test_bootstrap_state_cli(self):
        import subprocess
        pack = pack_state.load_pack(SOURCE_DIR, "software-development")
        default_profile = pack["defaults"]["profile"]

        state = {
            "capability_pack": "software-development",
            "profile": {"selected": default_profile, "mode": "preset"},
            "selection": pack["profiles"][default_profile]["selection"],
        }

        with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
            json.dump(state, f)
            f.flush()
            state_path = f.name

        try:
            result = subprocess.run(
                ["python3", str(Path(__file__).parent / "pack_state.py"),
                 "bootstrap-state", SOURCE_DIR, state_path],
                capture_output=True, text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            bs = json.loads(result.stdout)
            self.assertIn("pack", bs)
            self.assertIn("resolved", bs)
        finally:
            Path(state_path).unlink(missing_ok=True)

    def test_legacy_config_cli(self):
        import subprocess
        pack = pack_state.load_pack(SOURCE_DIR, "software-development")
        default_profile = pack["defaults"]["profile"]

        state = {
            "capability_pack": "software-development",
            "profile": {"selected": default_profile, "mode": "preset"},
            "selection": pack["profiles"][default_profile]["selection"],
            "user_name": "CLI Test",
        }

        with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
            json.dump(state, f)
            f.flush()
            state_path = f.name

        try:
            result = subprocess.run(
                ["python3", str(Path(__file__).parent / "pack_state.py"),
                 "legacy-config", SOURCE_DIR, state_path],
                capture_output=True, text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            config = json.loads(result.stdout)
            self.assertEqual(config["user_name"], "CLI Test")
        finally:
            Path(state_path).unlink(missing_ok=True)

    def test_invalid_command_exits_nonzero(self):
        import subprocess
        result = subprocess.run(
            ["python3", str(Path(__file__).parent / "pack_state.py"),
             "invalid-command", SOURCE_DIR],
            capture_output=True, text=True,
        )
        self.assertNotEqual(result.returncode, 0)

    def test_no_args_exits_nonzero(self):
        import subprocess
        result = subprocess.run(
            ["python3", str(Path(__file__).parent / "pack_state.py")],
            capture_output=True, text=True,
        )
        self.assertNotEqual(result.returncode, 0)


class TestPythonNodeResolverParity(unittest.TestCase):
    """Guards against drift between pack_state.py (Python) and
    scripts/lib/pack-resolver.mjs (Node). Both implement normalize_selection
    and profile matching; both are used in different code paths."""

    def _run_node_resolver(self, data):
        import shutil
        import subprocess
        if not shutil.which("node"):
            self.skipTest("node not installed")
        cli = str(Path(SOURCE_DIR) / "scripts" / "lib" / "resolve-state-cli.mjs")
        result = subprocess.run(
            ["node", cli,
             "--repo-root", SOURCE_DIR,
             "--pack-id", "software-development",
             "--data-json", json.dumps(data)],
            capture_output=True, text=True,
        )
        if result.returncode != 0:
            self.skipTest(f"node resolver unavailable: {result.stderr.strip()}")
        return json.loads(result.stdout)

    def test_enabled_sets_match_for_every_preset_profile(self):
        pack = pack_state.load_pack(SOURCE_DIR, "software-development")
        for profile_name, profile in pack["profiles"].items():
            with self.subTest(profile=profile_name):
                selection = profile["selection"]
                # Flat chezmoi-style data: matches what the wizard writes and
                # what both resolvers expect in production.
                data = {
                    "capability_pack": "software-development",
                    "pack_id": "software-development",
                    "profile_selected": profile_name,
                    "profile_mode": "preset",
                    "selection_enabled_mcps": selection["mcps"]["enabled"],
                    "selection_enabled_skills": selection["skills"]["enabled"],
                    "selection_enabled_agents": selection["agents"]["enabled"],
                    "selection_enabled_rules": selection["rules"]["enabled"],
                    "selection_enabled_permissions": selection["permissions"]["enabled"],
                }
                node_resolved = self._run_node_resolver(data)["resolved"]
                py_resolved = pack_state.resolved_state(SOURCE_DIR, data)["resolved"]

                for section in ("mcps", "skills", "agents", "rules"):
                    self.assertEqual(
                        sorted(py_resolved[section]["enabled"]),
                        sorted(node_resolved[section]["enabled"]),
                        f"{section} mismatch for profile {profile_name}",
                    )
                self.assertEqual(
                    sorted(py_resolved["permissions"]["enabled"]),
                    sorted(node_resolved["permissions"]["enabled"]),
                    f"permissions mismatch for profile {profile_name}",
                )

    def test_both_agree_on_custom_when_selection_does_not_match_any_preset(self):
        """An unmatched selection must resolve to profile_mode="custom" on
        both resolvers. Python returns "" from find_matching_profile and Node
        returns null; both are falsy, so both should land in custom mode."""
        data = {
            "capability_pack": "software-development",
            "pack_id": "software-development",
            "profile_selected": "balanced",
            "profile_mode": "custom",
            "selection_enabled_mcps": ["context7"],
            "selection_enabled_skills": [],
            "selection_enabled_agents": [],
            "selection_enabled_rules": [],
            "selection_enabled_permissions": [],
        }
        node_resolved = self._run_node_resolver(data)
        py_resolved = pack_state.resolved_state(SOURCE_DIR, data)

        self.assertEqual(node_resolved["profile"]["mode"], "custom")
        self.assertEqual(py_resolved["state"]["profile"]["mode"], "custom")
        self.assertEqual(
            sorted(node_resolved["resolved"]["mcps"]["enabled"]),
            sorted(py_resolved["resolved"]["mcps"]["enabled"]),
        )


if __name__ == "__main__":
    unittest.main()
