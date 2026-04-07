# Software Development Quickstart

Use this pack for delivery work that spans planning, implementation, testing, review, docs, and incident response.

## Default flow

1. Research the local codebase and the primary docs.
2. Plan if the change spans more than 3 files or carries real risk.
3. Implement in small verified steps.
4. Run the relevant tests before claiming completion.
5. Use code review mode for bug finding, risk, and missing coverage.

## Profile guidance

| Profile | Use when | Key capabilities |
| --- | --- | --- |
| `restricted` | Read-heavy repo work or low-trust machines | Git read, GitHub/AzDO read, no local shell |
| `balanced` | Daily driver for most development work | Full git, shell, docker, k8s, terraform |
| `open` | Personal-machine mode for broader access | Cloud CLIs, web search, secret-backed MCPs |

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
