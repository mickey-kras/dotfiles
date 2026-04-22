# GSD (Get Shit Done) Patterns

Source: `/Users/mikhailkrasilnikov/Downloads/get-shit-done-main/`

## Core framework

GSD is a Claude Code project management framework with agents, commands, hooks,
references, and workflow templates. Key directories:
- `agents/` -- 24 specialized agents (planner, executor, verifier, debugger, etc.)
- `get-shit-done/` -- core framework with contexts, references, templates, workflows
- `commands/` -- slash commands for plan, execute, verify phases
- `hooks/` -- pre/post tool-use hooks for quality gating

## Adaptable patterns

### 1. Context budget management
- Agents are aware of their context cost
- Skills load lightweight indexes (~130 lines), not full agent defs (100KB+)
- Plans are structured to minimize re-reading
- Sessions are kept focused; broad work is deferred to fresh sessions

### 2. Verification culture
- Goal-backward verification: start from what SHOULD exist, verify it DOES
- Task completion != goal achievement (a placeholder file is not a working feature)
- Verification requires fresh evidence, not previous-run claims
- Red-green cycle: write test, see fail, implement, see pass, revert, see fail again

### 3. Execution discipline
- Plans are prompts, not documents: they must be executable without interpretation
- Phases decompose into 2-3 parallel tasks per wave
- Dependency graphs determine execution order
- Gap closure mode: when verification fails, re-plan only the gaps

### 4. Model profiles
- Planner uses opus (high-judgment work)
- Executor uses sonnet (routine implementation)
- Verifier uses opus (needs skeptical judgment)
- Researcher uses haiku or sonnet (breadth over depth)

## What NOT to copy
- GSD's full project management framework (phases, sprints, roadmaps)
- Slash command infrastructure (we use skills instead)
- Hook scripts specific to GSD's workflow
- The 24-agent roster verbatim
