# Vendored Superpowers Skills

This directory is the staging area for workflow skills selectively vendored from the upstream `superpowers` project.

## Intent
- keep useful workflow discipline
- remove reliance on upstream plugin updates for core behavior
- adapt vendored skills to local dotfiles policy

## Initial Scope
- verification-before-completion
- systematic-debugging
- test-driven-development
- requesting-code-review
- receiving-code-review
- using-git-worktrees
- writing-plans
- executing-plans
- dispatching-parallel-agents

## First Vendored Batch
- verification-before-completion
- systematic-debugging
- test-driven-development
- requesting-code-review
- receiving-code-review

## Second Vendored Batch
- writing-plans
- executing-plans
- using-git-worktrees
- dispatching-parallel-agents

These copies were normalized to local policy:
- ASCII-safe content
- no upstream plugin prefixes
- no upstream "human partner" wording
- no extra upstream test or creation artifacts unless they help execution

## Rules For Vendored Copies
- no AI attribution text
- no connector assumptions
- no Sentry references
- no policy conflicts with runtime profiles
- preserve source attribution in repository history or local notes, not in generated output
