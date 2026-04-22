using DotfilesWizard;

namespace DotfilesWizard.Tests;

public class WizardHelpersTests
{
    [Theory]
    [InlineData("Balanced", true, " (*) Balanced")]
    [InlineData("Balanced", false, " ( ) Balanced")]
    [InlineData("Open", true, " (*) Open")]
    [InlineData("", false, " ( ) ")]
    public void FormatRadioItem_formats_correctly(string label, bool selected, string expected)
    {
        Assert.Equal(expected, WizardHelpers.FormatRadioItem(label, selected));
    }

    [Fact]
    public void SetEqual_returns_true_for_equal_sets()
    {
        Assert.True(WizardHelpers.SetEqual(["a", "b", "c"], ["c", "b", "a"]));
    }

    [Fact]
    public void SetEqual_returns_false_for_different_sets()
    {
        Assert.False(WizardHelpers.SetEqual(["a", "b"], ["a", "c"]));
    }

    [Fact]
    public void SetEqual_returns_false_for_different_lengths()
    {
        Assert.False(WizardHelpers.SetEqual(["a"], ["a", "b"]));
    }

    [Fact]
    public void SetEqual_returns_true_for_empty_lists()
    {
        Assert.True(WizardHelpers.SetEqual([], []));
    }

    [Theory]
    [InlineData("azure_devops_org", true)]
    [InlineData("memory_provider", false)]
    [InlineData("obsidian_vault_path", false)]
    [InlineData("user_name", false)]
    [InlineData("", false)]
    public void IsMcpDependentSetting_classifies_correctly(string key, bool expected)
    {
        Assert.Equal(expected, WizardHelpers.IsMcpDependentSetting(key));
    }

    [Fact]
    public void ParseChezmoiToml_parses_key_value_pairs()
    {
        var tempFile = Path.GetTempFileName();
        try
        {
            File.WriteAllText(tempFile, """
                [data]
                user_name = "Misha"
                user_role_summary = "Engineer"
                obsidian_vault_path = "/Users/misha/vault"
            """);
            var data = WizardHelpers.ParseChezmoiToml(tempFile);

            Assert.Equal("Misha", data["user_name"]);
            Assert.Equal("Engineer", data["user_role_summary"]);
            Assert.Equal("/Users/misha/vault", data["obsidian_vault_path"]);
        }
        finally
        {
            File.Delete(tempFile);
        }
    }

    [Fact]
    public void ParseChezmoiToml_handles_section_headers()
    {
        var tempFile = Path.GetTempFileName();
        try
        {
            File.WriteAllText(tempFile, """
                [data]
                key1 = "value1"
                [other]
                key2 = "value2"
            """);
            var data = WizardHelpers.ParseChezmoiToml(tempFile);

            Assert.Equal("value1", data["key1"]);
            Assert.Equal("value2", data["key2"]);
        }
        finally
        {
            File.Delete(tempFile);
        }
    }

    [Fact]
    public void ParseChezmoiToml_returns_empty_for_missing_file()
    {
        var data = WizardHelpers.ParseChezmoiToml("/nonexistent/path/chezmoi.toml");
        Assert.Empty(data);
    }

    [Fact]
    public void ParseChezmoiToml_skips_empty_lines()
    {
        var tempFile = Path.GetTempFileName();
        try
        {
            File.WriteAllText(tempFile, "key1 = \"value1\"\n\nkey2 = \"value2\"\n");
            var data = WizardHelpers.ParseChezmoiToml(tempFile);

            Assert.Equal(2, data.Count);
        }
        finally
        {
            File.Delete(tempFile);
        }
    }

    [Fact]
    public void ParseChezmoiToml_handles_values_with_equals_signs()
    {
        var tempFile = Path.GetTempFileName();
        try
        {
            File.WriteAllText(tempFile, "key = \"val=ue\"");
            var data = WizardHelpers.ParseChezmoiToml(tempFile);

            Assert.Equal("val=ue", data["key"]);
        }
        finally
        {
            File.Delete(tempFile);
        }
    }

    [Fact]
    public void ParseChezmoiToml_handles_unquoted_values()
    {
        var tempFile = Path.GetTempFileName();
        try
        {
            File.WriteAllText(tempFile, "key = true");
            var data = WizardHelpers.ParseChezmoiToml(tempFile);

            Assert.Equal("true", data["key"]);
        }
        finally
        {
            File.Delete(tempFile);
        }
    }

    [Fact]
    public void SelectionMatchesProfile_returns_true_when_matching()
    {
        var profile = new PackProfile
        {
            Selection = new PackSelection
            {
                Mcps = new EnabledList { Enabled = ["github", "context7"] },
                Skills = new EnabledList { Enabled = ["commit"] },
                Agents = new EnabledList { Enabled = [] },
                Rules = new EnabledList { Enabled = ["security"] },
                Permissions = new EnabledList { Enabled = ["file-read"] },
            },
        };
        var state = new WizardState
        {
            EnabledMcps = ["context7", "github"],
            EnabledSkills = ["commit"],
            EnabledAgents = [],
            EnabledRules = ["security"],
            EnabledPermissions = ["file-read"],
        };

        Assert.True(WizardHelpers.SelectionMatchesProfile(profile, state));
    }

    [Fact]
    public void SelectionMatchesProfile_returns_false_when_mcps_differ()
    {
        var profile = new PackProfile
        {
            Selection = new PackSelection
            {
                Mcps = new EnabledList { Enabled = ["github"] },
                Skills = new EnabledList { Enabled = [] },
                Agents = new EnabledList { Enabled = [] },
                Rules = new EnabledList { Enabled = [] },
                Permissions = new EnabledList { Enabled = [] },
            },
        };
        var state = new WizardState
        {
            EnabledMcps = ["github", "context7"],
            EnabledSkills = [],
            EnabledAgents = [],
            EnabledRules = [],
            EnabledPermissions = [],
        };

        Assert.False(WizardHelpers.SelectionMatchesProfile(profile, state));
    }

    [Fact]
    public void PreFillSettingsFromChezmoi_fills_empty_fields()
    {
        var state = new WizardState { Settings = [] };
        var chezmoi = new Dictionary<string, string>
        {
            ["user_name"] = "Misha",
            ["user_role_summary"] = "Engineer",
            ["memory_provider"] = "obsidian",
        };

        WizardHelpers.PreFillSettingsFromChezmoi(state, chezmoi);

        Assert.Equal("Misha", state.Settings["user_name"]);
        Assert.Equal("Engineer", state.Settings["user_role_summary"]);
        Assert.Equal("obsidian", state.Settings["memory_provider"]);
    }

    [Fact]
    public void PreFillSettingsFromChezmoi_does_not_overwrite_existing_values()
    {
        var state = new WizardState
        {
            Settings = new Dictionary<string, string> { ["user_name"] = "Existing" },
        };
        var chezmoi = new Dictionary<string, string> { ["user_name"] = "FromChezmoi" };

        WizardHelpers.PreFillSettingsFromChezmoi(state, chezmoi);

        Assert.Equal("Existing", state.Settings["user_name"]);
    }

    [Fact]
    public void PreFillSettingsFromChezmoi_fills_empty_string_values()
    {
        var state = new WizardState
        {
            Settings = new Dictionary<string, string> { ["user_name"] = "" },
        };
        var chezmoi = new Dictionary<string, string> { ["user_name"] = "Misha" };

        WizardHelpers.PreFillSettingsFromChezmoi(state, chezmoi);

        Assert.Equal("Misha", state.Settings["user_name"]);
    }

    [Fact]
    public void PreFillSettingsFromChezmoi_ignores_unknown_chezmoi_keys()
    {
        var state = new WizardState { Settings = [] };
        var chezmoi = new Dictionary<string, string> { ["unknown_key"] = "value" };

        WizardHelpers.PreFillSettingsFromChezmoi(state, chezmoi);

        Assert.False(state.Settings.ContainsKey("unknown_key"));
    }

    [Fact]
    public void GetSummaryText_preset_mode()
    {
        var state = new WizardState
        {
            ProfileMode = "preset",
            ProfileSelected = "balanced",
            EnabledMcps = ["github", "context7"],
            EnabledSkills = ["commit"],
            EnabledAgents = [],
            EnabledRules = ["security"],
        };

        var summary = WizardHelpers.GetSummaryText(state, "Software Development");

        Assert.Contains("Pack: Software Development", summary);
        Assert.Contains("Profile: balanced", summary);
        Assert.Contains("MCPs: 2", summary);
        Assert.Contains("Skills: 1", summary);
        Assert.Contains("Agents: 0", summary);
        Assert.Contains("Rules: 1", summary);
    }

    [Fact]
    public void GetSummaryText_custom_mode()
    {
        var state = new WizardState
        {
            ProfileMode = "custom",
            ProfileSelected = "balanced",
            EnabledMcps = [],
            EnabledSkills = [],
            EnabledAgents = [],
            EnabledRules = [],
        };

        var summary = WizardHelpers.GetSummaryText(state, "Test Pack");

        Assert.Contains("Profile: custom (from balanced)", summary);
    }
}
