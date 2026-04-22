# dotfiles
<img width="1536" height="559" alt="image" src="https://github.com/user-attachments/assets/22084ba4-1d64-4dbb-86fc-b63925134956" />
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

The installer launches a Terminal.Gui TUI wizard (.NET 10) with tabs for:
1. **Pack/Profile** - pick a capability pack and a preset profile
2. **MCPs** - toggle individual MCPs; MCP-dependent settings (Azure DevOps org) appear below
3. **Skills / Agents / Rules / Permissions** - fine-tune what gets installed
4. **Settings** - user profile (name, role, stack), memory provider, workspace paths

All fields pre-fill from existing chezmoi data when available. If .NET is unavailable, setup falls back to plain Bash prompts.

## What gets installed

### Pack-first architecture

The source of truth is now the selected pack, not a global profile table. Each pack owns:
- preset profiles
- curated MCP catalog
- managed skills
- Claude agents and rules
- permission groups
- pack-specific settings

The shared resolver in `templates/resolved-state.json` normalizes the current selection, snaps exact customizations back to a preset when possible, and renders Claude, Cursor, and Codex from one resolved state.

### Pack profiles

`software-development`
- `restricted`: read-heavy repo work and low-trust machines
- `balanced`: daily-driver development profile
- `open`: personal-machine profile for broader cloud, web, and secret-backed tooling

`content-creation`
- `focused`: low-risk writing and synthesis
- `studio`: default for structured research, design collaboration, and iteration
- `campaign`: broader search, crawl, and image-generation surface for trusted personal machines

`research-and-strategy`
- `desk`: low-risk reading and local synthesis
- `analyst`: default for broader investigation with browser and process tools
- `investigation`: wider crawling and search for trusted personal machines

### Capability packs

Current packs:
- `software-development`
- `content-creation`
- `research-and-strategy`

`software-development` provides the SDLC operating model across tools:
- Claude Code specialists
- Codex operating model
- Cursor rules and workflow guidance
- Managed first-party workflow skills for Claude and Codex

`content-creation` provides a content and editorial operating model:
- research and editorial agents
- content-specific review rules
- campaign and editorial playbooks
- curated skills for planning, memory, and verification

`research-and-strategy` provides an evidence-focused research and reporting model:
- trend research, competitive analysis, and evidence review agents
- citation discipline and uncertainty reporting rules
- research intake, evidence matrix, and executive summary playbooks
- curated skills for context budget, memory, planning, and verification

### MCPs

All versions are pinned for supply-chain safety. OAuth MCPs authenticate in the browser on first use.

| Server | Profiles | Transport | Auth | Risk | What it does |
|--------|----------|-----------|------|------|-------------|
| Playwright 0.0.68 | restricted, balanced, open | stdio (npx) | None | medium | Browser automation and E2E testing |
| Context7 | restricted, balanced, open | Remote HTTP | OAuth | low | Up-to-date library docs and code examples |
| Figma | restricted, balanced, open | Remote HTTP | OAuth | medium | Design-to-code: layouts, tokens, component variants |
| Atlassian Rovo MCP | balanced, open | Remote HTTP | OAuth / admin-enabled API token | medium | Official Atlassian cloud context for Jira, Confluence, and related tools |
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
| Telegram | campaign, investigation | stdio (npx) | Bitwarden item `mcp-telegram` | high | Telegram bot for content distribution and stakeholder updates |

**Bitwarden-backed MCPs** require [Bitwarden CLI](https://bitwarden.com/help/cli/) plus a valid `~/.bw_session` file. Run `bw-login` after installing dotfiles to refresh the shared session cache used by Claude, Codex, and Cursor.

Required Bitwarden items and structure:
- `mcp-github`: login password = GitHub PAT
- `mcp-aws`: custom fields `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
- `mcp-tailscale`: login password = Tailscale API key, custom field `TAILSCALE_TAILNET`
- `exa-api-key`: login password = Exa API key
- `firecrawl-api-key`: login password = Firecrawl API key
- `fal-api-key`: login password = fal.ai API key
- `mcp-telegram`: login password = Telegram bot token from BotFather

Keep these item names unique. If Bitwarden contains multiple items with the
same name, the wrapper cannot safely choose one without an explicit item id.

Then:
```bash
bw-login
export BW_SESSION="$(cat ~/.bw_session)"
chezmoi apply
```

### Agents

Claude agents are now pack-owned assets. The installer reconciles the selected pack into `~/.claude/agents` by symlinking the enabled agent set and removing only previously managed symlinks.

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

### Skills

Managed first-party skills are installed pack-by-pack into:
- `~/.claude/skills`
- `~/.codex/skills`

`software-development` managed skills:
- `context7-mcp`
- `context-budget`
- `dispatching-parallel-agents`
- `executing-plans`
- `obsidian-memory`
- `receiving-code-review`
- `requesting-code-review`
- `systematic-debugging`
- `test-driven-development`
- `using-git-worktrees`
- `verification-before-completion`
- `writing-plans`

`content-creation` managed skills:
- `ai-discoverability`
- `context-budget`
- `obsidian-memory`
- `verification-before-completion`
- `writing-plans`

`research-and-strategy` managed skills:
- `context-budget`
- `obsidian-memory`
- `source-freshness-checker`
- `verification-before-completion`
- `writing-plans`

These are installed from first-party pack directories in `packs/*/skills`, not from live plugin caches.

### Memory

The default memory provider remains the local `memory` MCP.

Optional explicit memory path:
- Obsidian via MCPVault (`@bitbonsai/mcpvault`)
- configured through the installer with a vault path
- stays local-first and replaces the generic `memory` server wiring when selected

### Intended `~/.claude` layout

The goal is to keep `~/.claude` small and honest: only live configuration and capability surfaces should remain there. Runtime residue like transcripts, caches, telemetry, paste history, shell snapshots, and temporary session state should be disposable.

Keep:
- `CLAUDE.md`
- `agents/`
- `hooks/`
- `plugins/`
- `rules/`
- `skills/`
- `settings.json`
- `settings.local.json`

Treat everything else as runtime state:
- safe to recreate
- safe to clear during cleanup
- not something to manage in dotfiles

### Permissions and settings

`~/.claude/settings.json` is now resolved-state-aware:
- the selected pack decides which profiles, MCPs, rules, agents, permissions, and settings exist
- exact customizations resolve back to a named preset when possible
- permission allowlists are generated from pack-owned permission groups
- deny rules keep hard bans centralized and preserve the MCP-only governance surface

All profiles still keep:
- `model: "opus"`
- `ENABLE_CLAUDEAI_MCP_SERVERS=false`
- dangerous operation denies like `sudo` and `rm -rf /`

`~/.claude/settings.local.json` is also managed and intentionally reset to a minimal empty override by default. That keeps profile compliance real by removing stale ad hoc local approvals unless you deliberately extend the model to support a small generated local exception set.

`~/.claude/CLAUDE.md` contains lightweight global preferences (Conventional Commits, feature branches, CLI-first workflow), is rendered with your configured display name, explicitly requires MCP-only workflows with no connectors, and explicitly ignores Sentry even if it appears locally.

`~/.codex/AGENTS.md` mirrors those same global preferences for Codex, so both tools behave consistently across machines. Cursor gets the same MCP-only and ignore rules through `~/.cursor/rules/global.mdc`.

Global Git hooks are also installed at `~/.config/git/hooks` and enabled through `core.hooksPath`, so the same charset and no-AI-attribution rules are enforced before commit and before push across all local repositories.

`~/.local/bin/bw-mcp` and `~/.local/bin/bw-login` are installed as shared helpers so Claude, Codex, and Cursor can all use the same Bitwarden-backed MCP definitions. `bw-login` writes the unlocked session token to `~/.bw_session`; export it into the current shell only when a shell-driven command needs it immediately.

## What gets configured

| Tool | Config files |
|------|-------------|
| Claude Code CLI | `~/.claude/CLAUDE.md`, `settings.json`, `agents/`, `rules/`, `skills/` + MCPs reconciled via `claude mcp add/remove` |
| Claude Desktop | MCPs reconciled into `~/Library/Application Support/Claude/claude_desktop_config.json` |
| Cursor | `~/.cursor/mcp.json`, `~/.cursor/rules/global.mdc` |
| Codex | `~/.codex/config.toml`, `~/.codex/AGENTS.md`, `~/.codex/skills/` |

## Updating

```bash
dotfiles-update   # Pull, apply, check versions, verify profile-aligned MCPs, security scan
```

Installed at `~/.local/bin/dotfiles-update` by chezmoi. Make sure `~/.local/bin` is in your PATH.

On Windows, Git Bash is the supported path. Small `.cmd` wrappers are installed alongside selected helpers for launcher compatibility, but setup and ongoing management are Bash-first. Git Bash (`bash` in PATH) is required and comes with [Git for Windows](https://gitforwindows.org).

For a quick pull-only update: `chezmoi update`

## Cleanup

To wipe local Claude Code, Claude Desktop, Codex, and Cursor state from a
machine, use:

```bash
./scripts/reset-ai-tooling.sh --dry-run
./scripts/reset-ai-tooling.sh --yes
```

The script is Bash-first and supports macOS plus Windows via Git Bash. It
targets app bundles, user config, caches, logs, and user-level CLI shims.

## File structure

```
.chezmoi.toml.tmpl                    # Direct init prompts and fallback data model
.chezmoiignore                        # Platform-conditional exclusions
packs/
  software-development/
    pack.yaml                         # Pack-owned schema: profiles, catalogs, settings, UI sections
    claude/
      agents/                         # Pack-owned Claude agents
      rules/                          # Pack-owned Claude rules
    docs/
      quickstart.md                   # Pack quickstart and profile guidance
      playbooks/
        execute.md                    # Non-trivial delivery sequence
        review.md                     # Code review checklist
        orchestration.md              # Multi-agent routing and context discipline
        health-check.md               # Installation verification
  content-creation/
    pack.yaml                         # Pack-owned schema for editorial and campaign work
    claude/
      agents/                         # Editorial and campaign agents
      rules/                          # Editorial governance and workflow rules
    docs/                             # Pack quickstart and playbooks
  research-and-strategy/
    pack.yaml                         # Pack-owned schema for research and evidence work
    claude/
      agents/                         # Research, analysis, and reporting agents
      rules/                          # Evidence discipline and report structure rules
    docs/                             # Pack quickstart and playbooks
dot_claude/
  CLAUDE.md.tmpl                      # -> ~/.claude/CLAUDE.md
  settings.json.tmpl                  # -> ~/.claude/settings.json
  settings.local.json.tmpl            # -> ~/.claude/settings.local.json
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
    executable_bw-mcp.cmd             # -> ~/.local/bin/bw-mcp.cmd (Windows compatibility)
    executable_bw-login               # -> ~/.local/bin/bw-login
    executable_bw-login.cmd           # -> ~/.local/bin/bw-login.cmd
    executable_dotfiles-update        # -> ~/.local/bin/dotfiles-update
    executable_dotfiles-update.cmd    # -> ~/.local/bin/dotfiles-update.cmd
scripts/
  bootstrap.sh                        # Main setup path for macOS/Linux/WSL/Git Bash
  bootstrap-wizard.sh                 # Wizard launcher (TUI first, plain-text fallback)
  pack_state.py                       # Pack metadata and resolved-state helper
  wizard/
    MainWindow.cs                     # Terminal.Gui TUI wizard
    PackState.cs                      # Pack data models and state helpers
    Program.cs                        # Wizard entry point
    DotfilesWizard.csproj             # .NET 10 project file
  chezmoi/
    run_onchange_after_configure-global-git-hooks.sh.tmpl   # Unix global Git hook setup
    run_onchange_after_install-claude-mcps.sh.tmpl          # Authoritative Claude MCP reconciliation
    run_onchange_after_install-claude-pack-assets.sh.tmpl   # Symlink selected pack agents and rules
    run_onchange_after_install-managed-skills.sh.tmpl       # Reconcile pack-selected skills
  lib/
    pack-resolver.mjs                 # JS resolver used by tests and helpers
templates/
  resolved-state.json                 # Shared pack-first resolution template
docs/
  architecture/
    template-dependency-inventory.md  # Template and resolver dependency map
  packs/
    research-and-strategy.md          # Research-and-strategy pack design and implementation notes
  security/
    README.md                         # Review method and approval criteria
    CONTRIBUTING.md                   # MCP and plugin evaluation process
    mcp-decisions/                    # Per-pack MCP decisions
    plugin-decisions/                 # Policy decisions such as MCP-only
tests/
  pack-resolver.test.mjs              # Resolver behavior coverage
  rendered-output.test.mjs            # Rendered template coverage
```

## Security

- **Pinned versions** - All stdio MCPs use exact version numbers to prevent supply-chain attacks via malicious updates.
- **No secrets in repo** - API keys are fetched from Bitwarden at `chezmoi apply` time.
- **OAuth MCPs** (Context7, Figma) authenticate via browser - no tokens stored locally.
- **Prompt-injection awareness** - higher-risk remote-content MCPs are isolated to the appropriate pack profiles and documented in `docs/security/mcp-decisions/`.
- **Authoritative reconciliation** - setup removes unmanaged or out-of-profile Claude MCPs by default to return the machine to the selected profile.
- **Registry is discovery, not approval** - registry entries are not trusted by default; every MCP or plugin candidate requires documented review before inclusion.
- **Hooks and plugins stay conservative** - the policy surface remains MCP-only, Sentry stays excluded, and plugin settings are intentionally not generated.
- **Periodic audit** - Run `npx @anthropic-ai/mcp-scan` to scan installed MCPs for tool poisoning.

## Dependencies

**Required:** git, chezmoi (auto-installed by bootstrap), bash (Git Bash on Windows)

**For TUI wizard:** .NET 10 SDK (auto-installed by bootstrap)

**For MCPs:** node, npx

**For open-profile MCPs only:** `uv` and `uvx`

**For Bitwarden-backed MCPs:** Bitwarden CLI (`bw`)
