# Phase 4: Research and Strategy Pack Implementation

## Goal
Promote the design-complete research-and-strategy pack to full implementation.

## Tasks
1. Create `packs/research-and-strategy/pack.yaml` with 3 profiles (desk, analyst, investigation)
2. Create agents: trend-researcher, competitive-analyst, evidence-reviewer, report-writer, executive-summary-writer
3. Create rules: evidence-over-claims, uncertainty-reporting, citation-discipline, report-structure
4. Create skills: context-budget, obsidian-memory, writing-plans, verification-before-completion (symlink-compatible)
5. Create docs: quickstart, playbooks (research-intake, evidence-matrix, executive-summary)
6. Wire templates: ensure resolved-state.json handles the new pack

## Adapted from
- Agency-agents: trend-researcher, feedback-synthesizer, evidence-collector, reality-checker
- Design doc: docs/packs/research-and-strategy.md

## Verification
- pack.yaml validates against schema
- All profiles reference valid catalog items
- Templates render correctly for new pack profiles
