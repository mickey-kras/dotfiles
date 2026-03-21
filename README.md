# dotfiles-claude

Claude Code configuration synced across all machines. One repo, every device, always in sync.

## What's inside

```
claude/
  CLAUDE.md              ← Global instructions loaded in every session
  settings.json          ← Permissions, deny list, env vars, hooks
  .mcp.json              ← Local MCP servers (context7, playwright, etc.)
  connectors.json        ← Manifest of ALL expected MCPs + cloud connectors
  rules/                 ← Code style, security, testing rules
  skills/                ← Reusable skills (shared across machines)
  agents/                ← Custom subagent definitions
  hooks/scripts/
    security-audit.sh    ← Validates config, blocks on critical issues
    startup-sync.sh      ← Pulls latest, pushes local drift
    check-connectors.sh  ← Detects missing MCPs/connectors, prompts to fix
    auto-commit-config.sh← Auto-commits & pushes any config change
scripts/
  install.sh             ← Cross-platform installer (macOS/Linux/WSL/Windows)
  setup-secrets.sh       ← Interactive: API keys + cloud connector auth
  export.sh              ← Export live config back into the repo
  diff.sh                ← Show drift between live config and repo
```

## Quick start — new machine

```bash
# 1. Clone
git clone git@github.com:mickey-kras/dotfiles-claude.git ~/dotfiles-claude

# 2. Install (symlinks config into ~/.claude/, checks dependencies)
~/dotfiles-claude/scripts/install.sh

# 3. Interactive setup — API keys + cloud connectors
~/dotfiles-claude/scripts/setup-secrets.sh
```

Step 3 walks you through everything interactively: enters API keys, offers to open Claude app settings for each cloud connector (Slack, Gmail, Calendar, Atlassian, Drive), then verifies what's connected.

## All managed MCPs & connectors

| Server | Type | Synced via | Auth |
|--------|------|-----------|------|
| context7 | Local (HTTP) | .mcp.json | API key → `setup-secrets.sh` |
| playwright | Local (stdio) | .mcp.json | None |
| Slack | Cloud connector | Claude account | OAuth in app |
| Gmail | Cloud connector | Claude account | OAuth in app |
| Google Calendar | Cloud connector | Claude account | OAuth in app |
| Atlassian | Cloud connector | Claude account | OAuth in app |
| Google Drive | Cloud connector | Claude account | OAuth in app |
| claude-mem | Built-in | Always available | None |

The `connectors.json` manifest tracks all of these. On every startup, `check-connectors.sh` compares what's expected vs what's active and tells you what's missing.

## How auto-sync works

Four hooks fire automatically:

**On startup** (`SessionStart`):
1. `security-audit.sh` — validates JSON, checks for hardcoded secrets, prompt injection, missing deny-list protections. Blocks on critical issues.
2. `startup-sync.sh` — pulls latest from GitHub, re-links if symlinks broke, pushes any local drift.
3. `check-connectors.sh` — reads `connectors.json`, checks which MCPs/connectors are missing, prints actionable steps.

**After every tool use** (`PostToolUse` on Write/Edit/Bash):
4. `auto-commit-config.sh` — if anything in `claude/` changed, commits and pushes silently.

Net effect: add an MCP on one machine → auto-pushed → auto-pulled on all others at next startup.

## Platform support

| Platform | Method | Notes |
|----------|--------|-------|
| macOS | Symlinks | Native, full support |
| Linux (Debian/Ubuntu/Fedora/Arch) | Symlinks | Same as macOS |
| WSL2 | Symlinks | Runs in Linux layer |
| Windows (Git Bash/MSYS) | File copy | Fallback; use `export.sh` to sync back |

Dependencies: `git`, `jq`, `node`, `npx`. The installer checks and tells you how to install per-platform.

## Adding a new local MCP

1. Add it to `claude/.mcp.json` on any machine
2. Auto-commit hook pushes it
3. Other machines pull on next startup
4. If it needs a key: add the key name to `claude/connectors.json` under `local`, then run `scripts/setup-secrets.sh` on each machine

## Adding a new cloud connector

1. Add it to `claude/connectors.json` under `cloud` with description and setup instructions
2. Commit and push
3. On each machine, `check-connectors.sh` will flag it as missing and tell you where to enable it
4. Or run `scripts/setup-secrets.sh` which walks through all connectors interactively

## Files that never get committed

| File | Contains |
|------|----------|
| `~/.claude/settings.local.json` | API keys, machine-local env vars |
| `~/.claude/.credentials.json` | Claude auth tokens |
| `~/.claude/.connectors-enabled` | Cloud connectors enabled on this machine |
| `~/.claude/projects/` | Auto-generated session memory |

## Useful commands

```bash
~/dotfiles-claude/scripts/diff.sh            # What's different locally vs repo
~/dotfiles-claude/scripts/export.sh          # Export live changes to repo
~/dotfiles-claude/scripts/setup-secrets.sh   # Re-run API key + connector setup
~/dotfiles-claude/scripts/install.sh         # Re-run installer

# Manual sync
cd ~/dotfiles-claude && git pull

# Manual security check
~/dotfiles-claude/claude/hooks/scripts/security-audit.sh

# Check connector status
~/dotfiles-claude/claude/hooks/scripts/check-connectors.sh
```

## Troubleshooting

**Startup says "merge conflict"** — `cd ~/dotfiles-claude && git status` and resolve manually.

**MCP not connecting** — Run `scripts/setup-secrets.sh` to check API keys. Or `/mcp` in Claude Code to see status.

**Hooks not firing** — `jq '.hooks' ~/.claude/settings.json` should show SessionStart + PostToolUse. Re-run `install.sh` if empty.

**Cloud connector missing after setup** — Enable it in Claude app > Settings > Integrations. These are per-account OAuth, not config-file based.

**Windows: changes not syncing** — Installer copies files instead of symlinking. After changes, run `scripts/export.sh` then commit.
