using System.Diagnostics;
using System.Text.Json;
using DotfilesWizard;

namespace DotfilesWizard.Tests;

public class WizardIntegrationTests
{
    private static string SourceDir =>
        Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".."));

    private static string WizardBinary =>
        Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "wizard",
            "bin", "Debug", "net10.0", "DotfilesWizard");

    [Fact]
    public void Wizard_exits_with_1_when_no_args()
    {
        var (exitCode, _, stderr) = RunWizard("");
        Assert.Equal(1, exitCode);
        Assert.Contains("usage:", stderr);
    }

    [Fact]
    public void Wizard_exits_with_1_for_missing_source_dir()
    {
        var (exitCode, _, stderr) = RunWizard("--source /nonexistent --state /tmp/x.json");
        Assert.Equal(1, exitCode);
        Assert.Contains("Source directory not found", stderr);
    }

    [Fact]
    public void Wizard_launches_with_empty_state_file()
    {
        var tempFile = Path.GetTempFileName();
        try
        {
            File.WriteAllText(tempFile, "");
            var (exitCode, stdout, _) = RunWizard(
                $"--source {SourceDir} --state {tempFile}", timeoutMs: 3000);
            Assert.Contains("Dotfiles Setup", stdout);
        }
        finally
        {
            File.Delete(tempFile);
        }
    }

    [Fact]
    public void Wizard_launches_with_empty_json_state()
    {
        var tempFile = Path.GetTempFileName();
        try
        {
            File.WriteAllText(tempFile, "{}");
            var (exitCode, stdout, _) = RunWizard(
                $"--source {SourceDir} --state {tempFile}", timeoutMs: 3000);
            Assert.Contains("Dotfiles Setup", stdout);
        }
        finally
        {
            File.Delete(tempFile);
        }
    }

    [Fact]
    public void Wizard_launches_with_valid_state()
    {
        var tempFile = Path.GetTempFileName();
        try
        {
            var state = new WizardState
            {
                CapabilityPack = "software-development",
                ProfileSelected = "balanced",
                ProfileMode = "preset",
                EnabledMcps = ["github"],
            };
            PackStateHelper.WriteState(tempFile, state);

            var (exitCode, stdout, _) = RunWizard(
                $"--source {SourceDir} --state {tempFile}", timeoutMs: 3000);
            Assert.Contains("Dotfiles Setup", stdout);
        }
        finally
        {
            File.Delete(tempFile);
        }
    }

    [Fact]
    public void Wizard_writes_default_state_for_empty_file()
    {
        var tempFile = Path.GetTempFileName();
        try
        {
            File.WriteAllText(tempFile, "");
            RunWizard($"--source {SourceDir} --state {tempFile}", timeoutMs: 3000);

            var content = File.ReadAllText(tempFile).Trim();
            Assert.True(content.Length > 2, "State file should be written with default state");

            var dict = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(content);
            Assert.NotNull(dict);
            Assert.True(dict!.ContainsKey("capability_pack"));
            Assert.Equal("software-development", dict["capability_pack"].GetString());
        }
        finally
        {
            File.Delete(tempFile);
        }
    }

    private static (int ExitCode, string Stdout, string Stderr) RunWizard(
        string args, int timeoutMs = 5000)
    {
        var binaryPath = WizardBinary;
        if (!File.Exists(binaryPath))
        {
            // Fall back to dotnet run
            binaryPath = "dotnet";
            var projectDir = Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "wizard");
            args = $"run --project {projectDir} -- {args}";
        }

        var psi = new ProcessStartInfo
        {
            FileName = binaryPath,
            Arguments = args,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true,
            Environment = { ["TERM"] = "xterm-256color" },
        };

        using var proc = Process.Start(psi)!;
        var stdout = "";
        var stderr = "";

        var stdoutTask = Task.Run(() => stdout = proc.StandardOutput.ReadToEnd());
        var stderrTask = Task.Run(() => stderr = proc.StandardError.ReadToEnd());

        if (!proc.WaitForExit(timeoutMs))
        {
            proc.Kill();
            proc.WaitForExit(1000);
        }

        stdoutTask.Wait(2000);
        stderrTask.Wait(2000);

        return (proc.ExitCode, stdout, stderr);
    }
}
