# Dotfiles v2 Pack-First Architecture Plan

## Goal

Transform the 2-pack dotfiles into a 3-pack system by:
1. Enhancing productivity patterns across existing packs (adapted from GSD and agency-agents)
2. Upgrading software-development and content-creation agents with reference patterns
3. Implementing the research-and-strategy pack (currently design-complete)
4. Expanding test coverage and documentation

## Research documents

- [research/effective-claude-analysis.md](research/effective-claude-analysis.md)
- [research/gsd-patterns.md](research/gsd-patterns.md)
- [research/agency-agents-patterns.md](research/agency-agents-patterns.md)
- [research/mcp-candidates.md](research/mcp-candidates.md)

## Phase graph

```
Phase 0 -> Phase 1 -> Phase 2 ----\
                   |-> Phase 3 ----|-> Phase 5 -> Phase 7 -\
                   |-> Phase 4 ----|                        |-> Phase 8 -> Phase 9
                   |-> Phase 6 ---------> (merge) ---------/
```

## Phases

| Phase | Document | Summary |
|-------|----------|---------|
| 0 | [phases/phase-00-baseline.md](phases/phase-00-baseline.md) | Verify baseline, create plan docs |
| 1 | [phases/phase-01-productivity.md](phases/phase-01-productivity.md) | Enhance shared productivity patterns |
| 2 | [phases/phase-02-software-dev-upgrade.md](phases/phase-02-software-dev-upgrade.md) | Upgrade software-development agents |
| 3 | [phases/phase-03-content-creation.md](phases/phase-03-content-creation.md) | Enhance content-creation agents |
| 4 | [phases/phase-04-research-strategy.md](phases/phase-04-research-strategy.md) | Implement research-and-strategy pack |
| 5 | [phases/phase-05-mcp-research.md](phases/phase-05-mcp-research.md) | MCP security review for new pack |
| 6 | [phases/phase-06-tui-wizard.md](phases/phase-06-tui-wizard.md) | Update wizard for 3 packs |
| 7 | [phases/phase-07-security-governance.md](phases/phase-07-security-governance.md) | Update security governance docs |
| 8 | [phases/phase-08-testing.md](phases/phase-08-testing.md) | Expand test coverage |
| 9 | [phases/phase-09-docs-rollout.md](phases/phase-09-docs-rollout.md) | Final docs and rollout notes |

## Constraints

- Pack-first architecture: each pack owns its domain
- No new MCPs beyond existing approved set
- All output matches allowed charset
- No AI authorship attribution
- Conventional Commits for all commits
- Adapt, do not copy from reference sources
