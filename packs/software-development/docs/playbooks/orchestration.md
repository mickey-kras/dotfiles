# Orchestration Playbook

Use this when the task involves multiple agents, phases, or cross-cutting concerns.

## Quality gates

Every phase transition should produce evidence, not assertions:
- test results, rendered diffs, or config snapshots
- not "it should work" or "I verified it"

## Agent routing

| Situation | Route to |
| --- | --- |
| Ambiguous or large request | delivery-orchestrator |
| Architecture or tradeoff decision | staff-engineer or planner |
| Feature implementation with clear spec | backend-engineer or frontend-engineer |
| Bug with unclear root cause | debugger with systematic-debugging skill |
| Review before merge | code-reviewer with requesting-code-review skill |
| Infrastructure or deployment | devops-engineer |
| Security concern | security-engineer |
| Docs or ADR | technical-writer |
| Incident in progress | incident-commander |

## Parallel work

Use `dispatching-parallel-agents` when:
- two or more tasks have no shared state
- outputs are disjoint files or topics
- neither task depends on the other's result

Do not parallelize when:
- tasks share files or state
- one task's output informs the other's approach

## Context discipline

- Use `context-budget` in read-heavy or delegation-heavy sessions.
- Start a new session for unrelated work.
- Prefer `writing-plans` over carrying large plans in conversation context.
- Keep delegated prompts focused: include file paths and line numbers, not full file contents.
- Use `/compact` when context pressure symptoms appear: vagueness, skipped steps, weak summaries.

## Handoff format

When routing between agents, include:
- Goal: what needs to happen
- Scope: which files, which systems
- Constraints: what must not change
- Context: what has already been tried or decided
- Verification: how to confirm success
