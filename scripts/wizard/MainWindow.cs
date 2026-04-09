using Terminal.Gui;
using Terminal.Gui.App;
using Terminal.Gui.Configuration;
using Terminal.Gui.Drawing;
using Terminal.Gui.Input;
using Terminal.Gui.ViewBase;
using Terminal.Gui.Views;
using Attribute = Terminal.Gui.Drawing.Attribute;

namespace DotfilesWizard;

public sealed class MainWindow : Window
{
    private readonly string _sourceDir;
    private readonly string _stateFile;

    private WizardState _state;
    private PackData _pack;
    private List<PackInfo> _packs;

    private TabView _tabView = null!;
    private Label _summaryLabel = null!;
    private Button _applyButton = null!;
    private Button _exitButton = null!;

    // Pack/Profile tab - custom hoverable radio items
    private List<Label> _packItems = [];
    private List<Label> _profileItems = [];
    private int _packSelectedIdx;
    private int _profileSelectedIdx;

    // Catalog tab scroll views with checkboxes
    private readonly Dictionary<string, List<CheckBox>> _catalogChecks = [];

    // Settings tab controls
    private readonly List<(string Key, View Control)> _settingControls = [];
    private View _settingsContainer = null!;
    private bool _rebuildingSettings;

    // MCP settings section
    private View _mcpSettingsContainer = null!;
    private readonly List<(string Key, View Control)> _mcpSettingControls = [];
    private bool _rebuildingMcpSettings;

    // Chezmoi data for pre-filling user profile fields
    private readonly Dictionary<string, string> _chezmoiData;

    public bool Applied { get; private set; }

    private const int MinCols = 80;
    private const int MinRows = 30;

    public MainWindow(string sourceDir, string stateFile)
    {
        _sourceDir = sourceDir;
        _stateFile = stateFile;

        _packs = PackStateHelper.ListPacks(sourceDir);
        _chezmoiData = LoadChezmoiData();
        _state = InitState();
        _pack = PackStateHelper.LoadPack(sourceDir, _state.CapabilityPack);

        Title = "Dotfiles Setup";
        Width = Dim.Fill();
        Height = Dim.Fill();

        var scheme = CreateColorScheme();
        SchemeManager.AddScheme("Dotfiles", scheme);
        SchemeName = "Dotfiles";

        var hoverScheme = CreateHoverScheme();
        SchemeManager.AddScheme("DotfilesHover", hoverScheme);

        BuildUi();
        CheckTerminalSize();
        Application.SizeChanging += (_, _) => CheckTerminalSize();
    }

    private Label? _sizeWarning;

    private void CheckTerminalSize()
    {
        var cols = Application.Screen.Width;
        var rows = Application.Screen.Height;
        if (cols < MinCols || rows < MinRows)
        {
            if (_sizeWarning == null)
            {
                _sizeWarning = new Label
                {
                    X = Pos.Center(), Y = Pos.Center(),
                    Width = Dim.Auto(), Height = 1,
                    Text = $"Terminal too small ({cols}x{rows}). Minimum: {MinCols}x{MinRows}. Please resize.",
                };
                Add(_sizeWarning);
            }
            _sizeWarning.Visible = true;
            _tabView.Visible = false;
        }
        else
        {
            if (_sizeWarning != null)
                _sizeWarning.Visible = false;
            _tabView.Visible = true;
        }
    }

    private static Scheme CreateColorScheme()
    {
        var baseScheme = SchemeManager.GetScheme("Base");
        var bg = ToColor(ThemeColors.Background);
        var fg = ToColor(ThemeColors.Foreground);
        var accent = ToColor(ThemeColors.Accent);
        var activeBg = ToColor(ThemeColors.ActiveBackground);
        return baseScheme with
        {
            Normal = new Attribute(fg, bg),
            Focus = new Attribute(fg, bg),
            HotNormal = new Attribute(fg, bg),
            HotFocus = new Attribute(fg, bg),
            Disabled = new Attribute(new Color(128, 128, 128), bg),
            Active = new Attribute(accent, activeBg),
            Highlight = new Attribute(fg, bg),
            Editable = new Attribute(fg, new Color(88, 88, 88)),
            ReadOnly = new Attribute(accent, new Color(18, 18, 18)),
        };
    }

    private static Scheme CreateHoverScheme()
    {
        var hoverFg = ToColor(ThemeColors.HoverForeground);
        var hoverBg = ToColor(ThemeColors.HoverBackground);
        return SchemeManager.GetScheme("Dotfiles") with
        {
            Normal = new Attribute(hoverFg, hoverBg),
            Focus = new Attribute(hoverFg, hoverBg),
            HotNormal = new Attribute(hoverFg, hoverBg),
            HotFocus = new Attribute(hoverFg, hoverBg),
        };
    }

    private static Color ToColor(Rgb rgb) => new(rgb.R, rgb.G, rgb.B);

    private static void AttachHover(View view)
    {
        view.SchemeName = "Dotfiles";
        view.WantMousePositionReports = true;
        view.MouseEnter += (_, _) => { view.SchemeName = "DotfilesHover"; };
        view.MouseLeave += (_, _) => { view.SchemeName = "Dotfiles"; };
    }

    private static Dictionary<string, string> LoadChezmoiData()
    {
        var configPath = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
            ".config", "chezmoi", "chezmoi.toml");
        return WizardHelpers.ParseChezmoiToml(configPath);
    }

    private WizardState InitState()
    {
        if (File.Exists(_stateFile) && File.ReadAllText(_stateFile).Trim().Length > 0)
        {
            var state = PackStateHelper.ReadState(_stateFile);
            if (!string.IsNullOrEmpty(state.CapabilityPack))
            {
                PreFillSettingsFromChezmoi(state);
                return state;
            }
        }

        var defaultPack = _packs[0];
        var pack = PackStateHelper.LoadPack(_sourceDir, defaultPack.Id);
        var profile = pack.Profiles[pack.Defaults.Profile];
        var state2 = WizardState.FromProfile(defaultPack.Id, pack.Defaults.Profile, profile);
        PreFillSettingsFromChezmoi(state2);
        PackStateHelper.WriteState(_stateFile, state2);
        return state2;
    }

    private void PreFillSettingsFromChezmoi(WizardState state) =>
        WizardHelpers.PreFillSettingsFromChezmoi(state, _chezmoiData);

    private void BuildUi()
    {
        var logo = new Label
        {
            X = 1, Y = 0,
            Width = Dim.Fill(1),
            Height = 7,
            Text = "  ____        _    __ _ _\n"
                 + " |  _ \\  ___ | |_ / _(_) | ___  ___\n"
                 + " | | | |/ _ \\| __| |_| | |/ _ \\/ __|\n"
                 + " | |_| | (_) | |_|  _| | |  __/\\__ \\\n"
                 + " |____/ \\___/ \\__|_| |_|_|\\___||___/\n"
                 + "\n"
                 + "              .dotfiles",
        };
        Add(logo);

        var tools = DetectTools();
        var toolLabel = new Label
        {
            X = 1, Y = 7,
            Width = Dim.Fill(1),
            Height = 1,
            Text = tools,
        };
        Add(toolLabel);

        _summaryLabel = new Label
        {
            X = 1, Y = 9,
            Width = Dim.Fill(1),
            Height = 1,
            Text = GetSummaryText(),
        };
        Add(_summaryLabel);

        _tabView = new TabView
        {
            X = 0, Y = 11,
            Width = Dim.Fill(),
            Height = Dim.Fill(2),
            CanFocus = true,
        };
        _tabView.Style.ShowBorder = true;
        _tabView.Style.ShowTopLine = true;
        _tabView.Style.TabsOnBottom = false;

        _tabView.AddTab(BuildPackProfileTab(), false);
        _tabView.AddTab(BuildMcpTab(), false);
        _tabView.AddTab(BuildCatalogTab("Skills", "skills", _state.EnabledSkills), false);
        _tabView.AddTab(BuildCatalogTab("Agents", "agents", _state.EnabledAgents), false);
        _tabView.AddTab(BuildCatalogTab("Rules", "rules", _state.EnabledRules), false);
        _tabView.AddTab(BuildCatalogTab("Permissions", "permissions", _state.EnabledPermissions), false);
        _tabView.AddTab(BuildSettingsTab(), false);

        Add(_tabView);

        _applyButton = new Button
        {
            Text = "Apply",
            X = Pos.Center() - 10,
            Y = Pos.Bottom(_tabView),
            IsDefault = false,
        };
        _applyButton.Accepting += (_, e) =>
        {
            SaveState();
            Applied = true;
            Application.RequestStop();
            e.Handled = true;
        };

        _exitButton = new Button
        {
            Text = "Quit",
            X = Pos.Center() + 4,
            Y = Pos.Bottom(_tabView),
        };
        _exitButton.Accepting += (_, e) =>
        {
            Application.RequestStop();
            e.Handled = true;
        };

        Add(_applyButton, _exitButton);
    }

    private static string DetectTools()
    {
        var parts = new List<string>();

        if (ToolExists("claude"))
            parts.Add("[+] Claude Code");
        else
            parts.Add("[x] Claude Code");

        if (Directory.Exists(Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".cursor"))
            || Directory.Exists("/Applications/Cursor.app"))
            parts.Add("[+] Cursor");
        else
            parts.Add("[x] Cursor");

        if (ToolExists("codex"))
            parts.Add("[+] Codex");
        else
            parts.Add("[x] Codex");

        return string.Join("  ", parts);
    }

    private static bool ToolExists(string name)
    {
        try
        {
            var psi = new System.Diagnostics.ProcessStartInfo
            {
                FileName = "which",
                Arguments = name,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true,
            };
            using var proc = System.Diagnostics.Process.Start(psi);
            proc?.WaitForExit(2000);
            return proc?.ExitCode == 0;
        }
        catch
        {
            return false;
        }
    }

    private string GetSummaryText() =>
        WizardHelpers.GetSummaryText(_state, _pack.Label);

    private void UpdateSummary()
    {
        _summaryLabel.Text = GetSummaryText();
    }

    // -----------------------------------------------------------------------
    // Hoverable radio items (replaces RadioGroup for per-item hover)
    // -----------------------------------------------------------------------

    private static string FormatRadioItem(string label, bool selected) =>
        WizardHelpers.FormatRadioItem(label, selected);

    private List<Label> BuildRadioItems(
        View container, string[] labels, int selectedIdx, Action<int> onSelect)
    {
        var items = new List<Label>();
        for (var i = 0; i < labels.Length; i++)
        {
            var idx = i;
            var lbl = new Label
            {
                X = 0, Y = i,
                Width = Dim.Fill(),
                Height = 1,
                Text = FormatRadioItem(labels[i], i == selectedIdx),
                CanFocus = true,
            };
            AttachHover(lbl);
            lbl.MouseClick += (_, args) =>
            {
                if (args.Flags.HasFlag(MouseFlags.Button1Clicked))
                {
                    for (var j = 0; j < items.Count; j++)
                        items[j].Text = FormatRadioItem(labels[j], j == idx);
                    onSelect(idx);
                    args.Handled = true;
                }
            };
            items.Add(lbl);
            container.Add(lbl);
        }
        return items;
    }

    private void UpdateRadioLabels(List<Label> items, string[] labels, int selectedIdx)
    {
        for (var i = 0; i < items.Count; i++)
            items[i].Text = FormatRadioItem(labels[i], i == selectedIdx);
    }

    // -----------------------------------------------------------------------
    // Pack / Profile tab
    // -----------------------------------------------------------------------

    private Tab BuildPackProfileTab()
    {
        var tab = new Tab { DisplayText = " Pack/Profile " };
        var view = new View { Width = Dim.Fill(), Height = Dim.Fill(), CanFocus = true };

        var packFrame = new FrameView
        {
            Title = "Capability Pack",
            X = 1, Y = 0,
            Width = Dim.Fill(1),
            Height = _packs.Count + 2,
            CanFocus = true,
        };

        var packLabels = _packs.Select(p => $"{p.Label} - {p.Description}").ToArray();
        _packSelectedIdx = Math.Max(0, _packs.FindIndex(p => p.Id == _state.CapabilityPack));

        _packItems = BuildRadioItems(packFrame, packLabels, _packSelectedIdx, idx =>
        {
            _packSelectedIdx = idx;
            var packInfo = _packs[idx];
            if (packInfo.Id != _state.CapabilityPack)
                SwitchPack(packInfo.Id);
        });
        view.Add(packFrame);

        var profileFrame = new FrameView
        {
            Title = "Profile",
            X = 1,
            Y = Pos.Bottom(packFrame) + 1,
            Width = Dim.Fill(1),
            Height = Dim.Fill(),
            CanFocus = true,
        };

        BuildProfileItems(profileFrame);
        view.Add(profileFrame);

        tab.View = view;
        return tab;
    }

    private void BuildProfileItems(View container)
    {
        var profileIds = _pack.Profiles.Keys.ToList();
        var profileLabels = _pack.Profiles.Values
            .Select(p => $"{p.Label} - {p.Description}")
            .ToArray();
        _profileSelectedIdx = Math.Max(0, profileIds.IndexOf(_state.ProfileSelected));

        _profileItems = BuildRadioItems(container, profileLabels, _profileSelectedIdx, idx =>
        {
            _profileSelectedIdx = idx;
            var profileId = profileIds[idx];
            if (profileId != _state.ProfileSelected)
                SwitchProfile(profileId);
        });
    }

    private void SwitchPack(string packId)
    {
        _pack = PackStateHelper.LoadPack(_sourceDir, packId);
        var defaultProfile = _pack.Defaults.Profile;
        var profile = _pack.Profiles[defaultProfile];
        _state = WizardState.FromProfile(packId, defaultProfile, profile);
        PreFillSettingsFromChezmoi(_state);
        RebuildUi();
    }

    private void SwitchProfile(string profileId)
    {
        if (!_pack.Profiles.TryGetValue(profileId, out var profile))
            return;
        _state = WizardState.FromProfile(_state.CapabilityPack, profileId, profile);
        PreFillSettingsFromChezmoi(_state);
        RebuildUi();
    }

    private void RebuildUi()
    {
        RemoveAll();
        _catalogChecks.Clear();
        _settingControls.Clear();
        _mcpSettingControls.Clear();
        BuildUi();
        SetNeedsLayout();
    }

    // -----------------------------------------------------------------------
    // MCP tab (catalog in FrameView + MCP-dependent settings in FrameView)
    // -----------------------------------------------------------------------

    private Tab BuildMcpTab()
    {
        var tab = new Tab { DisplayText = " MCPs " };
        var view = new View { Width = Dim.Fill(), Height = Dim.Fill(), CanFocus = true };

        if (!_pack.Catalogs.TryGetValue("mcps", out var catalog) || catalog.Count == 0)
        {
            view.Add(new Label { X = 2, Y = 1, Text = "No MCPs available in this pack." });
            tab.View = view;
            return tab;
        }

        var mcpFrame = new FrameView
        {
            Title = "MCPs",
            X = 1, Y = 0,
            Width = Dim.Fill(1),
            Height = catalog.Count + 2,
            CanFocus = true,
        };

        var enabled = new HashSet<string>(_state.EnabledMcps);
        var checks = new List<CheckBox>();
        var y = 0;

        foreach (var (itemId, item) in catalog)
        {
            var desc = string.IsNullOrEmpty(item.Description) ? itemId : item.Description;
            if (desc.Length > 60)
                desc = desc[..57] + "...";

            var cb = new CheckBox
            {
                X = 1,
                Y = y,
                Width = Dim.Fill(1),
                Text = $" {itemId} - {desc}",
                CheckedState = enabled.Contains(itemId) ? CheckState.Checked : CheckState.UnChecked,
                CanFocus = true,
            };
            var capturedId = itemId;
            cb.CheckedStateChanged += (_, args) =>
            {
                if (args.Value is CheckState.Checked)
                {
                    if (!_state.EnabledMcps.Contains(capturedId))
                        _state.EnabledMcps.Add(capturedId);
                }
                else
                {
                    _state.EnabledMcps.Remove(capturedId);
                }
                SnapProfileIfNeeded();
                UpdateSummary();
                RebuildMcpSettingsContent();
            };
            AttachHover(cb);
            checks.Add(cb);
            mcpFrame.Add(cb);
            y++;
        }

        _catalogChecks["mcps"] = checks;
        view.Add(mcpFrame);

        // MCP Settings FrameView
        _mcpSettingsContainer = new FrameView
        {
            Title = "MCP Settings",
            X = 1,
            Y = Pos.Bottom(mcpFrame) + 1,
            Width = Dim.Fill(1),
            Height = Dim.Fill(),
            CanFocus = true,
        };
        RebuildMcpSettingsInto(_mcpSettingsContainer);
        view.Add(_mcpSettingsContainer);

        tab.View = view;
        return tab;
    }

    private void RebuildMcpSettingsInto(View container)
    {
        _mcpSettingControls.Clear();
        var mcpSettingKeys = GetMcpDependentSettings();
        if (mcpSettingKeys.Count == 0)
        {
            container.Add(new Label { X = 1, Y = 0, Text = "No MCP-specific settings." });
            return;
        }

        var y = 0;
        foreach (var key in mcpSettingKeys)
        {
            if (!_pack.SettingsSchema.TryGetValue(key, out var schema))
                continue;

            var currentValue = _state.Settings.GetValueOrDefault(key, schema.Default ?? "");

            var label = new Label
            {
                X = 1, Y = y,
                Width = 25,
                Text = schema.Label + ":",
            };
            container.Add(label);

            var textField = new TextField
            {
                X = 27, Y = y,
                Width = Dim.Fill(2),
                Text = currentValue,
                CanFocus = true,
            };
            var capturedKey = key;
            textField.TextChanged += (_, _) =>
            {
                _state.Settings[capturedKey] = textField.Text;
                SnapProfileIfNeeded();
            };
            container.Add(textField);
            _mcpSettingControls.Add((key, textField));
            y++;
        }
    }

    private List<string> GetMcpDependentSettings()
    {
        var result = new List<string>();

        if (_state.EnabledMcps.Contains("azure-devops") &&
            _pack.SettingsSchema.ContainsKey("azure_devops_org"))
            result.Add("azure_devops_org");

        return result;
    }

    private void RebuildMcpSettingsContent()
    {
        if (_rebuildingMcpSettings || _mcpSettingsContainer == null)
            return;
        _rebuildingMcpSettings = true;
        try
        {
            _mcpSettingsContainer.RemoveAll();
            RebuildMcpSettingsInto(_mcpSettingsContainer);
            _mcpSettingsContainer.SetNeedsLayout();
            _mcpSettingsContainer.SetNeedsDraw();
        }
        finally
        {
            _rebuildingMcpSettings = false;
        }
    }

    // -----------------------------------------------------------------------
    // Catalog tabs (Skills, Agents, Rules, Permissions)
    // -----------------------------------------------------------------------

    private Tab BuildCatalogTab(string title, string catalogKey, List<string> enabledList)
    {
        var tab = new Tab { DisplayText = $" {title} " };
        var view = new View { Width = Dim.Fill(), Height = Dim.Fill(), CanFocus = true };

        if (!_pack.Catalogs.TryGetValue(catalogKey, out var catalog) || catalog.Count == 0)
        {
            view.Add(new Label { X = 2, Y = 1, Text = $"No {title.ToLowerInvariant()} available in this pack." });
            tab.View = view;
            return tab;
        }

        var enabled = new HashSet<string>(enabledList);
        var checks = new List<CheckBox>();
        var y = 0;

        foreach (var (itemId, item) in catalog)
        {
            var desc = string.IsNullOrEmpty(item.Description) ? itemId : item.Description;
            if (desc.Length > 60)
                desc = desc[..57] + "...";

            var cb = new CheckBox
            {
                X = 2,
                Y = y,
                Width = Dim.Fill(1),
                Text = $" {itemId} - {desc}",
                CheckedState = enabled.Contains(itemId) ? CheckState.Checked : CheckState.UnChecked,
                CanFocus = true,
            };
            var capturedId = itemId;
            var capturedKey = catalogKey;
            cb.CheckedStateChanged += (_, args) =>
            {
                var list = GetEnabledListRef(capturedKey);
                if (args.Value is CheckState.Checked)
                {
                    if (!list.Contains(capturedId))
                        list.Add(capturedId);
                }
                else
                {
                    list.Remove(capturedId);
                }
                SnapProfileIfNeeded();
                UpdateSummary();
            };
            AttachHover(cb);
            checks.Add(cb);
            view.Add(cb);
            y++;
        }

        _catalogChecks[catalogKey] = checks;
        tab.View = view;
        return tab;
    }

    private List<string> GetEnabledListRef(string catalogKey) => catalogKey switch
    {
        "mcps" => _state.EnabledMcps,
        "skills" => _state.EnabledSkills,
        "agents" => _state.EnabledAgents,
        "rules" => _state.EnabledRules,
        "permissions" => _state.EnabledPermissions,
        _ => throw new ArgumentException($"Unknown catalog: {catalogKey}"),
    };

    // -----------------------------------------------------------------------
    // Settings tab (pack settings + user profile)
    // -----------------------------------------------------------------------

    private Tab BuildSettingsTab()
    {
        var tab = new Tab { DisplayText = " Settings " };
        _settingsContainer = new View { Width = Dim.Fill(), Height = Dim.Fill(), CanFocus = true };
        RebuildSettingsInto(_settingsContainer);
        tab.View = _settingsContainer;
        return tab;
    }

    private void RebuildSettingsInto(View container)
    {
        var y = 0;

        var profileFrame = new FrameView
        {
            Title = "User Profile",
            X = 1, Y = y,
            Width = Dim.Fill(1),
            Height = 5,
            CanFocus = true,
        };
        AddUserProfileField(profileFrame, "user_name", "Display Name", 0);
        AddUserProfileField(profileFrame, "user_role_summary", "Role Summary", 1);
        AddUserProfileField(profileFrame, "user_stack_summary", "Stack Summary", 2);
        container.Add(profileFrame);
        y += 6;

        var filteredSettings = _pack.SettingsSchema
            .Where(kv => !IsMcpDependentSetting(kv.Key))
            .ToList();

        if (filteredSettings.Count > 0)
        {
            var visibleCount = 0;
            foreach (var (key, schema) in filteredSettings)
            {
                if (schema.VisibleIf != null)
                {
                    var visible = schema.VisibleIf.All(kv =>
                        _state.Settings.TryGetValue(kv.Key, out var val) && val == kv.Value);
                    if (!visible)
                        continue;
                }
                visibleCount += schema.Type == "enum" ? schema.Options.Count : 1;
                visibleCount++;
            }

            var settingsFrame = new FrameView
            {
                Title = "Pack Settings",
                X = 1, Y = y,
                Width = Dim.Fill(1),
                Height = Dim.Fill(),
                CanFocus = true,
            };

            var sy = 0;
            foreach (var (key, schema) in filteredSettings)
            {
                if (schema.VisibleIf != null)
                {
                    var visible = schema.VisibleIf.All(kv =>
                        _state.Settings.TryGetValue(kv.Key, out var val) && val == kv.Value);
                    if (!visible)
                        continue;
                }

                var currentValue = _state.Settings.GetValueOrDefault(key, schema.Default ?? "");

                var label = new Label
                {
                    X = 1, Y = sy,
                    Width = 25,
                    Text = schema.Label + ":",
                };
                settingsFrame.Add(label);

                if (schema.Type == "enum" && schema.Options.Count > 0)
                {
                    var optionLabels = schema.Options.Select(o => o.Label).ToArray();
                    var currentIdx = schema.Options.FindIndex(o => o.Value == currentValue);

                    var radio = new RadioGroup
                    {
                        X = 27, Y = sy,
                        Width = Dim.Fill(1),
                        RadioLabels = optionLabels,
                        SelectedItem = Math.Max(0, currentIdx),
                        DoubleClickAccepts = false,
                        CanFocus = true,
                    };
                    var capturedKey = key;
                    var capturedOptions = schema.Options;
                    radio.SelectedItemChanged += (_, args) =>
                    {
                        _state.Settings[capturedKey] = capturedOptions[args.SelectedItem ?? 0].Value;
                        SnapProfileIfNeeded();
                        RebuildSettingsContent();
                    };
                    settingsFrame.Add(radio);
                    _settingControls.Add((key, radio));
                    sy += schema.Options.Count;
                }
                else
                {
                    var textField = new TextField
                    {
                        X = 27, Y = sy,
                        Width = Dim.Fill(2),
                        Text = currentValue,
                        CanFocus = true,
                    };
                    var capturedKey = key;
                    textField.TextChanged += (_, _) =>
                    {
                        _state.Settings[capturedKey] = textField.Text;
                        SnapProfileIfNeeded();
                    };
                    settingsFrame.Add(textField);
                    _settingControls.Add((key, textField));
                    sy++;
                }
                sy++;
            }
            container.Add(settingsFrame);
        }
    }

    private void AddUserProfileField(View container, string key, string label, int y)
    {
        var currentValue = _state.Settings.GetValueOrDefault(key, "");

        var lbl = new Label
        {
            X = 1, Y = y,
            Width = 25,
            Text = label + ":",
        };
        container.Add(lbl);

        var textField = new TextField
        {
            X = 27, Y = y,
            Width = Dim.Fill(2),
            Text = currentValue,
            CanFocus = true,
        };
        var capturedKey = key;
        textField.TextChanged += (_, _) =>
        {
            _state.Settings[capturedKey] = textField.Text;
        };
        container.Add(textField);
        _settingControls.Add((key, textField));
    }

    private static bool IsMcpDependentSetting(string key) =>
        WizardHelpers.IsMcpDependentSetting(key);

    private void RebuildSettingsContent()
    {
        if (_rebuildingSettings)
            return;
        _rebuildingSettings = true;
        try
        {
            _settingControls.Clear();
            _settingsContainer.RemoveAll();
            RebuildSettingsInto(_settingsContainer);
            _settingsContainer.SetNeedsLayout();
            _settingsContainer.SetNeedsDraw();
        }
        finally
        {
            _rebuildingSettings = false;
        }
    }

    // -----------------------------------------------------------------------
    // Profile matching
    // -----------------------------------------------------------------------

    private void SnapProfileIfNeeded()
    {
        foreach (var (profileId, profile) in _pack.Profiles)
        {
            if (SelectionMatches(profile))
            {
                _state.ProfileSelected = profileId;
                _state.ProfileMode = "preset";
                var profileIds = _pack.Profiles.Keys.ToList();
                var idx = profileIds.IndexOf(profileId);
                if (idx >= 0 && _profileSelectedIdx != idx)
                {
                    _profileSelectedIdx = idx;
                    var profileLabels = _pack.Profiles.Values
                        .Select(p => $"{p.Label} - {p.Description}")
                        .ToArray();
                    UpdateRadioLabels(_profileItems, profileLabels, idx);
                }
                return;
            }
        }
        _state.ProfileMode = "custom";
    }

    private bool SelectionMatches(PackProfile profile) =>
        WizardHelpers.SelectionMatchesProfile(profile, _state);

    // -----------------------------------------------------------------------
    // Persistence
    // -----------------------------------------------------------------------

    private void SaveState()
    {
        PackStateHelper.WriteState(_stateFile, _state);
    }
}
