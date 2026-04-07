# Template Dependency Inventory

Current migration inventory for the pack-first transformation.

Still legacy-driven before this branch:
- `.chezmoi.toml.tmpl` writes runtime-profile and custom overlay fields only.
- `scripts/bootstrap.sh` builds effective MCPs and permissions from hard-coded global arrays.
- `dot_local/bin/executable_dotfiles-update` still derives expected MCPs from legacy runtime-profile tables.

Now moved onto shared resolved-state rendering:
- [`templates/resolved-state.json`](/Users/mikhailkrasilnikov/dotfiles/templates/resolved-state.json)
- [`dot_claude/settings.json.tmpl`](/Users/mikhailkrasilnikov/dotfiles/dot_claude/settings.json.tmpl)
- [`dot_codex/config.toml.tmpl`](/Users/mikhailkrasilnikov/dotfiles/dot_codex/config.toml.tmpl)
- [`dot_cursor/mcp.json.tmpl`](/Users/mikhailkrasilnikov/dotfiles/dot_cursor/mcp.json.tmpl)
- [`scripts/chezmoi/run_onchange_after_install-claude-mcps.sh.tmpl`](/Users/mikhailkrasilnikov/dotfiles/scripts/chezmoi/run_onchange_after_install-claude-mcps.sh.tmpl)
- [`scripts/chezmoi/run_onchange_after_install-managed-skills.sh.tmpl`](/Users/mikhailkrasilnikov/dotfiles/scripts/chezmoi/run_onchange_after_install-managed-skills.sh.tmpl)

Pack-owned asset migration in progress:
- Claude agents moved to [`packs/software-development/claude/agents`](/Users/mikhailkrasilnikov/dotfiles/packs/software-development/claude/agents)
- Claude rules moved to [`packs/software-development/claude/rules`](/Users/mikhailkrasilnikov/dotfiles/packs/software-development/claude/rules)
- New reconcile path added in [`scripts/chezmoi/run_onchange_after_install-claude-pack-assets.sh.tmpl`](/Users/mikhailkrasilnikov/dotfiles/scripts/chezmoi/run_onchange_after_install-claude-pack-assets.sh.tmpl)

Remaining Phase 0 and follow-on migration targets:
- `dot_local/bin/executable_dotfiles-update`
- `scripts/bootstrap.sh`
- README structure and rollout docs
