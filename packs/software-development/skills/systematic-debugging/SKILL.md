---
name: systematic-debugging
description: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes
---

# Systematic Debugging

## Use for
- test failures
- production bugs
- flaky behavior
- build or integration failures
- unexpected regressions

## Do not use for
- speculative redesign before there is evidence
- ordinary implementation work with no failure to investigate

## Primary users
- `debugger`
- `backend-engineer`
- `frontend-engineer`
- `staff-engineer`
- `quality-engineer`

## Inputs
- failing test, error message, logs, or reproduction steps

## Outputs
- verified root cause
- smallest reliable fix direction or fix
- verification against the original failure
- remaining uncertainty if any

## Overview

Do not stack guesses. Debugging should reduce uncertainty step by step until the root cause is clear enough for a minimal fix.

**Core principle:** No fixes without root-cause investigation first.

## Method

Work in four phases:
- reproduce and gather evidence
- compare working and broken paths
- form one hypothesis and test it
- implement the smallest fix that addresses the confirmed cause

Return to earlier phases whenever new evidence contradicts the current theory.

## Phase 1: Reproduce and Gather Evidence

Before changing code:
- read the full error or failure output
- reproduce the problem consistently if possible
- check recent relevant changes
- identify which component, boundary, or environment is failing

In multi-component systems, add focused instrumentation at component boundaries. Confirm where data, config, or control flow first becomes wrong.

## Phase 2: Compare Against Reality

Look for:
- a nearby working example in the same codebase
- a reference implementation you are trying to match
- differences between working and broken behavior
- missing config, dependencies, or assumptions

Fixes are much safer when they explain the difference between "works" and "fails."

## Phase 3: One Hypothesis at a Time

State the current theory explicitly:
- `I think X is failing because Y.`

Then test it with the smallest possible change or observation.

Rules:
- one hypothesis at a time
- one meaningful variable at a time
- if the test fails, form a new hypothesis instead of piling on more changes

## Phase 4: Implement the Smallest Fix

Once the root cause is verified:
- create or keep a failing test if practical
- implement one fix aimed at the source, not the symptom
- verify the original failure is gone
- verify no obvious regressions were introduced

If multiple fix attempts fail, stop and question whether the architecture or mental model is wrong.

## Red Flags

Stop and reset if you catch yourself:
- making a "quick fix" before understanding the failure
- changing multiple things at once
- skipping reproduction because the issue "seems obvious"
- treating partial improvement as proof of root cause
- proposing a redesign without evidence

## Related Skills

- `test-driven-development`
- `verification-before-completion`
