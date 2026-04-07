# Dependency Inventory

Phase 0 inventory of the current global runtime-model dependencies that must move
behind a resolved pack state.

## Global Data Dependencies

### `.chezmoidata/runtime_profiles.yaml`

- `profiles`
  - [dot_claude/settings.json.tmpl](/Users/mikhailkrasilnikov/dotfiles/dot_claude/settings.json.tmpl)
  - [scripts/chezmoi/run_onchange_after_install-claude-mcps.sh.tmpl](/Users/mikhailkrasilnikov/dotfiles/scripts/chezmoi/run_onchange_after_install-claude-mcps.sh.tmpl)
- `mcp_sets`
  - [dot_codex/config.toml.tmpl](/Users/mikhailkrasilnikov/dotfiles/dot_codex/config.toml.tmpl)
  - [dot_cursor/mcp.json.tmpl](/Users/mikhailkrasilnikov/dotfiles/dot_cursor/mcp.json.tmpl)
  - [scripts/chezmoi/run_onchange_after_install-claude-mcps.sh.tmpl](/Users/mikhailkrasilnikov/dotfiles/scripts/chezmoi/run_onchange_after_install-claude-mcps.sh.tmpl)
- `permission_groups`
  - [dot_claude/settings.json.tmpl](/Users/mikhailkrasilnikov/dotfiles/dot_claude/settings.json.tmpl)
- `hard_bans`
  - [dot_claude/settings.json.tmpl](/Users/mikhailkrasilnikov/dotfiles/dot_claude/settings.json.tmpl)

### `.chezmoidata/capability_packs.yaml`

- `packs`
  - [scripts/chezmoi/run_onchange_after_install-managed-skills.sh.tmpl](/Users/mikhailkrasilnikov/dotfiles/scripts/chezmoi/run_onchange_after_install-managed-skills.sh.tmpl)

## Prompt-State Dependencies

These values are written into `~/.config/chezmoi/chezmoi.toml` today and then
consumed directly by templates and helper scripts:

- `runtime_profile`
  - [dot_claude/settings.json.tmpl](/Users/mikhailkrasilnikov/dotfiles/dot_claude/settings.json.tmpl)
  - [dot_codex/config.toml.tmpl](/Users/mikhailkrasilnikov/dotfiles/dot_codex/config.toml.tmpl)
  - [dot_cursor/mcp.json.tmpl](/Users/mikhailkrasilnikov/dotfiles/dot_cursor/mcp.json.tmpl)
  - [scripts/chezmoi/run_onchange_after_install-claude-mcps.sh.tmpl](/Users/mikhailkrasilnikov/dotfiles/scripts/chezmoi/run_onchange_after_install-claude-mcps.sh.tmpl)
  - [dot_local/bin/executable_dotfiles-update](/Users/mikhailkrasilnikov/dotfiles/dot_local/bin/executable_dotfiles-update)
- `capability_pack`
  - [.chezmoi.toml.tmpl](/Users/mikhailkrasilnikov/dotfiles/.chezmoi.toml.tmpl)
  - [scripts/chezmoi/run_onchange_after_install-managed-skills.sh.tmpl](/Users/mikhailkrasilnikov/dotfiles/scripts/chezmoi/run_onchange_after_install-managed-skills.sh.tmpl)
  - [dot_codex/config.toml.tmpl](/Users/mikhailkrasilnikov/dotfiles/dot_codex/config.toml.tmpl)
  - [dot_codex/AGENTS.md.tmpl](/Users/mikhailkrasilnikov/dotfiles/dot_codex/AGENTS.md.tmpl)
  - [dot_cursor/rules/global.mdc.tmpl](/Users/mikhailkrasilnikov/dotfiles/dot_cursor/rules/global.mdc.tmpl)
  - [dot_local/bin/executable_dotfiles-update](/Users/mikhailkrasilnikov/dotfiles/dot_local/bin/executable_dotfiles-update)
- `profile_base`
  - [dot_claude/settings.json.tmpl](/Users/mikhailkrasilnikov/dotfiles/dot_claude/settings.json.tmpl)
  - [dot_codex/config.toml.tmpl](/Users/mikhailkrasilnikov/dotfiles/dot_codex/config.toml.tmpl)
  - [dot_cursor/mcp.json.tmpl](/Users/mikhailkrasilnikov/dotfiles/dot_cursor/mcp.json.tmpl)
  - [scripts/chezmoi/run_onchange_after_install-claude-mcps.sh.tmpl](/Users/mikhailkrasilnikov/dotfiles/scripts/chezmoi/run_onchange_after_install-claude-mcps.sh.tmpl)
  - [dot_local/bin/executable_dotfiles-update](/Users/mikhailkrasilnikov/dotfiles/dot_local/bin/executable_dotfiles-update)
- `custom_enabled_mcps`, `custom_disabled_mcps`
  - [dot_codex/config.toml.tmpl](/Users/mikhailkrasilnikov/dotfiles/dot_codex/config.toml.tmpl)
  - [dot_cursor/mcp.json.tmpl](/Users/mikhailkrasilnikov/dotfiles/dot_cursor/mcp.json.tmpl)
  - [scripts/chezmoi/run_onchange_after_install-claude-mcps.sh.tmpl](/Users/mikhailkrasilnikov/dotfiles/scripts/chezmoi/run_onchange_after_install-claude-mcps.sh.tmpl)
  - [dot_local/bin/executable_dotfiles-update](/Users/mikhailkrasilnikov/dotfiles/dot_local/bin/executable_dotfiles-update)
- `custom_enabled_permission_groups`, `custom_disabled_permission_groups`
  - [dot_claude/settings.json.tmpl](/Users/mikhailkrasilnikov/dotfiles/dot_claude/settings.json.tmpl)
- `memory_provider`, `obsidian_vault_path`
  - [.chezmoi.toml.tmpl](/Users/mikhailkrasilnikov/dotfiles/.chezmoi.toml.tmpl)
  - [dot_codex/config.toml.tmpl](/Users/mikhailkrasilnikov/dotfiles/dot_codex/config.toml.tmpl)
  - [dot_cursor/mcp.json.tmpl](/Users/mikhailkrasilnikov/dotfiles/dot_cursor/mcp.json.tmpl)
  - [scripts/chezmoi/run_onchange_after_install-claude-mcps.sh.tmpl](/Users/mikhailkrasilnikov/dotfiles/scripts/chezmoi/run_onchange_after_install-claude-mcps.sh.tmpl)
  - [dot_local/bin/executable_dotfiles-update](/Users/mikhailkrasilnikov/dotfiles/dot_local/bin/executable_dotfiles-update)
- `azure_devops_org`
  - [.chezmoi.toml.tmpl](/Users/mikhailkrasilnikov/dotfiles/.chezmoi.toml.tmpl)
  - [dot_codex/config.toml.tmpl](/Users/mikhailkrasilnikov/dotfiles/dot_codex/config.toml.tmpl)
  - [dot_cursor/mcp.json.tmpl](/Users/mikhailkrasilnikov/dotfiles/dot_cursor/mcp.json.tmpl)
  - [scripts/chezmoi/run_onchange_after_install-claude-mcps.sh.tmpl](/Users/mikhailkrasilnikov/dotfiles/scripts/chezmoi/run_onchange_after_install-claude-mcps.sh.tmpl)
  - [dot_local/bin/executable_dotfiles-update](/Users/mikhailkrasilnikov/dotfiles/dot_local/bin/executable_dotfiles-update)

## Bootstrap Runtime Duplication

[scripts/bootstrap.sh](/Users/mikhailkrasilnikov/dotfiles/scripts/bootstrap.sh) keeps a
second copy of:

- runtime profile names
- MCP set membership
- permission group membership
- default memory-provider behavior

That duplication must be retired once pack-native selection state is the source
of truth.

## Transitional Direction

The migration target for every consumer above is:

1. installer selection state
2. resolved pack state
3. host-specific rendering

No host template or reconcile script should read `profiles`, `mcp_sets`,
`permission_groups`, `hard_bans`, or capability-pack metadata directly once the
Phase 2 migration is complete.
