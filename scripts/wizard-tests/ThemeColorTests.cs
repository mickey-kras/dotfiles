using DotfilesWizard;

namespace DotfilesWizard.Tests;

public class ThemeColorTests
{
    [Fact]
    public void HoverForeground_matches_Accent()
    {
        Assert.Equal(ThemeColors.Accent, ThemeColors.HoverForeground);
    }

    [Fact]
    public void HoverBackground_matches_ActiveBackground()
    {
        Assert.Equal(ThemeColors.ActiveBackground, ThemeColors.HoverBackground);
    }

    [Fact]
    public void Hover_colors_equal_Active_colors()
    {
        Assert.Equal(ThemeColors.Accent, ThemeColors.HoverForeground);
        Assert.Equal(ThemeColors.ActiveBackground, ThemeColors.HoverBackground);
    }

    [Fact]
    public void Background_is_dark_gray()
    {
        var bg = ThemeColors.Background;
        Assert.Equal(58, bg.R);
        Assert.Equal(58, bg.G);
        Assert.Equal(58, bg.B);
    }

    [Fact]
    public void Foreground_is_white()
    {
        var fg = ThemeColors.Foreground;
        Assert.Equal(255, fg.R);
        Assert.Equal(255, fg.G);
        Assert.Equal(255, fg.B);
    }

    [Fact]
    public void Accent_is_cyan()
    {
        var accent = ThemeColors.Accent;
        Assert.Equal(0, accent.R);
        Assert.Equal(255, accent.G);
        Assert.Equal(255, accent.B);
    }

    [Fact]
    public void ActiveBackground_is_blue()
    {
        var active = ThemeColors.ActiveBackground;
        Assert.Equal(0, active.R);
        Assert.Equal(0, active.G);
        Assert.Equal(215, active.B);
    }

    [Fact]
    public void Hover_foreground_differs_from_normal_foreground()
    {
        Assert.NotEqual(ThemeColors.Foreground, ThemeColors.HoverForeground);
    }

    [Fact]
    public void Hover_background_differs_from_normal_background()
    {
        Assert.NotEqual(ThemeColors.Background, ThemeColors.HoverBackground);
    }

    [Fact]
    public void Rgb_record_equality_works()
    {
        var a = new Rgb(10, 20, 30);
        var b = new Rgb(10, 20, 30);
        var c = new Rgb(10, 20, 31);

        Assert.Equal(a, b);
        Assert.NotEqual(a, c);
    }
}
