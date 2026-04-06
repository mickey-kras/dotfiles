---
name: receiving-code-review
description: Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable
---

# Receiving Code Review

## Use for
- processing review comments before implementing them
- checking whether feedback is correct for this codebase
- clarifying unclear, conflicting, or incomplete review items

## Do not use for
- writing the initial review
- blindly implementing comments without verification

## Primary users
- `backend-engineer`
- `frontend-engineer`
- `staff-engineer`
- `quality-engineer`

## Inputs
- review comments
- current code, tests, and relevant requirements

## Outputs
- clarified review items
- reasoned acceptance or pushback
- verified implementation of accepted items

## Overview

Review feedback is input to evaluate, not a command to obey. Treat each item as a technical claim that must be checked against the codebase and the intended behavior.

**Core principle:** Verify before implementing.

## Method

Work through review feedback in this order:
- read the full review without reacting
- restate each item as a technical requirement
- verify it against code, tests, and requirements
- implement accepted items one at a time
- push back when the feedback is wrong for valid technical reasons

## Clarify Before Acting

If any item is unclear:
- stop
- ask for clarification before implementing any related item

Do not partially implement a mixed review set when unresolved comments could change the correct approach.

## Evaluation Checklist

Before accepting a review item, check:
- is it technically correct for this codebase?
- does it preserve intended behavior?
- does existing code or tests explain why the current implementation exists?
- does it conflict with prior user decisions or documented requirements?

If you cannot answer those questions quickly, investigate or ask.

## Pushback Rules

Push back when:
- the suggestion breaks existing functionality
- the reviewer lacks important context
- the suggestion violates YAGNI for unused code
- the suggestion conflicts with stated architecture or requirements

Push back with:
- technical reasoning
- concrete references to code or tests
- a question when there is still uncertainty

## Response Style

Avoid performative agreement. Prefer:
- a brief technical acknowledgment
- a clarification question
- or direct implementation

Good:
- `Fixed the missing null handling in <path>.`
- `Checked this against the compatibility requirement. We still need the legacy path because ...`
- `Need clarification on comments 4 and 5 before changing the control flow.`

Bad:
- `You're absolutely right!`
- `Great point!`
- `Thanks for catching that!`

## Implementation Order

For multi-item feedback:
- clarify unclear items first
- fix blocking or security issues first
- then fix simpler correctness issues
- then address larger refactors
- verify each accepted item before moving on

## Correcting Your Own Pushback

If you pushed back and later confirm the reviewer was right:
- state that fact briefly
- name what changed your conclusion
- implement the fix

Do not turn it into a long apology or defense.

## Related Skills

- `requesting-code-review`
- `verification-before-completion`
