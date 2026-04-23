import shutil
import unittest

from helpers import load_yaml_as_json


@unittest.skipUnless(shutil.which("chezmoi"), "chezmoi not installed")
class RuntimeParityTests(unittest.TestCase):
    def setUp(self):
        self.runtime = load_yaml_as_json(".chezmoidata/runtime_profiles.yaml")
        self.capability_packs = load_yaml_as_json(".chezmoidata/capability_packs.yaml")
        self.pack = load_yaml_as_json("packs/software-development/pack.yaml")

    def test_full_profile_mcps_match_current_runtime_catalog(self):
        expected = sorted(self.runtime["mcp_sets"]["full"])
        actual = sorted(self.pack["profiles"]["full"]["selection"]["mcps"]["enabled"])
        self.assertEqual(actual, expected)

    def test_full_profile_permissions_match_current_runtime_catalog(self):
        expected = sorted(self.runtime["profiles"]["full"]["permission_groups"])
        actual = sorted(self.pack["profiles"]["full"]["selection"]["permissions"]["enabled"])
        self.assertEqual(actual, expected)

    def test_guardrails_match_current_runtime_catalog(self):
        self.assertEqual(
            self.pack["guardrails"]["hard_bans"],
            self.runtime["hard_bans"],
        )

    def test_tooling_matches_existing_capability_pack_metadata(self):
        expected = self.capability_packs["packs"]["software-development"]
        actual = self.pack["tooling"]
        self.assertEqual(sorted(actual["claude_agents"]), sorted(expected["claude_agents"]))
        self.assertEqual(sorted(actual["managed_skills"]), sorted(expected["managed_skills"]))
        self.assertEqual(actual["codex_mode"], expected["codex_mode"])
        self.assertEqual(actual["cursor_mode"], expected["cursor_mode"])


if __name__ == "__main__":
    unittest.main()
