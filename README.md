# dotfiles

AI toolchain config synced across machines with [chezmoi](https://chezmoi.io). One command sets up Claude Code, Cursor, and Codex with shared MCPs, profile-aware permissions, capability packs, and Bitwarden-backed secret wrappers.

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

The installer now asks for:
1. **Runtime profile** - `restricted`, `balanced`, `open`, or `custom`
2. **Capability pack** - currently `software-development`
3. **Display name, role summary, stack summary**
4. **Azure DevOps org** - optional
5. **Custom MCPs and permission groups** if `custom` is selected

If `gum` is installed, setup uses a richer TUI. Otherwise it falls back to plain Bash prompts.

## What gets installed

### Runtime profiles

`restricted`
- remote work systems allowed
- no local or system mutation by default
- no `uv` or `uvx`
- no high-injection web MCPs

`balanced`
- `restricted` plus practical local execution and containers
- good default for work machines

`open`
- `balanced` plus cloud, web, and high-injection MCPs
- best fit for trusted personal machines

`custom`
- curated MCP catalog and permission groups
- you choose the exact subset

### Capability packs

Current pack:
- `software-development`

This pack provides the SDLC team model across tools:
- Claude Code subagents
- Codex operating model
- Cursor rules and workflow guidance

Future packs can reuse the same runtime profiles while swapping the working style and capability surface.

### MCPs

All versions are pinned for supply-chain safety. OAuth MCPs authenticate in the browser on first use.

| Server | Profiles | Transport | Auth | Risk | What it does |
|--------|----------|-----------|------|------|-------------|
| Playwright 0.0.68 | restricted, balanced, open | stdio (npx) | None | medium | Browser automation and E2E testing |
| Context7 | restricted, balanced, open | Remote HTTP | OAuth | low | Up-to-date library docs and code examples |
| Figma | restricted, balanced, open | Remote HTTP | OAuth | medium | Design-to-code: layouts, tokens, component variants |
| Filesystem 2026.1.14 | restricted, balanced, open | stdio (npx) | None | low | Local file browsing rooted at `~/Dev` |
| Git 2.10.5 | restricted, balanced, open | stdio (npx) | None | low | Repository history and diff operations |
| Memory 2026.1.26 | restricted, balanced, open | stdio (npx) | None | low | Local MCP memory store |
| Sequential Thinking 2025.12.18 | restricted, balanced, open | stdio (npx) | None | low | Structured reasoning MCP |
| GitHub 2025.4.8 | restricted, balanced, open | stdio (npx) | Bitwarden item `mcp-github` | medium | GitHub API access with PAT |
| Azure DevOps 2.5.0 | restricted, balanced, open | stdio (npx) | PAT/OAuth | medium | Work items, PRs, pipelines, repos |
| Shell 2.0.15 | balanced, open | stdio (npx) | None | high | Controlled shell MCP access |
| Docker MCP Gateway | balanced, open | stdio (docker) | Docker Desktop / Engine | high | Docker MCP toolkit bridge |
| Process 1.5.10 | balanced, open | stdio (npx) | None | medium | Local process inspection |
| Terraform 0.13.0 | balanced, open | stdio (npx) | None | low | Terraform inspection and IaC workflows |
| Kubernetes 3.4.0 | balanced, open | stdio (npx) | None | medium | Cluster and manifest inspection |
| HTTP Fetch 2025.4.7 | open | stdio (uvx) | None | high | HTTP fetch and page retrieval |
| AWS 1.3.26 | open | stdio (uvx) | Bitwarden item `mcp-aws` | high | AWS API access with key pair |
| Tailscale 0.3.2 | open | stdio (npx) | Bitwarden item `mcp-tailscale` | high | Tailscale admin API access |
| Exa 3.1.9 | open | stdio (npx) | API key | high | AI-powered web search |
| Firecrawl 3.11.0 | open | stdio (npx) | API key | high | Web scraping and crawling |
| fal-ai 2.1.4 | open | stdio (npx) | API key | medium | AI image generation |

**Bitwarden-backed MCPs** require [Bitwarden CLI](https://bitwarden.com/help/cli/) plus a valid `~/.bw_session` file. Run `bw-login` after installing dotfiles to refresh it.

Required Bitwarden items and structure:
- `mcp-github`: login password = GitHub PAT
- `mcp-aws`: custom fields `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
- `mcp-tailscale`: login password = Tailscale API key, custom field `TAILSCALE_TAILNET`
- `exa-api-key`: login password = Exa API key
- `firecrawl-api-key`: login password = Firecrawl API key
- `fal-api-key`: login password = fal.ai API key

Then:
```bash
bw-login && chezmoi apply
```

### Agents

| Agent | Purpose |
|-------|---------|
| delivery-orchestrator | Front door for free-form requests; decomposes work and routes to the right specialists |
| planner | Builds phased implementation plans with file targets, risks, and verification |
| product-manager | Clarifies problem, scope, tradeoffs, and success criteria |
| workflow-architect | Maps workflows, states, handoffs, and failure paths |
| backend-engineer | Owns backend implementation, contracts, schemas, and service logic |
| frontend-engineer | Owns frontend implementation, interaction flow, and accessibility |
| staff-engineer | Handles cross-cutting technical work that spans multiple specialties |
| quality-engineer | Owns cross-cutting verification strategy and higher-level test implementation |
| code-reviewer | Reviews changes for bugs, regressions, risk, and missing tests |
| debugger | Investigates failures and isolates root cause with evidence |
| git-workflow-master | Owns Git hygiene, rebases, recovery, and branch safety |
| devops-engineer | Handles CI/CD, infra automation, environments, and rollout safety |
| security-engineer | Reviews auth, trust boundaries, secrets, input handling, and abuse risk |
| technical-writer | Writes high-signal technical docs, runbooks, migration notes, and PR text |
| incident-commander | Coordinates production incident response, containment, and rollback direction |

### Permissions and settings

`~/.claude/settings.json` is now runtime-profile-aware:
- `restricted` keeps a read-heavy baseline and blocks `uv` and `uvx`
- `balanced` adds practical local execution and container workflows
- `open` adds broader package, cloud, secret, and web access

All profiles still keep:
- `model: "opus"`
- `ENABLE_CLAUDEAI_MCP_SERVERS=false`
- dangerous operation denies like `sudo` and `rm -rf /`

`~/.claude/CLAUDE.md` contains lightweight global preferences (Conventional Commits, feature branches, CLI-first workflow), is rendered with your configured display name, explicitly requires MCP-only workflows with no connectors, and explicitly ignores Sentry even if it appears locally.

`~/.codex/AGENTS.md` mirrors those same global preferences for Codex, so both tools behave consistently across machines. Cursor gets the same MCP-only and ignore rules through `~/.cursor/rules/global.mdc`.

Global Git hooks are also installed at `~/.config/git/hooks` and enabled through `core.hooksPath`, so the same charset and no-AI-attribution rules are enforced before commit and before push across all local repositories.

`~/.local/bin/bw-mcp` and `~/.local/bin/bw-login` are installed as shared helpers so Claude, Codex, and Cursor can all use the same Bitwarden-backed MCP definitions.

## What gets configured

| Tool | Config files |
|------|-------------|
| Claude Code CLI | `~/.claude/CLAUDE.md`, `settings.json`, `agents/` + MCPs reconciled via `claude mcp add/remove` |
| Claude Desktop | MCPs reconciled into `~/Library/Application Support/Claude/claude_desktop_config.json` |
| Cursor | `~/.cursor/mcp.json`, `~/.cursor/rules/global.mdc` |
| Codex | `~/.codex/config.toml`, `~/.codex/AGENTS.md` |

## Updating

```bash
dotfiles-update   # Pull, apply, check versions, verify profile-aligned MCPs, security scan
```

Installed at `~/.local/bin/dotfiles-update` by chezmoi. Make sure `~/.local/bin` is in your PATH.

On Windows, a `.cmd` wrapper is installed alongside so `dotfiles-update` works from PowerShell and cmd. Requires Git Bash (`bash` in PATH) - included with [Git for Windows](https://gitforwindows.org).

For a quick pull-only update: `chezmoi update`

## File structure

```
.chezmoi.toml.tmpl                    # Setup prompts and local data model
.chezmoidata/
  runtime_profiles.yaml               # Runtime profiles, MCP catalog, permission groups, hard bans
  capability_packs.yaml               # Capability pack metadata
.chezmoiignore                        # Platform-conditional exclusions
packs/
  software-development/
    pack.json                         # Capability pack metadata
dot_claude/
  CLAUDE.md.tmpl                      # -> ~/.claude/CLAUDE.md
  settings.json.tmpl                  # -> ~/.claude/settings.json
  agents/
    delivery-orchestrator.md          # Request normalization and routing
    planner.md                        # Planning agent
    product-manager.md                # Product and requirements agent
    workflow-architect.md             # Workflow and process agent
    backend-engineer.md               # Backend implementation agent
    frontend-engineer.md              # Frontend implementation agent
    staff-engineer.md                 # Cross-cutting engineering agent
    quality-engineer.md               # Verification and higher-level testing agent
    code-reviewer.md                  # Code review agent
    debugger.md                       # Debugging agent
    git-workflow-master.md            # Git workflow agent
    devops-engineer.md                # CI/CD and infrastructure agent
    security-engineer.md              # Security review agent
    technical-writer.md               # Technical documentation agent
    incident-commander.md             # Incident response agent
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
    executable_bw-mcp                 # -> ~/.local/bin/bw-mcp
    executable_bw-login               # -> ~/.local/bin/bw-login
    executable_bw-login.cmd           # -> ~/.local/bin/bw-login.cmd (Windows only)
    executable_dotfiles-update        # -> ~/.local/bin/dotfiles-update
    executable_dotfiles-update.cmd    # -> ~/.local/bin/dotfiles-update.cmd (Windows only)
scripts/
  bootstrap.sh                        # Main setup path for macOS/Linux/WSL/Git Bash
  bootstrap.ps1                       # Legacy compatibility path
  chezmoi/
    run_onchange_after_configure-global-git-hooks.sh.tmpl   # Unix global Git hook setup
    run_onchange_after_configure-global-git-hooks.ps1.tmpl  # Windows global Git hook setup
    run_onchange_after_install-claude-mcps.sh.tmpl          # Authoritative Claude MCP reconciliation
    run_onchange_after_install-claude-mcps.ps1.tmpl         # Windows MCP registration
```

## Security

- **Pinned versions** - All stdio MCPs use exact version numbers to prevent supply-chain attacks via malicious updates.
- **No secrets in repo** - API keys are fetched from Bitwarden at `chezmoi apply` time.
- **OAuth MCPs** (Context7, Figma) authenticate via browser - no tokens stored locally.
- **Prompt-injection awareness** - `http`, `exa`, and `firecrawl` are intentionally `open`-only because they ingest broad remote content.
- **Authoritative reconciliation** - setup removes unmanaged or out-of-profile Claude MCPs by default to return the machine to the selected profile.
- **Periodic audit** - Run `npx @anthropic-ai/mcp-scan` to scan installed MCPs for tool poisoning.

## Dependencies

**Required:** git, chezmoi (auto-installed by bootstrap), bash (Git Bash on Windows)

**For MCPs:** node, npx

**For open-profile MCPs only:** `uv` and `uvx`

**For richer setup UI:** `gum`

**For Bitwarden-backed MCPs:** Bitwarden CLI (`bw`)
