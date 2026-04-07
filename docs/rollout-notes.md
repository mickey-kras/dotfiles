# Pack-First Architecture Rollout Notes

Branch: `feat/pack-first-dotfiles`

## What changed

### Architecture

The dotfiles moved from a global profile model to a **pack-first capability architecture**. Each pack (`software-development`, `content-creation`) owns its profiles, MCP catalog, agents, rules, skills, permissions, and settings. A shared resolver (`templates/resolved-state.json`) normalizes selections and feeds all host templates (Claude Code, Claude Desktop, Cursor, Codex) from one resolved state.

### New pack: content-creation

Added `content-creation` with three profiles:
- `focused` -- low-risk writing and synthesis
- `studio` (default) -- structured research and editorial iteration
- `campaign` -- broader search, crawl, and image generation for trusted machines

### Bootstrap wizard

The installer (`scripts/bootstrap-wizard.sh`) now shows a styled configuration summary with MCP counts, skill counts, agent counts, and warnings for secret-backed or high-injection-risk MCPs. Dead legacy code (~400 lines of hardcoded arrays and unused helpers) was removed from `scripts/bootstrap.sh`.

### Documentation

- `packs/software-development/docs/quickstart.md` -- rewritten with profile table, model guidance, key skills, and playbook links
- `packs/software-development/docs/playbooks/orchestration.md` -- agent routing, parallel work rules, context discipline, handoff format
- `packs/software-development/docs/playbooks/health-check.md` -- quick verification commands and common issue table
- `docs/packs/research-and-strategy.md` -- design-complete spec with profiles, agents, rules, settings, guardrails, and implementation criteria
- `docs/security/CONTRIBUTING.md` -- 10-dimension MCP evaluation rubric and step-by-step contribution process

### Security

Every MCP candidate has a recorded decision in `docs/security/mcp-decisions/`. The new CONTRIBUTING.md formalizes the evaluation process for future candidates. No new MCPs were added without review. Sentry remains excluded.

### Tests

- 19 JavaScript tests covering pack loading, profile matching, validation, cross-pack consistency, and fixture rendering
- 6 Python snapshot tests covering rendered output for both packs across all profiles
- All 25 tests pass

## Upgrade path

### From an existing dotfiles installation on this branch

```bash
cd ~/dotfiles && git pull
npm install
chezmoi apply
```

### From a fresh machine

```bash
bash <(curl -sL https://raw.githubusercontent.com/mickey-kras/dotfiles/main/scripts/bootstrap.sh)
```

The wizard will prompt for pack, profile, and settings.

### Switching packs

Re-run the bootstrap wizard:
```bash
cd ~/dotfiles && bash scripts/bootstrap.sh
```

Select a different pack. The reconcile scripts will remove the old pack's agents, rules, and skills and install the new pack's assets. MCPs are reconciled to match the new selection.

### Switching profiles within a pack

Re-run the wizard and select a different profile. Or edit `~/.config/chezmoi/chezmoi.toml` directly and run `chezmoi apply`. The resolved state will snap exact customizations back to a named preset when possible.

## Rollback

### To the previous global-profile model

```bash
cd ~/dotfiles
git checkout main
chezmoi apply
```

This restores the pre-pack-first configuration. The `.chezmoidata/` files still contain the legacy profile definitions for backward compatibility.

### Partial rollback (keep pack-first, revert specific changes)

```bash
git log --oneline main..feat/pack-first-dotfiles
git revert <commit>
chezmoi apply
```

## Residual risks

- **Legacy data files**: `.chezmoidata/capability_packs.yaml` and `.chezmoidata/runtime_profiles.yaml` are kept for parity testing only. They should be removed once the branch is validated on all machines and merged.
- **research-and-strategy pack**: Design-complete but not implemented. Requires a focused security review of crawl/search MCPs before activation.
- **Obsidian memory**: The `visible_if` gating in pack.yaml relies on `memory_provider == "obsidian"` in chezmoi data. If data is missing, the MCP is silently excluded (safe default).
- **Bitwarden session**: Secret-backed MCPs fail silently if `~/.bw_session` is stale. The health-check playbook documents the fix.
