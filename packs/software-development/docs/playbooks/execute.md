# Execution Playbook

Use this sequence for non-trivial delivery work:

1. Clarify goal, scope, constraints, and rollback conditions.
2. Inventory impacted files and current behavior before editing.
3. Add or update tests and fixtures for the intended behavior.
4. Implement in narrow slices and verify between slices.
5. Reconcile generated config, hooks, and managed assets before final verification.
6. Run final tests plus rendered-output checks before commit.

When the work is broad:
- use `writing-plans`
- use `executing-plans`
- keep delegation bounded and context-light
