---
name: context-budget
description: Use when delegating work, reading large files, or operating in a long session to keep context lean, prevent degraded output quality, and decide when to checkpoint or start fresh
---

# Context Budget

## Use for
- before spawning subagents or parallel workers
- before reading large files or many files in one turn
- when the session already feels heavy
- when you need to decide whether to inline, summarize, delegate, or checkpoint

## Do not use for
- tiny single-file edits with no delegation and no context pressure

## Primary users
- `delivery-orchestrator`
- `planner`
- `staff-engineer`
- any agent delegating or reading broadly

## Inputs
- current task shape
- files or outputs you are considering reading
- current session pressure

## Outputs
- leaner prompts
- smaller reads
- clearer delegation boundaries
- explicit checkpoint or fresh-session advice when needed

## Overview

Context pressure is a quality risk, not just a convenience issue.

When context gets heavy, quality degrades before the model obviously fails. The first signs are usually vagueness, skipped steps, and overconfident summaries.

## Core Rules

- do not read agent definition files just to use the agent
- do not inline large files into subagent prompts when the agent can read them directly
- prefer summaries, frontmatter, headers, and targeted excerpts over full-file reads
- keep orchestrators thin: route and summarize, do not absorb specialist work
- if heavy reading is required, delegate the read and ask for a structured result
- when context is already congested, reduce scope before continuing

## Warning Signs

- completion claims get vague
- the plan loses detail it had earlier
- the agent starts skipping protocol steps it normally follows
- a delegated worker returns structural success but weak semantic evidence
- you are tempted to read one more large file "just to be safe"

## Method

1. Decide whether the next step needs full content or only a summary.
2. Read the smallest amount that still supports the decision.
3. If multiple heavy reads are needed, delegate them instead of accumulating them locally.
4. Keep subagent prompts file-based: point to paths, not pasted bodies.
5. When the session is getting heavy, warn the user and suggest checkpointing or a fresh session.

## Context Cost Awareness

Before reading a file or spawning an agent, estimate the cost:
- agent definition files: ~2-5KB each, rarely needed for routing
- skill SKILL.md files: ~130 lines, worth reading for protocol
- full source files: varies widely, read only the needed section
- large diffs or logs: summarize or delegate, never inline fully

Prefer file-path references over pasted content in subagent prompts.
The agent can read the file itself at lower net cost than carrying it in the prompt.

## Escalation Guidance

- normal: targeted reads, concise summaries, focused prompts
- degrading: frontmatter-only or excerpt-only reads, aggressive delegation
- poor: checkpoint progress, avoid new broad reads, prefer a fresh session

## Example

Instead of:
- pasting a long diff plus three design docs into a review prompt

Prefer:
- point the reviewer at the changed files
- summarize the intent in a few lines
- name the exact risks to inspect

## Bottom Line

Use context deliberately. Smaller, sharper context usually beats bigger context.
