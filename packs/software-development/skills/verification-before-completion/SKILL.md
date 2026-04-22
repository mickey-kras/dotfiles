---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
---

# Verification Before Completion

## Use for
- before claiming a fix works
- before saying tests pass
- before committing, pushing, or opening a PR
- before handing work to review

## Do not use for
- early exploration where no success claim is being made yet

## Primary users
- all implementation agents
- `quality-engineer`
- `code-reviewer`
- `delivery-orchestrator`

## Inputs
- current claim or status you are about to report
- exact command that proves or disproves the claim

## Outputs
- fresh verification evidence
- accurate status statement tied to that evidence
- explicit note of any accepted deviation from the original target

## Overview

Claiming work is complete without verification is dishonesty, not efficiency.

**Core principle:** Evidence before claims, always.

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you have not run the verification command recently enough to support the claim, do not make the claim.

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

## Method

For every completion claim:
- identify the proving command
- run it fresh
- read the real output
- state the result exactly as the output supports it

Then verify backward from the intended outcome:
- re-check the stated goal, acceptance criteria, or plan
- confirm the evidence actually proves that outcome, not just a nearby proxy
- if the result intentionally differs from the original target, document the deviation explicitly instead of silently treating it as complete

## Goal-Backward Verification

Task completion is not goal achievement. A placeholder file satisfies "create component"
but does not satisfy "working component." Always verify backward from the goal:

1. What must be TRUE for the goal to be achieved?
2. What must EXIST in the codebase for those truths to hold?
3. What must be WIRED for those artifacts to function together?

Verify each level against the actual codebase, not against task status.

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |
| Original goal satisfied | Evidence matches intended behavior | Nearby behavior, summary text |

## Red Flags - STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"
- Tired and wanting work over
- **ANY wording implying success without having run verification**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence != evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter != compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion != excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

## Key Patterns

**Tests:**
```
GOOD: [Run test command] [See: 34/34 pass] "All tests pass"
BAD: "Should pass now" / "Looks correct"
```

**Regression tests (TDD Red-Green):**
```
GOOD: Write -> Run (pass) -> Revert fix -> Run (MUST FAIL) -> Restore -> Run (pass)
BAD: "I've written a regression test" (without red-green verification)
```

**Build:**
```
GOOD: [Run build] [See: exit 0] "Build passes"
BAD: "Linter passed" (linter doesn't check compilation)
```

**Requirements:**
```
GOOD: Re-read plan -> Create checklist -> Verify each -> Report gaps or completion
BAD: "Tests pass, phase complete"
```

**Accepted deviations:**
```
GOOD: "Original plan expected X. We intentionally shipped Y instead because Z. Verification covers Y, not X."
BAD: Quietly treating Y as if X was delivered
```

**Agent delegation:**
```
GOOD: Agent reports success -> Check VCS diff -> Verify changes -> Report actual state
BAD: Trust agent report
```

## Why This Matters

From prior failures:
- the user lost confidence in the reported result
- Undefined functions shipped - would crash
- Missing requirements shipped - incomplete features
- Time wasted on false completion -> redirect -> rework
- Violates the collaboration principle that honesty beats false confidence.

Accepted deviations are not failures when they are explicit, defended, and verified against the new reality. Hidden deviations are still failures.

## When To Apply

**ALWAYS before:**
- ANY variation of success/completion claims
- ANY expression of satisfaction
- ANY positive statement about work state
- Committing, PR creation, task completion
- Moving to next task
- Delegating to agents

**Rule applies to:**
- Exact phrases
- Paraphrases and synonyms
- Implications of success
- ANY communication suggesting completion/correctness

## The Bottom Line

**No shortcuts for verification.**

Run the command. Read the output. THEN claim the result.

This is non-negotiable.
