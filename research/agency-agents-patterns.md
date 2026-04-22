# Agency-Agents Patterns

Source: `/Users/mikhailkrasilnikov/Downloads/agency-agents-main/`

## Structure

Agency-agents is a large agent collection organized into divisions matching
effective-claude. Key additions:
- `strategy/` -- NEXUS orchestration framework with handoff templates
- `strategy/coordination/` -- agent activation prompts and handoff templates
- `scripts/` -- automation for agent management

## NEXUS orchestration

The NEXUS (Network of EXperts, Unified in Strategy) framework defines:
- Seven-phase pipeline: Discovery, Strategy, Scaffolding, Build, Hardening, Launch, Evolve
- Quality gates between phases (no phase advances without passing its gate)
- Context continuity via structured handoff documents
- Parallel execution for independent workstreams
- Evidence over claims principle (matches our verification-before-completion)

### Handoff template structure
- Metadata: from, to, phase, task reference, priority, timestamp
- Context: project, current state, relevant files, dependencies, constraints
- Deliverable request: what is needed, acceptance criteria, reference materials
- Quality expectations: must pass, evidence required, handoff to next

## Agents to adapt per pack

### Content-creation pack (from marketing + design)
- content-creator -> already adapted as content-strategist + script-writer
- growth-hacker -> patterns for channel-adaptation-editor
- social-media-strategist -> patterns for channel-adaptation-editor
- linkedin-content-creator -> patterns for channel-adaptation-editor
- seo-specialist -> patterns for content-strategist
- brand-guardian -> already adapted
- visual-storyteller -> already adapted

### Research-and-strategy pack (from product + testing)
- trend-researcher -> adapt as trend-researcher agent
- feedback-synthesizer -> adapt as feedback-synthesizer agent
- evidence-collector -> patterns for evidence-reviewer agent
- reality-checker -> patterns for evidence-reviewer agent

### Software-development pack (from testing + engineering)
- evidence-collector -> patterns for quality-engineer hardening
- reality-checker -> patterns for code-reviewer hardening

## What NOT to copy
- 150+ agent roster (we curate best 7-15 per pack)
- Full NEXUS seven-phase pipeline (too heavyweight for dotfiles)
- Emoji in agent definitions
- Division structure (we use packs)
- Detailed success metrics with specific percentages (not measurable in our context)
