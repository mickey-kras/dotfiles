---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Use for
- multi-step implementation work
- approved specs that need execution planning
- risky changes that need explicit file targets, sequencing, and verification

## Do not use for
- tiny one-file changes where a written plan would add overhead
- ambiguous work that still needs product or workflow clarification

## Primary users
- `planner`
- `delivery-orchestrator`
- `staff-engineer`

## Inputs
- approved request, design, or execution brief

## Outputs
- implementation plan saved under `docs/plans/...`
- concrete task breakdown
- verification guidance
- execution handoff

## Overview

Write implementation plans assuming the executor has little codebase context and needs precise, reliable guidance. Document the files to touch, the tests to write or run, the constraints to keep in mind, and the verification needed to finish cleanly.

Assume they are a capable engineer, but they should not need tribal knowledge to execute the plan correctly.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** Use a dedicated worktree when the task is large enough to benefit from isolation.

**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default)

## Scope Check

If the spec covers multiple independent subsystems, suggest breaking it into separate plans, one per subsystem. Each plan should produce working, testable software on its own.

## Method

Build the plan in this order:
- confirm scope and boundaries
- map files and responsibilities
- break work into small, testable tasks
- define verification for each task
- review the plan for gaps before handoff

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agent workflows:** Use a task-by-task execution workflow. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

**Existing Code Evidence:** [Required if this plan references or modifies existing code. See "Evidence for Existing Code" below.]

**Checkpoints:** [Ordered list of named pause points where the executor stops and confirms before proceeding. See "Named Checkpoints" below.]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
 result = function(input)
 assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
 return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** - never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code - the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

## Evidence for Existing Code

Any claim about existing code - a function's behavior, a file's contents, a type signature, a caller - must be backed by an evidence fragment in the plan itself. This is the structural guard against "imaginary code": a plan that references a symbol without evidence is invalid, not just risky.

**Format for each referenced symbol, function, or file region:**

- `path/to/file.ext:LINE[-LINE]` - exact location
- A 1-5 line quoted fragment from a Read/Grep result showing the code as it exists today
- Tool used (`Read`, `Grep`, `git show <sha>:path`)

**Example:**

> `src/smart_links/validator.py:42-47` (Read)
> ```python
> def validate_smart_link(link: SmartLink) -> ValidationResult:
> if link.url is None:
> return ValidationResult.failure("url required")
> return _check_duplicate(link)
> ```

Consolidate evidence either inline next to the task that uses it, or in a top-level **Existing Code Evidence** section under the header - whichever keeps the reference close to its use. The rule is that evidence exists somewhere in the document, not that it's duplicated.

**Out of scope:** new files and new code you are adding. Evidence is only required for claims about what already exists.

## Named Checkpoints

A checkpoint is a pause point in the plan where the executor stops, reports state, and waits for a human or supervising agent to say "continue" or "redirect." Checkpoints are part of the plan - they're approved up front, not improvised mid-execution.

**Rules:**
- Every plan lists its checkpoints in the header so both the user and executor see exit ramps before work starts
- Each checkpoint has a **semantic name** (what's now true, not "Step 3") and a **verification hook** (a command or observation that proves the pause state is sound)
- Long tasks (>15 min of work) must contain at least one checkpoint
- Checkpoints should align with testable seams - a failing test about to go green, a migration about to be applied, a module about to be wired into a caller

**Format inside a task:**

```markdown
### Task N: [Component Name]

**Checkpoint:** `migration-staged` - schema file written and `psql --dry-run` passes; DB not yet migrated
**Verification:** `pg_dump --schema-only | diff -` shows the new table DDL
```

A checkpoint is not a comment. It is an instruction to the executor: at this point, stop, run the verification, report the result, and wait.

## Remember
- Exact file paths always
- Complete code in every step - if a step changes code, show the code
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself, not a separate agent handoff.

**1. Spec coverage:** Skim each section or requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags - any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

**4. Evidence & checkpoints:** Does every reference to existing code have an evidence fragment? Does every long task have a named checkpoint with a verification hook? A plan that fails either check is a plan failure, same severity as a placeholder.

If you find issues, fix them inline. No need to re-review - just fix and move on. If you find a spec requirement with no task, add the task.

## Execution Handoff

After saving the plan, offer execution choice:

**"Plan complete and saved to `docs/plans/<filename>.md`. Two execution options:**

**1. Agent-driven execution (recommended)** - I dispatch a fresh specialist per task or batch, with review between checkpoints

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?"**

**If Agent-driven chosen:**
- Fresh specialist per task or batch plus review between checkpoints

**If Inline Execution chosen:**
- Batch execution with checkpoints for review
