using Terminal.Gui;
using Terminal.Gui.App;
using Terminal.Gui.ViewBase;
using Terminal.Gui.Views;

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

    // Pack/Profile tab controls
    private RadioGroup _packRadio = null!;
    private RadioGroup _profileRadio = null!;

    // Catalog tab scroll views with checkboxes
    private readonly Dictionary<string, List<CheckBox>> _catalogChecks = [];

    // Settings tab controls
    private readonly List<(string Key, View Control)> _settingControls = [];
    private View _settingsContainer = null!;

    public bool Applied { get; private set; }

    public MainWindow(string sourceDir, string stateFile)
    {
        _sourceDir = sourceDir;
        _stateFile = stateFile;

        _packs = PackStateHelper.ListPacks(sourceDir);
        _state = InitState();
        _pack = PackStateHelper.LoadPack(sourceDir, _state.CapabilityPack);

        Title = "Dotfiles Setup";
        Width = Dim.Fill();
        Height = Dim.Fill();

        BuildUi();
    }

    private WizardState InitState()
    {
        if (File.Exists(_stateFile) && File.ReadAllText(_stateFile).Trim().Length > 0)
            return PackStateHelper.ReadState(_stateFile);

        var defaultPack = _packs[0];
        var pack = PackStateHelper.LoadPack(_sourceDir, defaultPack.Id);
        var profile = pack.Profiles[pack.Defaults.Profile];
        var state = WizardState.FromProfile(defaultPack.Id, pack.Defaults.Profile, profile);
        PackStateHelper.WriteState(_stateFile, state);
        return state;
    }

    private void BuildUi()
    {
        _summaryLabel = new Label
        {
            X = 1,
            Y = 0,
            Width = Dim.Fill(1),
            Height = 1,
            Text = GetSummaryText(),
        };
        Add(_summaryLabel);

        _tabView = new TabView
        {
            X = 0,
            Y = 2,
            Width = Dim.Fill(),
            Height = Dim.Fill(2),
            CanFocus = true,
        };
        _tabView.Style.ShowBorder = true;
        _tabView.Style.ShowTopLine = true;
        _tabView.Style.TabsOnBottom = false;

        _tabView.AddTab(BuildPackProfileTab(), false);
        _tabView.AddTab(BuildCatalogTab("MCPs", "mcps", _state.EnabledMcps), false);
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
            IsDefault = true,
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

    private string GetSummaryText()
    {
        var profileLine = _state.ProfileMode == "preset"
            ? _state.ProfileSelected
            : $"custom (from {_state.ProfileSelected})";
        return $"Pack: {_pack.Label} | Profile: {profileLine} | " +
               $"MCPs: {_state.EnabledMcps.Count} | Skills: {_state.EnabledSkills.Count} | " +
               $"Agents: {_state.EnabledAgents.Count} | Rules: {_state.EnabledRules.Count}";
    }

    private void UpdateSummary()
    {
        _summaryLabel.Text = GetSummaryText();
    }

    // -----------------------------------------------------------------------
    // Pack / Profile tab
    // -----------------------------------------------------------------------

    private Tab BuildPackProfileTab()
    {
        var tab = new Tab { DisplayText = " Pack/Profile " };
        var view = new View { Width = Dim.Fill(), Height = Dim.Fill(), CanFocus = true };

        // Pack selection
        var packFrame = new FrameView
        {
            Title = "Capability Pack",
            X = 1, Y = 0,
            Width = Dim.Fill(1),
            Height = _packs.Count + 2,
            CanFocus = true,
        };

        var packLabels = _packs.Select(p => $"{p.Label} - {p.Description}").ToArray();
        var currentPackIdx = _packs.FindIndex(p => p.Id == _state.CapabilityPack);

        _packRadio = new RadioGroup
        {
            X = 1, Y = 0,
            Width = Dim.Fill(1),
            RadioLabels = packLabels,
            SelectedItem = Math.Max(0, currentPackIdx),
            CanFocus = true,
        };
        _packRadio.SelectedItemChanged += (_, args) =>
        {
            var packInfo = _packs[args.SelectedItem ?? 0];
            if (packInfo.Id == _state.CapabilityPack)
                return;
            SwitchPack(packInfo.Id);
        };
        packFrame.Add(_packRadio);
        view.Add(packFrame);

        // Profile selection
        var profileFrame = new FrameView
        {
            Title = "Profile",
            X = 1,
            Y = Pos.Bottom(packFrame) + 1,
            Width = Dim.Fill(1),
            Height = Dim.Fill(),
            CanFocus = true,
        };

        _profileRadio = BuildProfileRadio();
        profileFrame.Add(_profileRadio);
        view.Add(profileFrame);

        tab.View = view;
        return tab;
    }

    private RadioGroup BuildProfileRadio()
    {
        var profileIds = _pack.Profiles.Keys.ToList();
        var profileLabels = _pack.Profiles.Values
            .Select(p => $"{p.Label} - {p.Description}")
            .ToArray();
        var currentIdx = profileIds.IndexOf(_state.ProfileSelected);

        var radio = new RadioGroup
        {
            X = 1, Y = 0,
            Width = Dim.Fill(1),
            RadioLabels = profileLabels,
            SelectedItem = Math.Max(0, currentIdx),
            CanFocus = true,
        };
        radio.SelectedItemChanged += (_, args) =>
        {
            var profileId = profileIds[args.SelectedItem ?? 0];
            if (profileId == _state.ProfileSelected)
                return;
            SwitchProfile(profileId);
        };
        return radio;
    }

    private void SwitchPack(string packId)
    {
        _pack = PackStateHelper.LoadPack(_sourceDir, packId);
        var defaultProfile = _pack.Defaults.Profile;
        var profile = _pack.Profiles[defaultProfile];
        _state = WizardState.FromProfile(packId, defaultProfile, profile);
        RebuildUi();
    }

    private void SwitchProfile(string profileId)
    {
        if (!_pack.Profiles.TryGetValue(profileId, out var profile))
            return;
        _state = WizardState.FromProfile(_state.CapabilityPack, profileId, profile);
        RebuildUi();
    }

    private void RebuildUi()
    {
        // Remove all subviews and rebuild
        RemoveAll();
        _catalogChecks.Clear();
        _settingControls.Clear();
        BuildUi();
        SetNeedsLayout();
    }

    // -----------------------------------------------------------------------
    // Catalog tabs (MCPs, Skills, Agents, Rules, Permissions)
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
                Text = $"{itemId} - {desc}",
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
    // Settings tab
    // -----------------------------------------------------------------------

    private Tab BuildSettingsTab()
    {
        var tab = new Tab { DisplayText = " Settings " };
        _settingsContainer = new View { Width = Dim.Fill(), Height = Dim.Fill(), CanFocus = true };

        if (_pack.SettingsSchema.Count == 0)
        {
            _settingsContainer.Add(new Label { X = 2, Y = 1, Text = "No settings available for this pack." });
            tab.View = _settingsContainer;
            return tab;
        }

        var y = 1;
        foreach (var (key, schema) in _pack.SettingsSchema)
        {
            // Check visible_if conditions
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
                X = 2, Y = y,
                Width = 25,
                Text = schema.Label + ":",
            };
            _settingsContainer.Add(label);

            if (schema.Type == "enum" && schema.Options.Count > 0)
            {
                var optionLabels = schema.Options.Select(o => o.Label).ToArray();
                var currentIdx = schema.Options.FindIndex(o => o.Value == currentValue);

                var radio = new RadioGroup
                {
                    X = 28, Y = y,
                    Width = Dim.Fill(1),
                    RadioLabels = optionLabels,
                    SelectedItem = Math.Max(0, currentIdx),
                    CanFocus = true,
                };
                var capturedKey = key;
                var capturedOptions = schema.Options;
                radio.SelectedItemChanged += (_, args) =>
                {
                    _state.Settings[capturedKey] = capturedOptions[args.SelectedItem ?? 0].Value;
                    SnapProfileIfNeeded();
                    // Rebuild settings tab if other settings depend on this via visible_if
                    RebuildSettingsContent();
                };
                _settingsContainer.Add(radio);
                _settingControls.Add((key, radio));
                y += schema.Options.Count;
            }
            else
            {
                var textField = new TextField
                {
                    X = 28, Y = y,
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
                _settingsContainer.Add(textField);
                _settingControls.Add((key, textField));
                y++;
            }
            y++;
        }

        tab.View = _settingsContainer;
        return tab;
    }

    private void RebuildSettingsContent()
    {
        // Find the settings tab and rebuild its content
        var tabs = _tabView.Tabs.ToList();
        var settingsTab = tabs.LastOrDefault();
        if (settingsTab == null)
            return;

        _settingControls.Clear();
        _settingsContainer.RemoveAll();
        var newTab = BuildSettingsTab();
        settingsTab.View = newTab.View;
        _tabView.SetNeedsLayout();
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
                // Update profile radio if it exists
                var profileIds = _pack.Profiles.Keys.ToList();
                var idx = profileIds.IndexOf(profileId);
                if (idx >= 0 && _profileRadio.SelectedItem != idx)
                    _profileRadio.SelectedItem = idx;
                return;
            }
        }
        _state.ProfileMode = "custom";
    }

    private bool SelectionMatches(PackProfile profile)
    {
        var sel = profile.Selection;
        return SetEqual(sel.Mcps.Enabled, _state.EnabledMcps)
            && SetEqual(sel.Skills.Enabled, _state.EnabledSkills)
            && SetEqual(sel.Agents.Enabled, _state.EnabledAgents)
            && SetEqual(sel.Rules.Enabled, _state.EnabledRules)
            && SetEqual(sel.Permissions.Enabled, _state.EnabledPermissions);
    }

    private static bool SetEqual(List<string> a, List<string> b) =>
        a.Count == b.Count && new HashSet<string>(a).SetEquals(b);

    // -----------------------------------------------------------------------
    // Persistence
    // -----------------------------------------------------------------------

    private void SaveState()
    {
        PackStateHelper.WriteState(_stateFile, _state);
    }
}
