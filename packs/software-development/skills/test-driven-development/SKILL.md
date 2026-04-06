---
name: test-driven-development
description: Use when implementing any feature or bugfix, before writing implementation code
---

# Test-Driven Development

## Use for
- new features
- bug fixes
- refactoring with behavior protection
- behavior changes that should be locked in

## Do not use for
- throwaway prototypes unless the user explicitly wants rigor
- generated code
- simple configuration changes with no executable behavior to lock down

## Primary users
- `backend-engineer`
- `frontend-engineer`
- `staff-engineer`
- `quality-engineer`
- `debugger`

## Inputs
- desired behavior, bug report, or change request

## Outputs
- failing test that proves the target behavior matters
- minimal implementation to satisfy the test
- verification that the target path is now green

## Overview

Write the test first. Watch it fail for the expected reason. Then write the minimum code needed to make it pass.

**Core principle:** If you did not watch the test fail first, you do not know whether it proves the behavior you care about.

## Method

Follow a strict red-green-refactor loop:
- write one failing test
- verify it fails for the expected reason
- write the minimum code to pass
- verify green
- refactor while staying green

## RED

Write one test for one behavior.

The test should:
- have a clear name
- express the intended behavior
- avoid unnecessary mocks
- be small enough that failure is easy to interpret

Bad test smell:
- broad names
- many assertions about unrelated behavior
- mocks proving the mock configuration instead of the product behavior

## VERIFY RED

Run the smallest command that proves the new test fails.

Confirm:
- it fails, rather than crashing unexpectedly
- the failure matches the missing or broken behavior
- it is not already green

If it passes immediately, the test is not proving the new behavior yet.

## GREEN

Write the smallest implementation that makes the failing test pass.

Rules:
- no extra features
- no "while I am here" refactors
- no speculative abstractions
- do not widen the implementation beyond what the test requires

## VERIFY GREEN

Run the targeted test again, then any immediately relevant broader verification.

Confirm:
- the target test passes
- nearby tests still pass
- there are no obvious new warnings or failures

## REFACTOR

Only after green:
- remove duplication
- improve names
- extract helpers
- clean structure without changing behavior

Keep the tests green throughout.

## Red Flags

Stop and reset if you catch yourself:
- writing production code before the first failing test
- writing tests after implementation "just to verify"
- keeping premature implementation as a reference
- adding options, abstractions, or refactors not demanded by the test

## Related Skills

- `systematic-debugging`
- `verification-before-completion`
