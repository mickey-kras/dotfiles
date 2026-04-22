# Pack-First Architecture Rollout Notes

Branch: `feat/pack-first-dotfiles`

## What changed

### Architecture

The dotfiles moved from a global profile model to a **pack-first capability architecture**. Each pack owns its profiles, MCP catalog, agents, rules, skills, permissions, and settings. A shared resolver (`templates/resolved-state.json`) normalizes selections and feeds all host templates (Claude Code, Claude Desktop, Cursor, Codex) from one resolved state.

### Three-pack system

| Pack | Profiles | Purpose |
| --- | --- | --- |
| software-development | restricted, balanced, open | Software delivery across planning, implementation, testing, review, docs, and incident response |
| content-creation | focused, studio, campaign | Editorial, research, brand, and visual-production for writing and creative execution |
| research-and-strategy | desk, analyst, investigation | Evidence gathering, source synthesis, strategic recommendation, and executive reporting |

### New pack: research-and-strategy

Added `research-and-strategy` with three profiles:
- `desk` -- low-risk reading and local synthesis
- `analyst` (default) -- broader investigation with browser and process tools
- `investigation` -- wider crawling and search for trusted machines

5 agents: trend-researcher, competitive-analyst, evidence-reviewer, report-writer, executive-summary-writer
4 rules: evidence-over-claims, uncertainty-reporting, citation-discipline, report-structure
4 skills: context-budget, obsidian-memory, writing-plans, verification-before-completion
3 playbooks: research-intake, evidence-matrix, executive-summary

### Productivity enhancements

Patterns adapted from GSD (get-shit-done) and agency-agents reference sources:
- **Context cost awareness**: context-budget skill enhanced with file cost estimation guidance
- **Goal-backward verification**: verification-before-completion skill enhanced to verify backward from outcomes, not just forward from tasks
- **Handoff discipline**: dispatching-parallel-agents skill enhanced with structured handoff format
- **Model selection guidance**: performance rule enhanced with task-to-model mapping
- **Reality-checking discipline**: quality-engineer agent enhanced with evidence-collector skepticism patterns
- **Evidence requirements**: code-reviewer agent enhanced with structured evidence rules
- **Routing discipline**: delivery-orchestrator agent enhanced with NEXUS quality-gate and handoff patterns

### Content-creation enhancements

- content-strategist: SEO awareness, content pillars, reader journey mapping
- channel-adaptation-editor: platform-specific guidance (LinkedIn, Twitter, blog, email, video)
- editorial-reviewer: structured review checklist with evidence discipline
- campaign-build playbook: research-first methodology, repurposing paths

### Bootstrap wizard

The installer (`scripts/bootstrap-wizard.sh`) now discovers all 3 packs automatically. No code changes needed -- the wizard was already pack-generic. The `pack_state.py` helper now includes `research_workspace` in legacy config output.

### Documentation

- `packs/research-and-strategy/docs/quickstart.md` -- profile table, agent list, model guidance, playbook links
- `packs/research-and-strategy/docs/playbooks/` -- research-intake, evidence-matrix, executive-summary
- `docs/security/mcp-decisions/research-and-strategy.md` -- per-profile MCP decisions
- `research/` -- analysis documents for effective-claude, GSD, agency-agents reference sources
- `phases/` -- phase documents for the transformation plan

### Security

Every MCP in the new pack is drawn from the existing approved catalog. No new MCPs were introduced. The `docs/security/mcp-decisions.md` table updated from "candidate" to actual placement for all research-and-strategy MCPs. Sentry remains excluded.

### Tests

- 26 JavaScript tests covering pack loading, profile matching, validation, cross-pack consistency, and fixture rendering for all 3 packs
- 6 Python tests covering schema validation, rendered-output snapshots (36 template x profile combinations), and runtime parity
- All 32 tests pass

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

This restores the pre-pack-first configuration.

### Partial rollback (keep pack-first, revert specific changes)

```bash
git log --oneline main..feat/pack-first-dotfiles
git revert <commit>
chezmoi apply
```

## Residual risks

- **Legacy data files**: `.chezmoidata/` files kept for parity testing only. Remove after branch is validated on all machines and merged.
- **Obsidian memory**: `visible_if` gating relies on `memory_provider == "obsidian"` in chezmoi data. Missing data silently excludes the MCP (safe default).
- **Bitwarden session**: Secret-backed MCPs fail silently if `~/.bw_session` is stale. The health-check playbook documents the fix.
- **Research pack web MCPs**: http, exa, firecrawl carry high prompt-injection risk. Gated to `investigation` profile only, for trusted personal machines.
- **Research pack maturity**: New pack has not been validated in production use. Agents and rules may need tuning after real-world usage.
