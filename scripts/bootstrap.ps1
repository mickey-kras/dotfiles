# One-command bootstrap for Windows
# Usage: irm https://raw.githubusercontent.com/mickey-kras/dotfiles-claude/main/scripts/bootstrap.ps1 | iex

$ErrorActionPreference = "Stop"
$Repo = "mickey-kras/dotfiles-claude"

# --- Logo ---
Write-Host ""
Write-Host "  __  __ _  __" -ForegroundColor Cyan
Write-Host " |  \/  | |/ /" -ForegroundColor Cyan
Write-Host " | |\/| |   < " -ForegroundColor Cyan
Write-Host " |_|  |_|_|\_\" -ForegroundColor Cyan
Write-Host ""
Write-Host "  AI Toolchain Bootstrap" -ForegroundColor White
Write-Host "  Claude Code - Cursor - Codex" -ForegroundColor DarkGray
Write-Host ""

# --- Install chezmoi if missing ---
if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
    Write-Host "* Installing chezmoi..." -ForegroundColor Yellow
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install twpayne.chezmoi --accept-package-agreements --accept-source-agreements
    } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        choco install chezmoi -y
    } else {
        Invoke-Expression (Invoke-WebRequest -Uri "https://get.chezmoi.io/ps1" -UseBasicParsing).Content
    }
    Write-Host "  + chezmoi installed" -ForegroundColor Green
} else {
    Write-Host "  + chezmoi already installed" -ForegroundColor Green
}

# --- Check dependencies ---
$missing = @()
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { $missing += "git" }
if (-not (Get-Command node -ErrorAction SilentlyContinue)) { $missing += "node" }
if (-not (Get-Command npx -ErrorAction SilentlyContinue)) { $missing += "npx" }

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "! Missing: $($missing -join ', ')" -ForegroundColor Yellow
    Write-Host "  MCPs require node/npx." -ForegroundColor DarkGray
    Write-Host ""
}

# --- Detect AI tools ---
Write-Host ""
Write-Host "Detected tools:" -ForegroundColor White
if (Get-Command claude -ErrorAction SilentlyContinue) { Write-Host "  + Claude Code" -ForegroundColor Green } else { Write-Host "  - Claude Code (not found)" -ForegroundColor DarkGray }
if (Test-Path "$env:LOCALAPPDATA\Programs\cursor") { Write-Host "  + Cursor" -ForegroundColor Green } else { Write-Host "  - Cursor (not found)" -ForegroundColor DarkGray }
if (Get-Command codex -ErrorAction SilentlyContinue) { Write-Host "  + Codex" -ForegroundColor Green } else { Write-Host "  - Codex (not found)" -ForegroundColor DarkGray }
Write-Host ""

# --- Init + apply ---
Write-Host "Running chezmoi init + apply..." -ForegroundColor White
Write-Host "You'll be prompted about optional API-key MCPs (exa, firecrawl, fal-ai)." -ForegroundColor DarkGray
Write-Host "Core setup needs no API keys - OAuth MCPs auth in browser on first use." -ForegroundColor DarkGray
Write-Host ""
chezmoi init --apply "git@github.com:${Repo}.git"

# --- Bitwarden check (if API MCPs enabled) ---
$chezmoiConfig = Get-Content "$env:USERPROFILE\.config\chezmoi\chezmoi.toml" -ErrorAction SilentlyContinue
if ($chezmoiConfig -match 'enable_api_mcps = true') {
    if (Get-Command bw -ErrorAction SilentlyContinue) {
        Write-Host ""
        Write-Host "* API MCPs enabled. Unlock your Bitwarden vault:" -ForegroundColor Yellow
        Write-Host '  $env:BW_SESSION = $(bw unlock --raw)' -ForegroundColor Cyan
        Write-Host "  chezmoi apply" -ForegroundColor Cyan
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "! API MCPs enabled but Bitwarden CLI not found." -ForegroundColor Yellow
        Write-Host "  Install: npm install -g @bitwarden/cli" -ForegroundColor Cyan
        Write-Host '  Then: bw login; $env:BW_SESSION = $(bw unlock --raw); chezmoi apply' -ForegroundColor Cyan
        Write-Host ""
    }
}

# --- Done ---
Write-Host ""
Write-Host "+ Done!" -ForegroundColor Green
Write-Host ""
Write-Host "Verify:" -ForegroundColor White
Write-Host "  claude mcp list            # Claude Code MCPs" -ForegroundColor Cyan
Write-Host "  Get-Content ~/.cursor/mcp.json   # Cursor MCPs" -ForegroundColor Cyan
Write-Host "  Get-Content ~/.codex/config.toml # Codex config" -ForegroundColor Cyan
Write-Host "  ls ~/.claude/agents/       # Agents" -ForegroundColor Cyan
Write-Host ""
Write-Host "Update later: chezmoi update" -ForegroundColor DarkGray
