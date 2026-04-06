---
name: obsidian-memory
description: Use when the configured memory provider is Obsidian and the task needs durable notes, recall, or explicit knowledge capture in the vault
---

# Obsidian Memory

## Use for
- capturing durable notes worth keeping beyond the current session
- reading prior notes that should influence current work
- project memory, decisions, follow-ups, and reference material
- explicit knowledge capture after meaningful work is complete

## Do not use for
- automatic note creation on every session start
- transient scratch work better kept in the current chat
- writing to the vault without a clear reason or user value

## Primary users
- `delivery-orchestrator`
- `planner`
- `product-manager`
- `technical-writer`
- any agent asked to preserve or retrieve durable knowledge

## Inputs
- the memory task to perform
- note intent or retrieval goal
- current project or topic context

## Outputs
- relevant notes retrieved from the Obsidian vault
- new or updated notes when durable capture is justified
- concise summary of what was read or written

## Overview

Obsidian memory is explicit memory, not magic memory.

The vault should store durable, reusable knowledge. Do not treat it like an automatic transcript dump. Write only what is likely to help later work.

## When to Write

Prefer writing only when at least one of these is true:
- a decision should be preserved
- a reference note will save future rework
- a project state summary will materially help the next session
- the user explicitly asked to save memory

## When to Read

Read first when:
- the user refers to prior decisions or notes
- the task depends on project memory that may already exist
- a durable note is more trustworthy than ad hoc recollection

## Method

1. Decide whether the task needs durable memory or just current-session reasoning.
2. If memory is needed, search or read the smallest relevant note set first.
3. Summarize what matters before writing anything new.
4. Write or update notes only when the information is worth preserving.
5. Keep notes concise, factual, and easy to reuse later.

## Writing Rules

- prefer updating an existing note over creating duplicates
- use descriptive titles and predictable placement when possible
- store decisions, constraints, links, and next steps rather than chat-like narration
- do not write secrets or sensitive tokens into the vault
- do not claim memory was saved unless the write actually succeeded

## Response Rules

- say when you are using Obsidian as the memory surface
- distinguish between retrieved memory and newly written memory
- if the configured provider is not Obsidian, fall back gracefully

## Bottom Line

Use the vault as durable knowledge, not as automatic session exhaust.
