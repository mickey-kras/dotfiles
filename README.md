# dotfiles-claude

AI toolchain config synced across machines with [chezmoi](https://chezmoi.io). One command sets up Claude Code, Cursor, and Codex with shared MCPs, agents, and permissions.

## Quick start

**macOS / Linux / WSL:**
```bash
bash <(curl -sL https://raw.githubusercontent.com/mickey-kras/dotfiles-claude/main/scripts/bootstrap.sh)
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/mickey-kras/dotfiles-claude/main/scripts/bootstrap.ps1 | iex
```

**Already have chezmoi?**
```bash
chezmoi init --apply git@github.com:mickey-kras/dotfiles-claude.git
```

You'll get one prompt: whether to enable API-key MCPs (exa, firecrawl, fal-ai). Say no for a zero-config setup.

## What gets installed

### MCPs

All versions are pinned for supply-chain safety. OAuth MCPs authenticate in the browser on first use.

| Server | Transport | Auth | What it does |
|--------|-----------|------|-------------|
| Playwright 0.0.68 | stdio (npx) | None | Browser automation and E2E testing |
| Context7 | Remote HTTP | OAuth | Up-to-date library docs and code examples |
| Sentry | Remote HTTP | OAuth | Error tracking: stack traces, breadcrumbs, release health |
| Figma | Remote HTTP | OAuth | Design-to-code: layouts, tokens, component variants |
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

`~/.claude/settings.json` ships with pre-approved permissions for common dev tools (git, gh, npm, node, docker, etc.) and a deny list for dangerous operations (sudo, rm -rf /, etc.).

`~/.claude/CLAUDE.md` contains lightweight global preferences (Conventional Commits, feature branches, CLI-first workflow).

## What gets configured

| Tool | Config files |
|------|-------------|
| Claude Code | `~/.claude/CLAUDE.md`, `settings.json`, `agents/` + MCPs via `claude mcp add` |
| Cursor | `~/.cursor/mcp.json`, `~/.cursor/rules/global.mdc` |
| Codex | `~/.codex/config.toml` |

## Updating

```bash
chezmoi update    # Pull + apply on any machine
```

## File structure

```
.chezmoi.toml.tmpl                    # Setup prompt (API MCPs toggle)
.chezmoiignore                        # Platform-conditional exclusions
dot_claude/
  CLAUDE.md                           # → ~/.claude/CLAUDE.md
  settings.json                       # → ~/.claude/settings.json
  agents/
    planner.md                        # Planning agent
    code-reviewer.md                  # Code review agent
    tdd-guide.md                      # TDD coaching agent
dot_cursor/
  mcp.json.tmpl                       # → ~/.cursor/mcp.json
  rules/global.mdc                    # → ~/.cursor/rules/global.mdc
dot_codex/
  config.toml.tmpl                    # → ~/.codex/config.toml
run_onchange_after_install-claude-mcps.sh.tmpl   # Unix MCP registration
run_onchange_after_install-claude-mcps.ps1.tmpl  # Windows MCP registration
scripts/
  bootstrap.sh                        # macOS/Linux bootstrap
  bootstrap.ps1                       # Windows bootstrap
```

## Security

- **Pinned versions** — All stdio MCPs use exact version numbers to prevent supply-chain attacks via malicious updates.
- **No secrets in repo** — API keys are fetched from Bitwarden at `chezmoi apply` time.
- **OAuth MCPs** (Context7, Sentry, Figma) authenticate via browser — no tokens stored locally.
- **Periodic audit** — Run `npx @anthropic-ai/mcp-scan` to scan installed MCPs for tool poisoning.

## Dependencies

**Required:** git, chezmoi (auto-installed by bootstrap)

**For MCPs:** node, npx

**For API MCPs:** Bitwarden CLI (`bw`)
