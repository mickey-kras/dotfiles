# dotfiles

AI toolchain config synced across machines with [chezmoi](https://chezmoi.io). One command sets up Claude Code, Cursor, and Codex with shared MCPs, agents, and permissions.

## Quick start

**macOS / Linux / WSL / Windows (Git Bash):**
```bash
bash <(curl -sL https://raw.githubusercontent.com/mickey-kras/dotfiles/main/scripts/bootstrap.sh)
```

**Already have chezmoi?**
```bash
chezmoi init --apply git@github.com:mickey-kras/dotfiles.git
```

**Can't use SSH?** The repo is public - HTTPS works without auth:
```bash
chezmoi init --apply https://github.com/mickey-kras/dotfiles.git
```

**No git/SSH access at all?** Download the [zip from GitHub](https://github.com/mickey-kras/dotfiles/archive/refs/heads/main.zip), extract to `~/dotfiles`, then:
```bash
chezmoi init --apply --source ~/dotfiles
```

You'll get two prompts:
1. **Display name** - reused from your local config when available, otherwise prompted once.
2. **API-key MCPs** (exa, firecrawl, fal-ai) - requires Bitwarden CLI. Say no to skip.
3. **Azure DevOps org** - enter your org name, or press Enter to skip.

## What gets installed

### MCPs

All versions are pinned for supply-chain safety. OAuth MCPs authenticate in the browser on first use.

| Server | Transport | Auth | What it does |
|--------|-----------|------|-------------|
| Playwright 0.0.68 | stdio (npx) | None | Browser automation and E2E testing |
| Context7 | Remote HTTP | OAuth | Up-to-date library docs and code examples |
| Figma | Remote HTTP | OAuth | Design-to-code: layouts, tokens, component variants |
| Azure DevOps 2.5.0 | stdio (npx) | PAT/OAuth | Work items, PRs, pipelines, repos (org-scoped) |
| Exa 3.1.9 | stdio (npx) | API key | AI-powered web search |
| Firecrawl 3.11.0 | stdio (npx) | API key | Web scraping and crawling |
| fal-ai 2.1.4 | stdio (npx) | API key | AI image generation |

**API MCPs** (last 3) require [Bitwarden CLI](https://bitwarden.com/help/cli/). Store keys as Login items named `exa-api-key`, `firecrawl-api-key`, `fal-api-key` (API key in the Password field). Then:
```bash
bw login && export BW_SESSION=$(bw unlock --raw) && chezmoi apply
```

### Agents

| Agent | Purpose |
|-------|---------|
| planner | Explores codebase, identifies risks, creates step-by-step implementation plans |
| code-reviewer | Reviews diffs for bugs, security issues, and quality |
| tdd-guide | Guides red-green-refactor cycle with strict TDD discipline |

### Permissions & settings

`~/.claude/settings.json` ships with pre-approved permissions for common dev tools (git, gh, npm, node, docker, az, terraform, kubectl, k6, aws, gcloud, wrangler, etc.), a deny list for dangerous operations (sudo, rm -rf /, etc.), and `model: "opus"` so Claude Code uses the current Opus line by default.

`~/.claude/CLAUDE.md` contains lightweight global preferences (Conventional Commits, feature branches, CLI-first workflow), is rendered with your configured display name, and explicitly ignores Sentry even if it appears locally.

`~/.codex/AGENTS.md` mirrors those same global preferences for Codex, so both tools behave consistently across machines. Cursor gets the same ignore rule through `~/.cursor/rules/global.mdc`.

Global Git hooks are also installed at `~/.config/git/hooks` and enabled through `core.hooksPath`, so the same charset and no-AI-attribution rules are enforced before commit and before push across all local repositories.

## What gets configured

| Tool | Config files |
|------|-------------|
| Claude Code CLI | `~/.claude/CLAUDE.md`, `settings.json`, `agents/` + MCPs via `claude mcp add` |
| Claude Desktop | MCPs merged into `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) |
| Cursor | `~/.cursor/mcp.json`, `~/.cursor/rules/global.mdc` |
| Codex | `~/.codex/config.toml`, `~/.codex/AGENTS.md` |

## Updating

```bash
dotfiles-update   # Pull, apply, check versions, verify MCPs, security scan
```

Installed at `~/.local/bin/dotfiles-update` by chezmoi. Make sure `~/.local/bin` is in your PATH.

On Windows, a `.cmd` wrapper is installed alongside so `dotfiles-update` works from PowerShell and cmd. Requires Git Bash (`bash` in PATH) - included with [Git for Windows](https://gitforwindows.org).

For a quick pull-only update: `chezmoi update`

## File structure

```
.chezmoi.toml.tmpl                    # Setup prompts (API MCPs, Azure DevOps org)
.chezmoiignore                        # Platform-conditional exclusions
dot_claude/
  CLAUDE.md.tmpl                      # -> ~/.claude/CLAUDE.md
  settings.json                       # -> ~/.claude/settings.json
  agents/
    planner.md                        # Planning agent
    code-reviewer.md                  # Code review agent
    tdd-guide.md                      # TDD coaching agent
dot_cursor/
  mcp.json.tmpl                       # -> ~/.cursor/mcp.json
  rules/global.mdc.tmpl               # -> ~/.cursor/rules/global.mdc
dot_codex/
  config.toml.tmpl                    # -> ~/.codex/config.toml
  AGENTS.md.tmpl                      # -> ~/.codex/AGENTS.md
dot_config/
  git/hooks/
    _misha_git_policy.py              # Shared policy checker
    pre-commit                        # Staged content checks
    commit-msg                        # Commit message checks
    pre-push                          # Outgoing commit history checks
dot_local/
  bin/
    executable_dotfiles-update        # -> ~/.local/bin/dotfiles-update
    executable_dotfiles-update.cmd    # -> ~/.local/bin/dotfiles-update.cmd (Windows only)
scripts/
  bootstrap.sh                        # macOS/Linux bootstrap
  bootstrap.ps1                       # Windows bootstrap
  chezmoi/
    run_onchange_after_configure-global-git-hooks.sh.tmpl   # Unix global Git hook setup
    run_onchange_after_configure-global-git-hooks.ps1.tmpl  # Windows global Git hook setup
    run_onchange_after_install-claude-mcps.sh.tmpl          # Unix MCP registration
    run_onchange_after_install-claude-mcps.ps1.tmpl         # Windows MCP registration
```

## Security

- **Pinned versions** - All stdio MCPs use exact version numbers to prevent supply-chain attacks via malicious updates.
- **No secrets in repo** - API keys are fetched from Bitwarden at `chezmoi apply` time.
- **OAuth MCPs** (Context7, Figma) authenticate via browser - no tokens stored locally.
- **Periodic audit** - Run `npx @anthropic-ai/mcp-scan` to scan installed MCPs for tool poisoning.

## Dependencies

**Required:** git, chezmoi (auto-installed by bootstrap), bash (Git Bash on Windows)

**For MCPs:** node, npx

**For API MCPs:** Bitwarden CLI (`bw`)
