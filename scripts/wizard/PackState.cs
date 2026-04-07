using System.Diagnostics;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace DotfilesWizard;

public sealed record PackInfo
{
    [JsonPropertyName("id")] public string Id { get; init; } = "";
    [JsonPropertyName("label")] public string Label { get; init; } = "";
    [JsonPropertyName("description")] public string Description { get; init; } = "";
    [JsonPropertyName("default_profile")] public string DefaultProfile { get; init; } = "";
}

public sealed record PackProfile
{
    [JsonPropertyName("label")] public string Label { get; init; } = "";
    [JsonPropertyName("description")] public string Description { get; init; } = "";
    [JsonPropertyName("selection")] public PackSelection Selection { get; init; } = new();
}

public sealed record PackSelection
{
    [JsonPropertyName("mcps")] public EnabledList Mcps { get; init; } = new();
    [JsonPropertyName("skills")] public EnabledList Skills { get; init; } = new();
    [JsonPropertyName("agents")] public EnabledList Agents { get; init; } = new();
    [JsonPropertyName("rules")] public EnabledList Rules { get; init; } = new();
    [JsonPropertyName("permissions")] public EnabledList Permissions { get; init; } = new();
    [JsonPropertyName("settings")] public Dictionary<string, JsonElement> Settings { get; init; } = [];
}

public sealed record EnabledList
{
    [JsonPropertyName("enabled")] public List<string> Enabled { get; init; } = [];
}

public sealed record CatalogItem
{
    [JsonPropertyName("label")] public string Label { get; init; } = "";
    [JsonPropertyName("description")] public string Description { get; init; } = "";
    [JsonPropertyName("needs_secrets")] public bool NeedsSecrets { get; init; }
    [JsonPropertyName("prompt_injection_risk")] public string PromptInjectionRisk { get; init; } = "";
}

public sealed record SettingSchema
{
    [JsonPropertyName("type")] public string Type { get; init; } = "";
    [JsonPropertyName("label")] public string Label { get; init; } = "";
    [JsonPropertyName("default")] public string Default { get; init; } = "";
    [JsonPropertyName("options")] public List<SettingOption> Options { get; init; } = [];
    [JsonPropertyName("visible_if")] public Dictionary<string, string>? VisibleIf { get; init; }
}

public sealed record SettingOption
{
    [JsonPropertyName("value")] public string Value { get; init; } = "";
    [JsonPropertyName("label")] public string Label { get; init; } = "";
}

public sealed record PackData
{
    [JsonPropertyName("id")] public string Id { get; init; } = "";
    [JsonPropertyName("label")] public string Label { get; init; } = "";
    [JsonPropertyName("description")] public string Description { get; init; } = "";
    [JsonPropertyName("defaults")] public PackDefaults Defaults { get; init; } = new();
    [JsonPropertyName("profiles")] public Dictionary<string, PackProfile> Profiles { get; init; } = [];
    [JsonPropertyName("catalogs")] public Dictionary<string, Dictionary<string, CatalogItem>> Catalogs { get; init; } = [];
    [JsonPropertyName("settings_schema")] public Dictionary<string, SettingSchema> SettingsSchema { get; init; } = [];
}

public sealed record PackDefaults
{
    [JsonPropertyName("profile")] public string Profile { get; init; } = "";
    [JsonPropertyName("selection")] public PackSelection Selection { get; init; } = new();
}

public sealed record BootstrapState
{
    [JsonPropertyName("pack")] public PackData Pack { get; init; } = new();
    [JsonPropertyName("resolved")] public PackSelection Resolved { get; init; } = new();
    [JsonPropertyName("state")] public StateData State { get; init; } = new();
    [JsonPropertyName("matched_profile")] public string MatchedProfile { get; init; } = "";
}

public sealed record StateData
{
    [JsonPropertyName("profile")] public ProfileState Profile { get; init; } = new();
    [JsonPropertyName("selection")] public PackSelection Selection { get; init; } = new();
}

public sealed record ProfileState
{
    [JsonPropertyName("selected")] public string Selected { get; init; } = "";
    [JsonPropertyName("mode")] public string Mode { get; init; } = "";
}

public sealed record WizardState
{
    public string CapabilityPack { get; set; } = "";
    public string ProfileSelected { get; set; } = "";
    public string ProfileMode { get; set; } = "preset";
    public List<string> EnabledMcps { get; set; } = [];
    public List<string> EnabledSkills { get; set; } = [];
    public List<string> EnabledAgents { get; set; } = [];
    public List<string> EnabledRules { get; set; } = [];
    public List<string> EnabledPermissions { get; set; } = [];
    public Dictionary<string, string> Settings { get; set; } = [];

    public Dictionary<string, object> ToDict()
    {
        var dict = new Dictionary<string, object>
        {
            ["capability_pack"] = CapabilityPack,
            ["profile_selected"] = ProfileSelected,
            ["profile_mode"] = ProfileMode,
            ["selection_enabled_mcps"] = EnabledMcps,
            ["selection_enabled_skills"] = EnabledSkills,
            ["selection_enabled_agents"] = EnabledAgents,
            ["selection_enabled_rules"] = EnabledRules,
            ["selection_enabled_permissions"] = EnabledPermissions,
        };
        foreach (var (key, value) in Settings)
            dict[key] = value;
        return dict;
    }

    public static WizardState FromProfile(string packId, string profileId, PackProfile profile)
    {
        var state = new WizardState
        {
            CapabilityPack = packId,
            ProfileSelected = profileId,
            ProfileMode = "preset",
            EnabledMcps = [.. profile.Selection.Mcps.Enabled],
            EnabledSkills = [.. profile.Selection.Skills.Enabled],
            EnabledAgents = [.. profile.Selection.Agents.Enabled],
            EnabledRules = [.. profile.Selection.Rules.Enabled],
            EnabledPermissions = [.. profile.Selection.Permissions.Enabled],
            Settings = [],
        };
        foreach (var (key, value) in profile.Selection.Settings)
            state.Settings[key] = value.ToString();
        return state;
    }
}

public static class PackStateHelper
{
    private static string Run(string sourceDir, params string[] args)
    {
        var helper = Path.Combine(sourceDir, "scripts", "pack_state.py");
        var allArgs = new List<string> { helper };
        allArgs.AddRange(args);

        var psi = new ProcessStartInfo
        {
            FileName = "python3",
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
        };
        foreach (var arg in allArgs)
            psi.ArgumentList.Add(arg);

        using var proc = Process.Start(psi)
            ?? throw new InvalidOperationException("Failed to start python3");
        var output = proc.StandardOutput.ReadToEnd();
        var error = proc.StandardError.ReadToEnd();
        proc.WaitForExit();
        if (proc.ExitCode != 0)
            throw new InvalidOperationException($"pack_state.py failed: {error}");
        return output;
    }

    public static List<PackInfo> ListPacks(string sourceDir)
    {
        var json = Run(sourceDir, "list-packs", sourceDir);
        return JsonSerializer.Deserialize<List<PackInfo>>(json) ?? [];
    }

    public static PackData LoadPack(string sourceDir, string packId)
    {
        var json = Run(sourceDir, "pack", sourceDir, packId);
        return JsonSerializer.Deserialize<PackData>(json) ?? new();
    }

    public static BootstrapState GetBootstrapState(string sourceDir, string stateFile)
    {
        var json = Run(sourceDir, "bootstrap-state", sourceDir, stateFile);
        return JsonSerializer.Deserialize<BootstrapState>(json) ?? new();
    }

    public static void WriteState(string stateFile, WizardState state)
    {
        var json = JsonSerializer.Serialize(state.ToDict(), new JsonSerializerOptions { WriteIndented = true });
        File.WriteAllText(stateFile, json);
    }

    public static WizardState ReadState(string stateFile)
    {
        var json = File.ReadAllText(stateFile);
        var dict = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(json) ?? [];

        return new WizardState
        {
            CapabilityPack = dict.GetValueOrDefault("capability_pack").GetString() ?? "",
            ProfileSelected = dict.GetValueOrDefault("profile_selected").GetString() ?? "",
            ProfileMode = dict.GetValueOrDefault("profile_mode").GetString() ?? "preset",
            EnabledMcps = GetStringList(dict, "selection_enabled_mcps"),
            EnabledSkills = GetStringList(dict, "selection_enabled_skills"),
            EnabledAgents = GetStringList(dict, "selection_enabled_agents"),
            EnabledRules = GetStringList(dict, "selection_enabled_rules"),
            EnabledPermissions = GetStringList(dict, "selection_enabled_permissions"),
            Settings = GetSettings(dict),
        };
    }

    private static List<string> GetStringList(Dictionary<string, JsonElement> dict, string key)
    {
        if (!dict.TryGetValue(key, out var el) || el.ValueKind != JsonValueKind.Array)
            return [];
        return el.EnumerateArray().Select(e => e.GetString() ?? "").ToList();
    }

    private static Dictionary<string, string> GetSettings(Dictionary<string, JsonElement> dict)
    {
        var skip = new HashSet<string>
        {
            "capability_pack", "profile_selected", "profile_mode",
            "selection_enabled_mcps", "selection_enabled_skills",
            "selection_enabled_agents", "selection_enabled_rules",
            "selection_enabled_permissions"
        };
        var settings = new Dictionary<string, string>();
        foreach (var (key, value) in dict)
        {
            if (skip.Contains(key))
                continue;
            settings[key] = value.ValueKind == JsonValueKind.String
                ? value.GetString() ?? ""
                : value.ToString();
        }
        return settings;
    }
}
