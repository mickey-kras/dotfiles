---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

# Executing Plans

## Use for
- executing an existing implementation plan
- working through a multi-step plan with checkpoints
- carrying out a plan in a fresh session or isolated workspace

## Do not use for
- ambiguous work that still needs planning
- tiny changes where plan execution overhead is unnecessary

## Primary users
- `backend-engineer`
- `frontend-engineer`
- `staff-engineer`
- `quality-engineer`

## Inputs
- plan document
- current repo state

## Outputs
- completed or partially completed plan progress
- verification results per task or checkpoint
- blockers and open questions if execution stops

## Overview

Load plan, review critically, execute all tasks, report when complete.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

**Note:** If specialist agents are available, prefer task-by-task execution with review between tasks rather than blindly running the full plan inline.

## Method

Work in a disciplined loop:
- load and challenge the plan
- execute one task or checkpoint at a time
- verify before moving forward
- stop on blockers instead of improvising around them

## The Process

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with the user before starting
4. If no concerns: Create TodoWrite and proceed

### Step 2: Execute Tasks

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed

**Honor named checkpoints.** When a task declares a `**Checkpoint:**`, treat it as a hard stop: run the checkpoint's verification hook, report the observed state in one line, and wait for "continue" or redirection. Do not roll past a checkpoint because the next task "seems obvious" - the checkpoint exists because the plan's author wanted a human or supervisor decision at that seam. In agent-driven mode, report the checkpoint state to the dispatching agent instead of a human, but still wait for acknowledgment.

### Step 3: Complete Development

After all tasks complete and verified:
- Verify the final state before claiming completion
- Present the user with integration options appropriate to the current repo workflow

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- the user updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent

## Integration

**Related workflow skills:**
- **using-git-worktrees** - Set up isolated workspace before starting
- **writing-plans** - Creates the plan this skill executes
- **verification-before-completion** - Verify work before claiming success
