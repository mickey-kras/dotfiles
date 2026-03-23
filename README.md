# dotfiles-claude

AI toolchain configuration synced across all machines with [chezmoi](https://chezmoi.io). One command sets up Claude Code, Cursor, and Codex with shared MCPs, hooks, rules, agents, and instructions. No API keys needed for core setup — OAuth MCPs authorize in the browser on first use.

## Quick start — new machine

**macOS / Linux / WSL:**
```bash
bash <(curl -sL https://raw.githubusercontent.com/mickey-kras/dotfiles-claude/main/scripts/bootstrap.sh)
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/mickey-kras/dotfiles-claude/main/scripts/bootstrap.ps1 | iex
```

The bootstrap script installs chezmoi, clones this repo, and prompts you for:
- **Email** and **machine name** (stored locally, never committed)
- **Hook profile** — `minimal` (no hooks), `standard` (recommended), or `strict` (blocks linter config edits)
- **API-key MCPs** — optional, requires [Bitwarden CLI](https://bitwarden.com/help/cli/)

**If chezmoi is already installed:**
```bash
chezmoi init --apply git@github.com:mickey-kras/dotfiles-claude.git
```

## What gets configured

| Tool | MCP config | AI instructions |
|------|-----------|-----------------|
| Claude Code | `~/.claude.json` (via `claude mcp add`) | `~/.claude/CLAUDE.md` + `settings.json` + `rules/` + `agents/` + `hooks/` |
| Cursor | `~/.cursor/mcp.json` | `~/.cursor/rules/global.mdc` |
| Codex | `~/.codex/config.toml` | `model`, `instructions`, and MCPs in `config.toml` |

## MCP servers

### Core (keyless — always installed)

| Server | Transport | Auth | What it does |
|--------|-----------|------|-------------|
| Sequential Thinking | stdio (npx) | None | Structured step-by-step problem solving |
| Playwright | stdio (npx) | None | Browser automation and testing |
| Context7 | Remote HTTP | OAuth | Up-to-date library docs and code context |
| GitHub | Remote HTTP | OAuth | Repos, issues, PRs, code search |
| Cloudflare Docs | Remote HTTP | None | Cloudflare documentation lookup |
| Vercel | Remote HTTP | OAuth | Vercel deployments and projects |
| Magic UI | stdio (npx) | None | UI component generation |
| Bitwarden | stdio (npx) | Local vault | Secure access to vault items |
| Memory | stdio (npx) | None | Persistent cross-session memory |
| Filesystem | stdio (npx) | None | Safe read-only file operations |

### Optional (API keys via Bitwarden)

Enabled by answering "yes" to the API-key MCPs prompt during setup. Keys are pulled from Bitwarden at `chezmoi apply` time — never stored in the repo.

| Server | Bitwarden item name | What it does |
|--------|-------------------|-------------|
| Exa | `exa-api-key` | AI-powered web search |
| Firecrawl | `firecrawl-api-key` | Web scraping and crawling |
| fal-ai | `fal-api-key` | AI image generation |

**Setup:** Create Bitwarden login items with the names above, store the API key as the password. Run `bw login` + `export BW_SESSION=$(bw unlock --raw)` before `chezmoi apply`.

## Hooks

Hooks are Node.js scripts that run at specific points in the Claude Code lifecycle. Controlled by the **hook profile** you choose during setup.

| Hook | Event | What it does | Profile |
|------|-------|-------------|---------|
| block-no-verify | PreToolUse | Blocks `--no-verify` on git commands | standard+ |
| governance-capture | PreToolUse | Blocks secrets and destructive commands in Bash | standard+ |
| config-protection | PreToolUse | Blocks edits to linter/formatter configs | strict |
| suggest-compact | PostToolUse | Suggests `/compact` after 50 tool calls | standard+ |
| post-edit-format | PostToolUse | Auto-formats JS/TS/JSON after edits (Biome/Prettier) | standard+ |
| quality-gate | PostToolUse | Runs lightweight linting on edited files | standard+ |
| cost-tracker | Stop | Logs token usage to `~/.claude/metrics/costs.jsonl` | standard+ |
| session-start | SessionStart | Loads previous session summary for context | standard+ |
| session-end | Stop | Saves session summary for next time | standard+ |
| check-console-log | Stop | Warns about console.log in modified JS/TS files | standard+ |

**Profiles:**
- `minimal` — No hooks. Clean slate.
- `standard` — Recommended. All hooks except config-protection.
- `strict` — All hooks including config-protection (blocks linter config edits).

## Rules

Deployed to `~/.claude/rules/`. Applied automatically based on file globs.

| Rule | What it enforces |
|------|-----------------|
| code-style | TDD, SOLID, DRY, meaningful names, error handling |
| security | No secrets in code, input validation, HTTPS, parameterized queries |
| testing | Red-green-refactor, AAA pattern, behavior over implementation |
| development-workflow | Research-first: search GitHub → read docs → then code |
| performance | Model routing (Haiku/Sonnet/Opus), context management |
| git-workflow | Conventional commits, branch naming, PR workflow |
| bitwarden-setup | How to configure Bitwarden CLI for API-key MCPs |

## Agents

Deployed to `~/.claude/agents/`. Invoke with the Agent tool or subagent spawning.

| Agent | Purpose |
|-------|---------|
| planner | Explores codebase, identifies risks, creates step-by-step implementation plans |
| code-reviewer | Reviews diffs for bugs, security issues, and quality (CRITICAL → LOW) |
| tdd-guide | Guides red-green-refactor cycle, enforces 80%+ coverage |

## How it works

chezmoi manages dotfiles as templates in a git repo. When you run `chezmoi apply`:

1. Writes `~/.cursor/mcp.json` and `~/.codex/config.toml` from templates (MCPs + instructions)
2. Copies `~/.claude/CLAUDE.md`, `settings.json`, `rules/`, `agents/`, and `hooks/` scripts
3. Copies `~/.cursor/rules/global.mdc`
4. Runs `claude mcp add` via a run-script to register MCPs in Claude Code's user config

Templates use chezmoi variables (`.chezmoi.os`, `.machine`, `.hook_profile`, `.enable_api_mcps`) for machine-specific behavior.

## Verifying the setup

```bash
claude mcp list                     # Should show 10 keyless MCPs
cat ~/.cursor/mcp.json | jq .       # Valid JSON with 10 servers
cat ~/.codex/config.toml            # Model, instructions, 10 MCP blocks
ls ~/.claude/rules/                 # 7 rule files
ls ~/.claude/agents/                # 3 agent files
ls ~/.claude/hooks/scripts/         # 10 hook scripts
cat ~/.claude/settings.json | jq .hooks   # Hooks config (unless minimal)
```

## Updating

After changing templates in the repo:
```bash
chezmoi apply       # Apply locally
```

On other machines:
```bash
chezmoi update      # Pull + apply in one step
```

## Adding a new MCP

1. Add it to `dot_cursor/mcp.json.tmpl` (JSON format)
2. Add it to `dot_codex/config.toml.tmpl` (TOML format)
3. Add the `claude mcp add` command to `run_onchange_after_install-claude-mcps.sh.tmpl` (and `.ps1.tmpl`)
4. Commit, push, `chezmoi update` on other machines

## Changing machine config

```bash
chezmoi edit-config    # Opens ~/.config/chezmoi/chezmoi.toml
chezmoi apply          # Re-render templates with new values
```

To change hook profile or toggle API MCPs, edit the `[data]` section.

## File structure

```
.chezmoi.toml.tmpl                    # Machine config prompts (email, machine, profile, API MCPs)
.chezmoiignore                        # Files chezmoi skips (platform-conditional)
dot_cursor/
  mcp.json.tmpl                       # → ~/.cursor/mcp.json
  rules/global.mdc                    # → ~/.cursor/rules/global.mdc
dot_codex/
  config.toml.tmpl                    # → ~/.codex/config.toml
dot_claude/
  CLAUDE.md                           # → ~/.claude/CLAUDE.md
  settings.json.tmpl                  # → ~/.claude/settings.json (hooks + permissions)
  rules/
    code-style.md                     # Engineering principles
    security.md                       # Security rules
    testing.md                        # Testing standards
    development-workflow.md           # Research-first workflow
    performance.md                    # Model routing guidance
    git-workflow.md                   # Git conventions
    bitwarden-setup.md                # API-key MCP setup guide
  agents/
    planner.md                        # Planning agent
    code-reviewer.md                  # Code review agent
    tdd-guide.md                      # TDD coaching agent
  hooks/scripts/
    block-no-verify.js                # Blocks --no-verify
    governance-capture.js             # Blocks secrets/destructive commands
    config-protection.js              # Protects linter configs (strict)
    suggest-compact.js                # Suggests /compact
    post-edit-format.js               # Auto-formats JS/TS/JSON
    quality-gate.js                   # Post-edit linting
    cost-tracker.js                   # Token usage tracking
    session-start.js                  # Cross-session memory (load)
    session-end.js                    # Cross-session memory (save)
    check-console-log.js              # Catches console.log
run_onchange_after_install-claude-mcps.sh.tmpl   # Unix: claude mcp add
run_onchange_after_install-claude-mcps.ps1.tmpl  # Windows: claude mcp add
scripts/
  bootstrap.sh                        # macOS/Linux bootstrap
  bootstrap.ps1                       # Windows bootstrap
```

## Platform support

| Platform | Status |
|----------|--------|
| macOS (ARM/Intel) | Full |
| Linux (Debian/Ubuntu/Fedora/Arch) | Full |
| WSL2 | Full |
| Windows 11 | Full (hooks require Node.js) |

## Dependencies

**Required:** git, chezmoi (auto-installed by bootstrap)

**For MCPs and hooks:** node, npx

**For API-key MCPs:** Bitwarden CLI (`bw`)

**Optional:** jq (debugging)
