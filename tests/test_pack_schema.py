import unittest
from pathlib import Path

from helpers import load_yaml_as_json


class PackSchemaTests(unittest.TestCase):
    def test_all_pack_files_validate(self):
        required = {
            "version",
            "id",
            "label",
            "description",
            "defaults",
            "ui",
            "settings_schema",
            "catalogs",
            "guardrails",
            "profiles",
            "tooling",
        }
        pack_files = sorted(Path("packs").glob("*/pack.yaml"))
        self.assertGreaterEqual(len(pack_files), 2)

        for pack_file in pack_files:
            pack = load_yaml_as_json(str(pack_file))
            with self.subTest(pack=pack["id"]):
                self.assertTrue(required.issubset(pack.keys()))
                valid_ids = {"profiles", "settings", *pack["catalogs"].keys()}
                section_ids = {section["id"] for section in pack["ui"]["sections"]}
                self.assertEqual(section_ids, valid_ids)

                catalogs = pack["catalogs"]
                defaults = pack["defaults"]["selection"]["settings"]
                for profile_name, profile in pack["profiles"].items():
                    selection = profile["selection"]
                    for catalog_name in ("mcps", "skills", "agents", "rules", "permissions"):
                        enabled = selection[catalog_name]["enabled"]
                        unknown = sorted(set(enabled) - set(catalogs[catalog_name].keys()))
                        self.assertEqual(
                            unknown,
                            [],
                            msg=f"{profile_name} has unknown {catalog_name}: {unknown}",
                        )
                    for setting_name in selection["settings"].keys():
                        self.assertIn(
                            setting_name,
                            pack["settings_schema"],
                            msg=f"{profile_name} has unknown setting {setting_name}",
                        )
                    merged = {**defaults, **selection["settings"]}
                    for setting_name, schema in pack["settings_schema"].items():
                        if "visible_if" not in schema:
                            continue
                        for controller, value in schema["visible_if"].items():
                            self.assertIn(controller, merged)
                            if merged[controller] == value:
                                self.assertIn(
                                    setting_name,
                                    merged,
                                    msg=f"{profile_name} missing visible setting {setting_name}",
                                )

                tooling = pack["tooling"]
                self.assertEqual(
                    sorted(tooling["claude_agents"]),
                    sorted(catalogs["agents"].keys()),
                )
                self.assertEqual(
                    sorted(tooling["managed_skills"]),
                    sorted(catalogs["skills"].keys()),
                )


if __name__ == "__main__":
    unittest.main()
