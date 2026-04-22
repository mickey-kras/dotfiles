using System.Text.Json;
using DotfilesWizard;

namespace DotfilesWizard.Tests;

public class DataModelTests
{
    [Fact]
    public void PackInfo_deserializes_from_json()
    {
        var json = """
            {
                "id": "software-development",
                "label": "Software Development",
                "description": "Dev pack",
                "default_profile": "balanced"
            }
        """;
        var info = JsonSerializer.Deserialize<PackInfo>(json)!;

        Assert.Equal("software-development", info.Id);
        Assert.Equal("Software Development", info.Label);
        Assert.Equal("Dev pack", info.Description);
        Assert.Equal("balanced", info.DefaultProfile);
    }

    [Fact]
    public void PackProfile_deserializes_with_selection()
    {
        var json = """
            {
                "label": "Balanced",
                "description": "A balanced profile",
                "selection": {
                    "mcps": { "enabled": ["github"] },
                    "skills": { "enabled": ["commit"] },
                    "agents": { "enabled": [] },
                    "rules": { "enabled": [] },
                    "permissions": { "enabled": ["file-read"] }
                }
            }
        """;
        var profile = JsonSerializer.Deserialize<PackProfile>(json)!;

        Assert.Equal("Balanced", profile.Label);
        Assert.Equal(["github"], profile.Selection.Mcps.Enabled);
        Assert.Equal(["commit"], profile.Selection.Skills.Enabled);
        Assert.Empty(profile.Selection.Agents.Enabled);
        Assert.Equal(["file-read"], profile.Selection.Permissions.Enabled);
    }

    [Fact]
    public void CatalogItem_deserializes_all_fields()
    {
        var json = """
            {
                "label": "GitHub",
                "description": "GitHub integration",
                "needs_secrets": true,
                "prompt_injection_risk": "low"
            }
        """;
        var item = JsonSerializer.Deserialize<CatalogItem>(json)!;

        Assert.Equal("GitHub", item.Label);
        Assert.Equal("GitHub integration", item.Description);
        Assert.True(item.NeedsSecrets);
        Assert.Equal("low", item.PromptInjectionRisk);
    }

    [Fact]
    public void SettingSchema_deserializes_with_options_and_visible_if()
    {
        var json = """
            {
                "type": "enum",
                "label": "Memory Provider",
                "default": "builtin",
                "options": [
                    { "value": "builtin", "label": "Built-in" },
                    { "value": "obsidian", "label": "Obsidian" }
                ],
                "visible_if": { "some_key": "some_value" }
            }
        """;
        var schema = JsonSerializer.Deserialize<SettingSchema>(json)!;

        Assert.Equal("enum", schema.Type);
        Assert.Equal("Memory Provider", schema.Label);
        Assert.Equal("builtin", schema.Default);
        Assert.Equal(2, schema.Options.Count);
        Assert.Equal("builtin", schema.Options[0].Value);
        Assert.Equal("Obsidian", schema.Options[1].Label);
        Assert.NotNull(schema.VisibleIf);
        Assert.Equal("some_value", schema.VisibleIf!["some_key"]);
    }

    [Fact]
    public void SettingSchema_visible_if_is_null_when_absent()
    {
        var json = """{ "type": "text", "label": "Name", "default": "" }""";
        var schema = JsonSerializer.Deserialize<SettingSchema>(json)!;

        Assert.Null(schema.VisibleIf);
    }

    [Fact]
    public void PackData_deserializes_with_catalogs_and_settings_schema()
    {
        var json = """
            {
                "id": "test-pack",
                "label": "Test Pack",
                "description": "A test pack",
                "defaults": {
                    "profile": "default",
                    "selection": {
                        "mcps": { "enabled": [] },
                        "skills": { "enabled": [] },
                        "agents": { "enabled": [] },
                        "rules": { "enabled": [] },
                        "permissions": { "enabled": [] }
                    }
                },
                "profiles": {
                    "default": {
                        "label": "Default",
                        "description": "Default profile",
                        "selection": {
                            "mcps": { "enabled": ["github"] },
                            "skills": { "enabled": [] },
                            "agents": { "enabled": [] },
                            "rules": { "enabled": [] },
                            "permissions": { "enabled": [] }
                        }
                    }
                },
                "catalogs": {
                    "mcps": {
                        "github": {
                            "label": "GitHub",
                            "description": "GitHub MCP",
                            "needs_secrets": true,
                            "prompt_injection_risk": "low"
                        }
                    }
                },
                "settings_schema": {
                    "memory_provider": {
                        "type": "enum",
                        "label": "Memory Provider",
                        "default": "builtin",
                        "options": []
                    }
                }
            }
        """;
        var pack = JsonSerializer.Deserialize<PackData>(json)!;

        Assert.Equal("test-pack", pack.Id);
        Assert.Equal("default", pack.Defaults.Profile);
        Assert.Single(pack.Profiles);
        Assert.True(pack.Catalogs["mcps"].ContainsKey("github"));
        Assert.True(pack.SettingsSchema.ContainsKey("memory_provider"));
    }

    [Fact]
    public void PackData_defaults_to_empty_collections()
    {
        var pack = new PackData();

        Assert.Equal("", pack.Id);
        Assert.Empty(pack.Profiles);
        Assert.Empty(pack.Catalogs);
        Assert.Empty(pack.SettingsSchema);
    }

    [Fact]
    public void EnabledList_defaults_to_empty()
    {
        var list = new EnabledList();
        Assert.Empty(list.Enabled);
    }
}
