# dotfiles
[![CI](https://github.com/mickey-kras/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/mickey-kras/dotfiles/actions/workflows/ci.yml)

Shared AI development dotfiles managed with `chezmoi`.

This repo sets up one software-development toolchain across Claude Code, Codex, Cursor, Gemini CLI, Droid, and Obsidian.

Supported platforms:
- macOS: primary target
- Linux: supported
- Windows: secondary; use Git Bash

## Quick start

Use Git Bash on Windows.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mickey-kras/dotfiles/main/scripts/bootstrap.sh)
```

If you already have `chezmoi`:

```bash
chezmoi init --apply git@github.com:mickey-kras/dotfiles.git
```

Public HTTPS also works:

```bash
chezmoi init --apply https://github.com/mickey-kras/dotfiles.git
```

The bootstrap installs `chezmoi`, opens the setup wizard when `.NET` is available, and falls back to plain prompts otherwise.

## What you get

- One managed development setup
- All managed MCP servers, skills, agents, rules, and permission groups enabled by default
- Obsidian as the default memory provider
- Optional installation of Claude Code, Codex, Cursor, Gemini CLI, and Droid
- The same managed MCP surface rendered for Claude, Codex, Cursor, Gemini, and Droid

`MCP` here means Model Context Protocol server.

## Setup wizard

Tabs:
- `MCPs`
- `Skills`
- `Agents`
- `Rules`
- `Settings`

Everything starts selected. `Settings` contains:
- display name, role summary, and stack summary
- memory provider and Obsidian vault path
- optional installs for Claude Code, Codex, Cursor, Gemini CLI, and Droid
- `bw-gate` toggle on macOS
- Stitch API key

## What is managed

- Claude Code: `~/.claude/CLAUDE.md`, `settings.json`, `agents/`, `rules/`, `skills/`, plus MCP registration reconciliation
- Cursor: `~/.cursor/mcp.json`, `~/.cursor/rules/global.mdc`
- Codex: `~/.codex/config.toml`, `~/.codex/AGENTS.md`, `~/.codex/skills/`
- Gemini CLI: `~/.gemini/settings.json`
- Droid / Factory: `~/.factory/mcp.json`, `~/.factory/settings.json`, `~/.factory/droids/`
- Obsidian: vault `.obsidian/` state from `obsidian/managed/config.json`

## Obsidian

- The wizard auto-detects an existing vault from current AI tool configs when possible
- On macOS it prefers the iCloud vault path when present
- Otherwise it defaults to `~/Obsidian/memory-vault`
- If Obsidian is missing, dotfiles attempts to install it during apply
- If managed plugins are missing or on the wrong version, dotfiles downloads the pinned releases and rewrites managed plugin settings

Managed community plugins currently include Tasks, Dataview, Templater, Calendar, Kanban, Homepage, Table Editor, Breadcrumbs, Obsidian Local REST API, Metadata Menu, QuickAdd, Smart Connections, and Strange New Worlds.

## After install

If you use Bitwarden-backed MCPs:

- Bitwarden-backed MCPs require `bw` plus a valid `~/.bw_session`; run `bw-login` after bootstrap when needed

Other notes:
- Some MCPs expect local tools such as `docker`, `firebase`, or `uvx`
- Missing host tools do not block config rendering; that MCP becomes usable once the tool exists
- If Obsidian is your memory provider, open the vault once after install so the managed plugin setup can be used normally

## Updating

```bash
dotfiles-update
```

or:

```bash
chezmoi apply
```

## Important files

- `scripts/bootstrap.sh`: entry point
- `packs/software-development/pack.yaml`: internal catalog and default selections
- `obsidian/managed/config.json`: managed Obsidian app and plugin state
