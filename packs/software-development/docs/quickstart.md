# Software Development Quickstart

This is the only supported pack in the repo. Start from the default `full` selection and only turn something off when you have a specific reason.

## Default flow

1. Research the local codebase and the primary docs.
2. Plan if the change spans more than 3 files or carries real risk.
3. Implement in small verified steps.
4. Run the relevant tests before claiming completion.
5. Use code review mode for bug finding, risk, and missing coverage.

## Default setup

- Memory defaults to Obsidian
- The wizard auto-detects an existing vault path when possible and otherwise uses `~/Obsidian/memory-vault`
- Optional CLI installs exist for Claude Code, Codex, Cursor, Gemini CLI, and Droid; they are off by default
- macOS is the primary target, Linux is supported, and Windows is secondary through Git Bash

## Model guidance

- Use the strongest model (opus) for architecture, debugging, and security review.
- Use faster modes for routine edits, structured refactors, and narrow follow-up tasks.
- Match reasoning effort to task ambiguity: lightweight for mechanical transforms, deeper for design decisions.

## Key skills

- `writing-plans` and `executing-plans` for multi-step delivery
- `test-driven-development` for implementation rigor
- `systematic-debugging` for failure investigation
- `verification-before-completion` before claiming work is done
- `context-budget` for read-heavy or delegation-heavy sessions
- `dispatching-parallel-agents` for independent concurrent work
- `using-git-worktrees` for isolated feature work

## Playbooks

- [Execute](./playbooks/execute.md) - non-trivial delivery sequence
- [Review](./playbooks/review.md) - code review checklist
- [Orchestration](./playbooks/orchestration.md) - multi-agent routing and context discipline
- [Health Check](./playbooks/health-check.md) - installation verification
