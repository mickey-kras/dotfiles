---
description: Research-first delivery workflow
globs: ["**/*"]
---

# Development Workflow: Research -> Plan -> Test -> Implement -> Review

## 1. Research Before Writing Code

Before implementing anything non-trivial:
- search for prior art in the repo and surrounding ecosystem
- verify API behavior in official documentation before assuming
- check existing issues, discussions, or docs for edge cases and known failure modes
- prefer MCP-backed documentation and repo tools when available
- use the `context-budget` skill when delegation or broad reading would otherwise bloat the session

## 2. Plan Before Implementing

- for changes touching more than 3 files, outline the approach before coding
- identify dependencies, risks, verification steps, and sequencing
- use the `planner` agent for substantial changes
- use the `writing-plans` skill when the work needs a durable implementation plan

## 3. Test Before or Alongside Implementation

- start with the expected behavior, then implement the minimum change to satisfy it
- use the `test-driven-development` skill when it fits the task
- keep verification proportional: unit, integration, or end-to-end depending on risk
- prefer meaningful coverage over target-chasing

## 4. Implement With Verification Loops

- make incremental changes and verify between steps
- use the `systematic-debugging` skill for failures instead of guessing
- use the `verification-before-completion` skill before claiming success
- verify against the intended outcome, not just passing proxies or agent summaries
- if the delivered result intentionally differs from the original target, make that deviation explicit

## 5. Review Before Merge

- use the `code-reviewer` agent for correctness and regression risk
- use the `quality-engineer` agent for broader verification concerns
- address critical and high-severity findings before merge
- use conventional commit format for every commit
