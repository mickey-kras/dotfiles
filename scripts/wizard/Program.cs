using System.Text;
using DotfilesWizard;
using Terminal.Gui.App;
using Terminal.Gui.Drawing;

if (args.Length < 4 || args[0] != "--source" || args[2] != "--state")
{
    Console.Error.WriteLine("usage: dotfiles-wizard --source <dir> --state <file>");
    return 1;
}

var sourceDir = args[1];
var stateFile = args[3];

if (!Directory.Exists(sourceDir))
{
    Console.Error.WriteLine($"Source directory not found: {sourceDir}");
    return 1;
}

Application.Init();
try
{
    // Use consistent-width ASCII glyphs for checkbox alignment
    Glyphs.CheckStateChecked = new Rune('x');
    Glyphs.CheckStateUnChecked = new Rune(' ');

    var window = new MainWindow(sourceDir, stateFile);
    Application.Run(window);
    window.Dispose();
    return window.Applied ? 0 : 1;
}
finally
{
    Application.Shutdown();
}
