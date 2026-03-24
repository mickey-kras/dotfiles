# One-command bootstrap for Windows
# Usage: irm https://raw.githubusercontent.com/mickey-kras/dotfiles-claude/main/scripts/bootstrap.ps1 | iex

$ErrorActionPreference = "Stop"
$Repo = "mickey-kras/dotfiles-claude"

# --- Logo ---
Write-Host ""
Write-Host "  ____    _    ____ _____ " -ForegroundColor Cyan
Write-Host " |  _ \  / \  / ___|_   _|" -ForegroundColor Cyan
Write-Host " | |_) |/ _ \| |     | |  " -ForegroundColor Cyan
Write-Host " |  __// ___ \ |___  | |  " -ForegroundColor Cyan
Write-Host " |_|  /_/   \_\____| |_|  " -ForegroundColor Cyan
Write-Host ""
Write-Host "  People & AI Conduct Terms" -ForegroundColor White
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
  enable_api_mcps = false
  azure_devops_org = "$azureDevOpsOrg"
"@ | Set-Content "$configDir\chezmoi.toml"
Write-Host "  + Config saved" -ForegroundColor Green

# --- Clear stale chezmoi state and source for a clean init ---
$chezmoiSrc = "$env:USERPROFILE\.local\share\chezmoi"
$dotfilesDir = "$env:USERPROFILE\dotfiles-claude"
# Remove symlink/junction or stale clone so chezmoi init starts fresh
if ((Test-Path $chezmoiSrc) -and ((Get-Item $chezmoiSrc).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    Remove-Item $chezmoiSrc -Force
}
if (Test-Path $chezmoiSrc) { Remove-Item $chezmoiSrc -Recurse -Force }
# Remove cached promptOnce answers so our config values take effect
Remove-Item "$configDir\chezmoistate.boltdb" -ErrorAction SilentlyContinue
Remove-Item "$configDir\chezmoistate" -ErrorAction SilentlyContinue

# --- Init + apply (fresh clone — no stale templates) ---
Write-Host ""
Write-Host "Applying dotfiles..." -ForegroundColor White
chezmoi init --apply "git@github.com:${Repo}.git"

# --- Consolidate source: ~/dotfiles-claude + junction ---
if ((Test-Path $chezmoiSrc) -and -not ((Get-Item $chezmoiSrc).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    if (Test-Path $dotfilesDir) {
        Remove-Item $chezmoiSrc -Recurse -Force
    } else {
        Move-Item $chezmoiSrc $dotfilesDir
    }
    New-Item -ItemType Junction -Path $chezmoiSrc -Target $dotfilesDir | Out-Null
    Write-Host "  + Source linked: $chezmoiSrc -> $dotfilesDir" -ForegroundColor Green
}

# --- Bitwarden setup (if API MCPs enabled) ---
if ($enableApiMcps) {
    if (-not (Get-Command bw -ErrorAction SilentlyContinue)) {
        Write-Host ""
        Write-Host "Bitwarden CLI required for API MCPs" -ForegroundColor White
        $bwInstall = Read-Host "Install now? [Y/n]"
        if ($bwInstall -ne "n" -and $bwInstall -ne "N") {
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                winget install Bitwarden.CLI --accept-package-agreements --accept-source-agreements
            } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
                choco install bitwarden-cli -y
            } elseif (Get-Command npm -ErrorAction SilentlyContinue) {
                npm install -g @bitwarden/cli
            } else {
                Write-Host "  ! Could not detect a supported package manager." -ForegroundColor Red
                Write-Host "  Install manually: https://bitwarden.com/help/cli/" -ForegroundColor Cyan
            }
        }
    }

    if (Get-Command bw -ErrorAction SilentlyContinue) {
        Write-Host ""
        Write-Host "Bitwarden login & unlock" -ForegroundColor White
        $bwStatus = (bw status 2>$null | ConvertFrom-Json).status
        if ($bwStatus -eq "unauthenticated") {
            Write-Host "  * Not logged in. Running bw login..." -ForegroundColor Yellow
            bw login
        }
        Write-Host "  * Unlocking vault..." -ForegroundColor Yellow
        $env:BW_SESSION = bw unlock --raw
        if ($env:BW_SESSION) {
            Write-Host "  + Vault unlocked" -ForegroundColor Green

            # --- Ensure required Bitwarden items exist ---
            $bwItems = @(
                @{ Name = "exa-api-key"; Label = "Exa"; Url = "https://exa.ai" }
                @{ Name = "firecrawl-api-key"; Label = "Firecrawl"; Url = "https://firecrawl.dev" }
                @{ Name = "fal-api-key"; Label = "fal.ai"; Url = "https://fal.ai" }
            )
            $itemsMissing = $false
            foreach ($item in $bwItems) {
                $pw = bw get password $item.Name 2>$null
                if (-not $pw) { $itemsMissing = $true; break }
            }

            if ($itemsMissing) {
                Write-Host ""
                Write-Host "API key setup" -ForegroundColor White
                Write-Host "  Create free accounts and paste API keys below." -ForegroundColor DarkGray
                Write-Host "  Press Enter to skip any service." -ForegroundColor DarkGray
                Write-Host ""
                foreach ($item in $bwItems) {
                    $pw = bw get password $item.Name 2>$null
                    if ($pw) {
                        Write-Host "  + $($item.Label) - already configured" -ForegroundColor Green
                    } else {
                        Write-Host "  $($item.Label) ($($item.Url))" -ForegroundColor Cyan
                        $apiKey = Read-Host "  API key"
                        if ($apiKey) {
                            $template = bw get template item | ConvertFrom-Json
                            $template.name = $item.Name
                            $template.type = 1
                            $template.login.password = $apiKey
                            $template | ConvertTo-Json -Compress | bw encode | bw create item 2>$null | Out-Null
                            $check = bw get password $item.Name 2>$null
                            if ($check) {
                                Write-Host "  + $($item.Label) saved" -ForegroundColor Green
                            } else {
                                Write-Host "  ! Failed to save $($item.Label) - add manually later" -ForegroundColor Red
                            }
                        } else {
                            Write-Host "  * Skipped $($item.Label)" -ForegroundColor Yellow
                        }
                    }
                }
                bw sync 2>$null | Out-Null
            }

            # Enable API MCPs in config and re-apply
            @"
[data]
  enable_api_mcps = true
  azure_devops_org = "$azureDevOpsOrg"
"@ | Set-Content "$configDir\chezmoi.toml"

            Write-Host ""
            Write-Host "Re-applying dotfiles with API keys..." -ForegroundColor White
            chezmoi apply
            Write-Host "  + API MCPs configured" -ForegroundColor Green
        } else {
            Write-Host "  ! Failed to unlock vault." -ForegroundColor Red
            Write-Host '  Run manually: $env:BW_SESSION = $(bw unlock --raw); chezmoi apply' -ForegroundColor Cyan
        }
    } else {
        Write-Host ""
        Write-Host "! Skipping API MCPs - install Bitwarden CLI later and run:" -ForegroundColor Yellow
        Write-Host '  bw login; $env:BW_SESSION = $(bw unlock --raw); chezmoi apply' -ForegroundColor Cyan
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
Write-Host "  Get-Content ~/.codex/AGENTS.md  # Codex global instructions" -ForegroundColor Cyan
Write-Host "  ls ~/.claude/agents/       # Agents" -ForegroundColor Cyan
Write-Host ""
Write-Host "Update later: dotfiles-update" -ForegroundColor DarkGray
