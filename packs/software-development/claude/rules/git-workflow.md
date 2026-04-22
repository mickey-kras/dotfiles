---
description: Git conventions and PR workflow
globs: ["**/*"]
---

# Git Workflow

## Commit Messages

Format: `<type>[optional scope]: <description>`

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`

- subject line in imperative mood, ideally under 72 characters
- body is optional and should explain why, not repeat the diff
- use `feat` for new functionality and `fix` for bug fixes
- breaking changes use `!` before the `:` or a `BREAKING CHANGE:` footer

## Branching

- use feature branches, not direct commits to main
- keep branch names short and descriptive
- squash-merge pull requests unless there is a specific reason not to

## Pull Requests

- review the complete branch diff, not just the last commit
- summarize what changed, why, and how it was verified
- do not add a dedicated `Test plan` section by default
- mention meaningful verification inline only when it adds signal, such as tests added, key checks performed, or important gaps
- use a dedicated verification or test-plan section only when the repository explicitly expects that format

## Rules

- never force-push to main or master
- never use `--no-verify`
- never commit secrets
