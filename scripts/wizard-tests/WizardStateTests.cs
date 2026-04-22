using System.Text.Json;
using DotfilesWizard;

namespace DotfilesWizard.Tests;

public class WizardStateTests
{
    [Fact]
    public void FromProfile_creates_state_with_correct_values()
    {
        var profile = new PackProfile
        {
            Label = "Balanced",
            Description = "A balanced profile",
            Selection = new PackSelection
            {
                Mcps = new EnabledList { Enabled = ["github", "context7"] },
                Skills = new EnabledList { Enabled = ["commit"] },
                Agents = new EnabledList { Enabled = ["planner"] },
                Rules = new EnabledList { Enabled = ["security"] },
                Permissions = new EnabledList { Enabled = ["file-read"] },
            },
        };

        var state = WizardState.FromProfile("software-development", "balanced", profile);

        Assert.Equal("software-development", state.CapabilityPack);
        Assert.Equal("balanced", state.ProfileSelected);
        Assert.Equal("preset", state.ProfileMode);
        Assert.Equal(["github", "context7"], state.EnabledMcps);
        Assert.Equal(["commit"], state.EnabledSkills);
        Assert.Equal(["planner"], state.EnabledAgents);
        Assert.Equal(["security"], state.EnabledRules);
        Assert.Equal(["file-read"], state.EnabledPermissions);
    }

    [Fact]
    public void FromProfile_copies_lists_independently()
    {
        var profile = new PackProfile
        {
            Selection = new PackSelection
            {
                Mcps = new EnabledList { Enabled = ["github"] },
            },
        };

        var state = WizardState.FromProfile("pack", "profile", profile);
        state.EnabledMcps.Add("extra");

        Assert.Single(profile.Selection.Mcps.Enabled);
        Assert.Equal(2, state.EnabledMcps.Count);
    }

    [Fact]
    public void FromProfile_converts_settings_from_json_elements()
    {
        var settingsJson = """{"memory_provider": "builtin", "vault": "/path"}""";
        var settingsDict = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(settingsJson)!;

        var profile = new PackProfile
        {
            Selection = new PackSelection { Settings = settingsDict },
        };

        var state = WizardState.FromProfile("pack", "profile", profile);

        Assert.Equal("builtin", state.Settings["memory_provider"]);
        Assert.Equal("/path", state.Settings["vault"]);
    }

    [Fact]
    public void ToDict_returns_all_fields()
    {
        var state = new WizardState
        {
            CapabilityPack = "software-development",
            ProfileSelected = "balanced",
            ProfileMode = "preset",
            EnabledMcps = ["github"],
            EnabledSkills = ["commit"],
            EnabledAgents = [],
            EnabledRules = [],
            EnabledPermissions = [],
            Settings = new Dictionary<string, string>
            {
                ["memory_provider"] = "builtin",
                ["user_name"] = "Misha",
            },
        };

        var dict = state.ToDict();

        Assert.Equal("software-development", dict["capability_pack"]);
        Assert.Equal("balanced", dict["profile_selected"]);
        Assert.Equal("preset", dict["profile_mode"]);
        Assert.Equal(new List<string> { "github" }, dict["selection_enabled_mcps"]);
        Assert.Equal(new List<string> { "commit" }, dict["selection_enabled_skills"]);
        Assert.Equal("builtin", dict["memory_provider"]);
        Assert.Equal("Misha", dict["user_name"]);
    }

    [Fact]
    public void ToDict_settings_keys_are_flattened_into_dict()
    {
        var state = new WizardState
        {
            Settings = new Dictionary<string, string>
            {
                ["custom_key"] = "custom_value",
            },
        };

        var dict = state.ToDict();

        Assert.True(dict.ContainsKey("custom_key"));
        Assert.Equal("custom_value", dict["custom_key"]);
    }
}
