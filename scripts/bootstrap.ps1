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

# --- MCP Selection ---
Write-Host "MCP Configuration" -ForegroundColor White
Write-Host ""
Write-Host "  + Playwright        — Browser automation, E2E testing" -ForegroundColor Green
Write-Host "  + Context7          — Up-to-date library docs" -ForegroundColor Green
Write-Host "  + Sentry            — Error tracking, stack traces (OAuth)" -ForegroundColor Green
Write-Host "  + Figma             — Design-to-code (OAuth)" -ForegroundColor Green
Write-Host ""
Write-Host "  Optional:" -ForegroundColor White
Write-Host "  [1] Azure DevOps     — Work items, PRs, pipelines" -ForegroundColor Cyan
Write-Host "  [2] API MCPs         — Exa, Firecrawl, fal-ai (requires Bitwarden)" -ForegroundColor Cyan
Write-Host ""

$enableAzureDevOps = $false
$azureDevOpsOrg = ""
$enableApiMcps = $false

$choices = Read-Host "Enter numbers to enable (e.g. 1 2), or press Enter for core only"

foreach ($choice in ($choices -split '\s+')) {
    switch ($choice) {
        "1" {
            $azureDevOpsOrg = Read-Host "`nAzure DevOps org name"
            if ($azureDevOpsOrg) {
                $enableAzureDevOps = $true
                Write-Host "  + Azure DevOps org: $azureDevOpsOrg" -ForegroundColor Green
            } else {
                Write-Host "  * No org name - skipping Azure DevOps" -ForegroundColor Yellow
            }
        }
        "2" {
            $enableApiMcps = $true
            Write-Host "  + API MCPs enabled" -ForegroundColor Green
        }
        "" { }
        default {
            Write-Host "  * Unknown option: $choice (skipped)" -ForegroundColor Yellow
        }
    }
}

# --- Write chezmoi config ---
Write-Host ""
Write-Host "Writing chezmoi config..." -ForegroundColor DarkGray
$configDir = "$env:USERPROFILE\.config\chezmoi"
New-Item -ItemType Directory -Path $configDir -Force | Out-Null
@"
[data]
  enable_api_mcps = $($enableApiMcps.ToString().ToLower())
  azure_devops_org = "$azureDevOpsOrg"
"@ | Set-Content "$configDir\chezmoi.toml"
Write-Host "  + Config saved" -ForegroundColor Green

# --- Init + apply (no prompts — config already written) ---
Write-Host ""
Write-Host "Applying dotfiles..." -ForegroundColor White
chezmoi init --apply "git@github.com:${Repo}.git"

# --- Bitwarden check (if API MCPs enabled) ---
if ($enableApiMcps) {
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
Write-Host "Update later: dotfiles-update" -ForegroundColor DarkGray
