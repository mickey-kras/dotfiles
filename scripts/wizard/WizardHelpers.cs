using System.Text.Json;
using System.Text.RegularExpressions;

namespace DotfilesWizard;

/// <summary>RGB color value for scheme consistency checks.</summary>
public readonly record struct Rgb(int R, int G, int B);

/// <summary>Color constants shared between schemes. Hover must match Active.</summary>
public static class ThemeColors
{
    public static readonly Rgb Background = new(58, 58, 58);
    public static readonly Rgb Foreground = new(255, 255, 255);
    public static readonly Rgb Accent = new(0, 255, 255);
    public static readonly Rgb ActiveBackground = new(0, 0, 215);

    // Hover highlight uses the same colors as Active
    public static readonly Rgb HoverForeground = Accent;
    public static readonly Rgb HoverBackground = ActiveBackground;

    // Selected highlight: dimmer than hover, for currently-chosen items
    public static readonly Rgb SelectedForeground = new(220, 220, 220);
    public static readonly Rgb SelectedBackground = new(40, 40, 80);
}

public static class WizardHelpers
{
    public static string FormatRadioItem(string label, bool selected)
    {
        return selected ? $" (*) {label}" : $" ( ) {label}";
    }

    public static bool SetEqual(List<string> a, List<string> b) =>
        a.Count == b.Count && new HashSet<string>(a).SetEquals(b);

    public static bool IsMcpDependentSetting(string key) => key switch
    {
        _ => false,
    };

    public static bool IsHiddenSetting(string key) => key switch
    {
        "stitch_api_key" => true,
        _ => false,
    };

    private static readonly Dictionary<string, bool> _toolCache = new();

    /// <summary>Checks whether a CLI tool is on PATH. Result is cached per process.</summary>
    public static bool IsToolAvailable(string tool)
    {
        if (_toolCache.TryGetValue(tool, out var cached))
            return cached;

        var pathEnv = Environment.GetEnvironmentVariable("PATH") ?? "";
        var isWindows = Environment.OSVersion.Platform == PlatformID.Win32NT;
        var separator = isWindows ? ';' : ':';
        var extensions = isWindows ? new[] { ".exe", ".cmd", ".bat", "" } : new[] { "" };

        foreach (var dir in pathEnv.Split(separator, StringSplitOptions.RemoveEmptyEntries))
        {
            foreach (var ext in extensions)
            {
                var candidate = Path.Combine(dir, tool + ext);
                if (File.Exists(candidate))
                {
                    _toolCache[tool] = true;
                    return true;
                }
            }
        }
        _toolCache[tool] = false;
        return false;
    }

    public static List<string> MissingTools(IEnumerable<string> required) =>
        required.Where(t => !IsToolAvailable(t)).ToList();

    public static Dictionary<string, string> ParseChezmoiToml(string configPath)
    {
        var data = new Dictionary<string, string>();
        if (!File.Exists(configPath))
            return data;

        foreach (var line in File.ReadAllLines(configPath))
        {
            var trimmed = line.Trim();
            var eqIndex = trimmed.IndexOf('=');
            if (eqIndex <= 0) continue;
            var key = trimmed[..eqIndex].Trim();
            var value = trimmed[(eqIndex + 1)..].Trim().Trim('"');
            data[key] = value;
        }
        return data;
    }

    public static bool SelectionMatchesProfile(PackProfile profile, WizardState state)
    {
        var sel = profile.Selection;
        return SetEqual(sel.Mcps.Enabled, state.EnabledMcps)
            && SetEqual(sel.Skills.Enabled, state.EnabledSkills)
            && SetEqual(sel.Agents.Enabled, state.EnabledAgents)
            && SetEqual(sel.Rules.Enabled, state.EnabledRules)
            && SetEqual(sel.Permissions.Enabled, state.EnabledPermissions);
    }

    public static void PreFillSettingsFromChezmoi(
        WizardState state, Dictionary<string, string> chezmoiData)
    {
        var profileFields = new[] { "user_name", "user_role_summary", "user_stack_summary" };
        foreach (var key in profileFields)
        {
            if (!state.Settings.ContainsKey(key) || string.IsNullOrEmpty(state.Settings.GetValueOrDefault(key)))
            {
                if (chezmoiData.TryGetValue(key, out var val) && !string.IsNullOrEmpty(val))
                    state.Settings[key] = val;
            }
        }

        var settingsKeys = new[]
        {
            "obsidian_vault_path",
            "memory_provider",
            "install_claude_code",
            "install_codex",
            "install_cursor",
            "install_gemini_cli",
            "install_droid",
            "stitch_api_key",
            "bw_gate_install",
        };
        foreach (var key in settingsKeys)
        {
            if (!state.Settings.ContainsKey(key) || string.IsNullOrEmpty(state.Settings.GetValueOrDefault(key)))
            {
                if (chezmoiData.TryGetValue(key, out var val) && !string.IsNullOrEmpty(val))
                    state.Settings[key] = val;
            }
        }

        if (string.IsNullOrEmpty(state.Settings.GetValueOrDefault("obsidian_vault_path")))
        {
            var detectedVaultPath = DetectObsidianVaultPath();
            if (!string.IsNullOrEmpty(detectedVaultPath))
                state.Settings["obsidian_vault_path"] = detectedVaultPath;
        }
    }

    public static string GetSummaryText(WizardState state, string packLabel)
    {
        var memoryProvider = state.Settings.GetValueOrDefault("memory_provider", "builtin");
        return $"Setup: {packLabel} | MCPs: {state.EnabledMcps.Count} | Skills: {state.EnabledSkills.Count} | " +
               $"Agents: {state.EnabledAgents.Count} | Rules: {state.EnabledRules.Count} | Memory: {memoryProvider}";
    }

    private static string DetectObsidianVaultPath()
    {
        var home = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
        var candidates = new[]
        {
            Path.Combine(home, ".gemini", "settings.json"),
            Path.Combine(home, ".factory", "mcp.json"),
            Path.Combine(home, ".claude.json"),
            Path.Combine(home, ".cursor", "mcp.json"),
            Path.Combine(home, ".codex", "config.toml"),
        };

        foreach (var path in candidates)
        {
            var value = ExtractObsidianVaultPath(path);
            if (!string.IsNullOrEmpty(value))
                return value;
        }

        if (OperatingSystem.IsMacOS())
        {
            var icloudVault = Path.Combine(
                home,
                "Library",
                "Mobile Documents",
                "iCloud~md~obsidian",
                "Documents",
                "memory-vault");
            if (Directory.Exists(Path.GetDirectoryName(icloudVault)!))
                return icloudVault;
        }

        return Path.Combine(home, "Obsidian", "memory-vault");
    }

    private static string ExtractObsidianVaultPath(string path)
    {
        if (!File.Exists(path))
            return "";

        try
        {
            if (path.EndsWith(".json", StringComparison.OrdinalIgnoreCase))
            {
                using var document = JsonDocument.Parse(File.ReadAllText(path));
                if (document.RootElement.TryGetProperty("mcpServers", out var servers))
                {
                    foreach (var serverName in new[] { "obsidian", "memory" })
                    {
                        if (servers.TryGetProperty(serverName, out var server) &&
                            server.TryGetProperty("env", out var env) &&
                            env.TryGetProperty("OBSIDIAN_VAULT_PATH", out var vaultPath))
                        {
                            return vaultPath.GetString() ?? "";
                        }
                    }
                }
            }

            var match = Regex.Match(
                File.ReadAllText(path),
                "OBSIDIAN_VAULT_PATH\\s*=\\s*\"(?<path>[^\"]+)\"",
                RegexOptions.Multiline);
            if (match.Success)
                return match.Groups["path"].Value;
        }
        catch
        {
            // Ignore malformed user files and keep searching.
        }

        return "";
    }
}
