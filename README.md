# dotfiles
[![CI](https://github.com/mickey-kras/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/mickey-kras/dotfiles/actions/workflows/ci.yml)

AI development dotfiles for macOS and Linux, with Git Bash on Windows as secondary support. The repo manages one shared software-development toolchain across Claude Code, Codex, Cursor, Gemini CLI, Droid, and Obsidian with `chezmoi`.

## What this repo does

- Uses one managed software-development toolchain
- Starts with all managed MCPs, skills, agents, rules, and permission groups enabled
- Removes the old pack/profile/restriction chooser from the installer flow
- Defaults memory to Obsidian
- Installs Obsidian when it is selected and missing, then reconciles the vault, community plugins, and managed plugin settings
- Lets you optionally install Claude Code, Codex, Cursor, Gemini CLI, and Droid from the installer; these are off by default
- Renders the same managed MCP surface for Claude, Codex, Cursor, Gemini, and Droid/Factory

## Platforms

- macOS: primary target
- Linux: supported
- Windows: secondary; use Git Bash

## Quick start

Use Git Bash on Windows.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mickey-kras/dotfiles/main/scripts/bootstrap.sh)
```

Already have `chezmoi`?

```bash
chezmoi init --apply git@github.com:mickey-kras/dotfiles.git
```

Public HTTPS also works:

```bash
chezmoi init --apply https://github.com/mickey-kras/dotfiles.git
```

The bootstrap installs `chezmoi`, tries to launch the Terminal.Gui wizard when `.NET` is available, and falls back to plain prompts otherwise.

## Installer flow

Tabs:

1. `MCPs`
2. `Skills`
3. `Agents`
4. `Rules`
5. `Settings`

Everything starts selected. `Settings` contains:

- display name, role summary, and stack summary
- memory provider and Obsidian vault path
- optional installs for Claude Code, Codex, Cursor, Gemini CLI, and Droid
- `bw-gate` toggle on macOS
- Stitch API key

## Managed surfaces

- Claude Code: `~/.claude/CLAUDE.md`, `settings.json`, `agents/`, `rules/`, `skills/`, plus MCP registration reconciliation
- Cursor: `~/.cursor/mcp.json`, `~/.cursor/rules/global.mdc`
- Codex: `~/.codex/config.toml`, `~/.codex/AGENTS.md`, `~/.codex/skills/`
- Gemini CLI: `~/.gemini/settings.json`
- Droid / Factory: `~/.factory/mcp.json`, `~/.factory/settings.json`, `~/.factory/droids/`
- Obsidian: vault `.obsidian/` state from `obsidian/managed/config.json`

## Obsidian

Obsidian is the default memory provider for this repo.

- The wizard auto-detects an existing vault from current AI tool configs when possible
- On macOS it prefers the iCloud vault path when present
- Otherwise it defaults to `~/Obsidian/memory-vault`
- If Obsidian is missing, dotfiles attempts to install it during apply
- If managed plugins are missing or on the wrong version, dotfiles downloads the pinned releases and rewrites managed plugin settings

Managed community plugins currently include Tasks, Dataview, Templater, Calendar, Kanban, Homepage, Table Editor, Breadcrumbs, Obsidian Local REST API, Metadata Menu, QuickAdd, Smart Connections, and Strange New Worlds.

## Credentials and host tools

Some selected MCPs need local host tools or credentials before they are usable.

- Bitwarden-backed MCPs require `bw` plus a valid `~/.bw_session`; run `bw-login` after bootstrap when needed
- Some MCPs also expect local tools such as `docker`, `firebase`, or `uvx`
- The repo still renders config when a host tool is missing; that MCP becomes usable once the tool and credentials exist

## Updating

```bash
dotfiles-update
```

or:

```bash
chezmoi apply
```

## Repo pointers

- `packs/software-development/pack.yaml` for the internal catalog and default selections
- `obsidian/managed/config.json`
- `scripts/bootstrap.sh`
