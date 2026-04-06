---
description: Context and effort management guidance
globs: ["**/*"]
---

# Performance and Context Management

## Reasoning Effort

- use lightweight effort for straightforward edits and mechanical transformations
- use deeper reasoning for architecture, debugging, security analysis, and ambiguous requirements
- do not spend high reasoning effort on tasks that are mostly deterministic

## Context Management

- use `/compact` proactively when the session is getting heavy
- start a fresh session for unrelated work instead of dragging old context forward
- avoid broad multi-file work late in a congested session
- prefer explicit plans and smaller batches when the work spans many files
- do not inline large files into subagent prompts when the agent can read them directly
- use the `context-budget` skill for delegation-heavy or read-heavy work
- treat vagueness, skipped steps, and weak summaries as early context-pressure warnings

## Model Use

- reserve the strongest model or deepest reasoning for high-judgment work
- use faster modes for routine edits, structured refactors, and narrow follow-up tasks
- keep the choice proportional to task ambiguity and risk

## Troubleshooting

- read the full error output before proposing fixes
- make one clear change at a time when the failure mode is uncertain
- do not retry the same failed approach without new evidence
