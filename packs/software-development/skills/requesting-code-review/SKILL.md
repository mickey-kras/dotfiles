---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
---

# Requesting Code Review

## Use for
- meaningful implementation checkpoints
- major features or risky refactors
- final review before merge

## Do not use for
- trivial edits where review overhead adds no value
- unfinished work with known blocking failures unless the review is specifically about those failures

## Primary users
- `backend-engineer`
- `frontend-engineer`
- `staff-engineer`
- `quality-engineer`
- `planner`

## Inputs
- diff or commit range
- intended behavior
- requirement, plan, or success criteria being validated

## Outputs
- focused review request
- actionable review findings
- decision on whether to continue or fix issues first

## Overview

Use the local `code-reviewer` agent to inspect the work product at deliberate checkpoints. Keep the request narrow enough that the reviewer can reason about the actual change rather than your whole session.

**Core principle:** Review before defects compound.

## Method

For each review checkpoint:
- define the exact scope
- provide the intended behavior and requirement context
- include the diff or commit range
- dispatch `code-reviewer`
- act on the findings before proceeding

## Good Review Scope

A good request includes:
- what changed
- what it should do
- what range to review
- any known risks or assumptions

Prefer concrete ranges such as:
- `BASE_SHA`
- `HEAD_SHA`

## When Review Is Mandatory

- after a significant task batch in agent-driven execution
- after completing a major feature or risky bugfix
- before merge

## When Review Is Optional but Valuable

- before a refactor
- after a tricky bug fix
- when you want a fresh pass on test gaps, regressions, or edge cases

## Acting on Findings

- fix critical issues immediately
- fix important issues before moving on
- record or defer minor issues intentionally
- push back only with technical reasoning and evidence

## Common Mistakes

- requesting review with no requirement context
- sending an overly broad diff that hides the real risk
- continuing despite unresolved important findings
- arguing with correct feedback instead of fixing it

## Related Skills

- `receiving-code-review`
- `verification-before-completion`
