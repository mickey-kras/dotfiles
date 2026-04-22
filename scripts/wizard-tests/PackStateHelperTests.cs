using System.Text.Json;
using DotfilesWizard;

namespace DotfilesWizard.Tests;

public class PackStateHelperTests
{
    [Fact]
    public void WriteState_then_ReadState_round_trips()
    {
        var original = new WizardState
        {
            CapabilityPack = "software-development",
            ProfileSelected = "balanced",
            ProfileMode = "preset",
            EnabledMcps = ["github", "context7"],
            EnabledSkills = ["commit", "review"],
            EnabledAgents = ["planner"],
            EnabledRules = ["security"],
            EnabledPermissions = ["file-read", "file-write"],
            Settings = new Dictionary<string, string>
            {
                ["memory_provider"] = "builtin",
                ["user_name"] = "Test User",
            },
        };

        var tempFile = Path.GetTempFileName();
        try
        {
            PackStateHelper.WriteState(tempFile, original);
            var loaded = PackStateHelper.ReadState(tempFile);

            Assert.Equal(original.CapabilityPack, loaded.CapabilityPack);
            Assert.Equal(original.ProfileSelected, loaded.ProfileSelected);
            Assert.Equal(original.ProfileMode, loaded.ProfileMode);
            Assert.Equal(original.EnabledMcps, loaded.EnabledMcps);
            Assert.Equal(original.EnabledSkills, loaded.EnabledSkills);
            Assert.Equal(original.EnabledAgents, loaded.EnabledAgents);
            Assert.Equal(original.EnabledRules, loaded.EnabledRules);
            Assert.Equal(original.EnabledPermissions, loaded.EnabledPermissions);
            Assert.Equal(original.Settings["memory_provider"], loaded.Settings["memory_provider"]);
            Assert.Equal(original.Settings["user_name"], loaded.Settings["user_name"]);
        }
        finally
        {
            File.Delete(tempFile);
        }
    }

    [Fact]
    public void WriteState_produces_valid_json()
    {
        var state = new WizardState
        {
            CapabilityPack = "test-pack",
            ProfileSelected = "default",
            ProfileMode = "preset",
            EnabledMcps = ["mcp1"],
            Settings = new Dictionary<string, string> { ["key1"] = "val1" },
        };

        var tempFile = Path.GetTempFileName();
        try
        {
            PackStateHelper.WriteState(tempFile, state);
            var json = File.ReadAllText(tempFile);
            var parsed = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(json);

            Assert.NotNull(parsed);
            Assert.Equal("test-pack", parsed!["capability_pack"].GetString());
            Assert.Equal("mcp1", parsed["selection_enabled_mcps"][0].GetString());
            Assert.Equal("val1", parsed["key1"].GetString());
        }
        finally
        {
            File.Delete(tempFile);
        }
    }

    [Fact]
    public void ReadState_handles_empty_json_object()
    {
        var tempFile = Path.GetTempFileName();
        try
        {
            File.WriteAllText(tempFile, "{}");
            var state = PackStateHelper.ReadState(tempFile);

            Assert.Equal("", state.CapabilityPack);
            Assert.Equal("", state.ProfileSelected);
            Assert.Equal("preset", state.ProfileMode);
            Assert.Empty(state.EnabledMcps);
            Assert.Empty(state.EnabledSkills);
            Assert.Empty(state.EnabledAgents);
            Assert.Empty(state.EnabledRules);
            Assert.Empty(state.EnabledPermissions);
            Assert.Empty(state.Settings);
        }
        finally
        {
            File.Delete(tempFile);
        }
    }

    [Fact]
    public void ReadState_handles_partial_json()
    {
        var tempFile = Path.GetTempFileName();
        try
        {
            File.WriteAllText(tempFile, """
                {
                    "capability_pack": "my-pack",
                    "selection_enabled_mcps": ["github"]
                }
            """);
            var state = PackStateHelper.ReadState(tempFile);

            Assert.Equal("my-pack", state.CapabilityPack);
            Assert.Equal("", state.ProfileSelected);
            Assert.Equal(["github"], state.EnabledMcps);
            Assert.Empty(state.EnabledSkills);
        }
        finally
        {
            File.Delete(tempFile);
        }
    }

    [Fact]
    public void ReadState_extracts_settings_from_unknown_keys()
    {
        var tempFile = Path.GetTempFileName();
        try
        {
            File.WriteAllText(tempFile, """
                {
                    "capability_pack": "pack",
                    "profile_selected": "profile",
                    "profile_mode": "preset",
                    "user_name": "Misha",
                    "memory_provider": "obsidian"
                }
            """);
            var state = PackStateHelper.ReadState(tempFile);

            Assert.Equal("Misha", state.Settings["user_name"]);
            Assert.Equal("obsidian", state.Settings["memory_provider"]);
            Assert.False(state.Settings.ContainsKey("capability_pack"));
            Assert.False(state.Settings.ContainsKey("profile_selected"));
        }
        finally
        {
            File.Delete(tempFile);
        }
    }

    [Fact]
    public void ReadState_handles_non_string_setting_values()
    {
        var tempFile = Path.GetTempFileName();
        try
        {
            File.WriteAllText(tempFile, """
                {
                    "capability_pack": "pack",
                    "numeric_setting": 42,
                    "bool_setting": true
                }
            """);
            var state = PackStateHelper.ReadState(tempFile);

            Assert.Equal("42", state.Settings["numeric_setting"]);
            Assert.Equal("True", state.Settings["bool_setting"]);
        }
        finally
        {
            File.Delete(tempFile);
        }
    }
}
