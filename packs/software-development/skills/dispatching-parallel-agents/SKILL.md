---
name: dispatching-parallel-agents
description: Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies
---

# Dispatching Parallel Agents

## Use for
- 2 or more independent investigations or workstreams
- failures grouped by different files, subsystems, or root causes
- bounded tasks that can be delegated without shared context

## Do not use for
- tightly coupled work on the same files or shared state
- situations where one result changes the approach for the others
- vague debugging where the problem has not been separated yet

## Primary users
- `delivery-orchestrator`
- `planner`
- `staff-engineer`
- `debugger`

## Inputs
- list of independent problem domains
- constraints, ownership boundaries, and expected outputs

## Outputs
- one focused task per agent
- clear ownership boundaries
- integration checklist for returned work

## Overview

Use parallel agents only when the work is truly separable. The point is not "more agents"; it is less context per agent and faster progress on independent tracks.

**Core principle:** One agent per independent domain.

## Method

Follow this sequence:
- separate the problem into independent domains
- define one self-contained task per domain
- dispatch all independent tasks in parallel
- review and integrate the results carefully

## Independence Check

Use parallel dispatch when all of these are true:
- each task can be understood without the others
- agents will not edit the same files or depend on the same intermediate result
- one task finishing early does not change the others materially

If any of those are false, keep the work sequential.

## Task Design

Each agent task should include:
- exact scope
- specific goal
- constraints on files or systems
- what to return

Good task shape:
- "Fix failures in `agent-tool-abort.test.ts` without changing unrelated production code. Return root cause, changes made, and verification."

Bad task shape:
- "Fix all the tests."

## Handoff Format

Each task dispatched to a parallel agent should include:
- **Scope**: exact files, systems, or domains in play
- **Goal**: one measurable outcome
- **Constraints**: what not to touch, what to preserve
- **Return format**: what the agent should report back (root cause, changes, evidence)
- **Dependencies**: anything the agent needs to read or check first

This prevents agents from drifting into unrelated work or producing outputs
that cannot be integrated.

## Integration Rules

When agents return:
- read each summary before merging conclusions
- check for overlapping edits or incompatible assumptions
- run the full verification suite after integration
- do not trust parallel results without final verification

## Common Mistakes

- dispatching related failures that should have been investigated together
- giving agents broad goals instead of one bounded problem each
- omitting constraints, which invites unnecessary refactoring
- integrating results without conflict review or full verification

## Related Skills

- `writing-plans`
- `executing-plans`
- `verification-before-completion`
