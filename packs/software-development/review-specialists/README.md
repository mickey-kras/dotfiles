# Review Specialists

This directory stages first-party review specialists adapted from the useful parts of `pr-review-toolkit`.

## Intent
- keep review depth that adds real value
- remove plugin dependency from the critical path
- adapt the review specialists to local policy, agents, and runtime profiles
- avoid bloating the live default agent pack until each specialist proves useful

## Current Staged Specialists
- `comment-quality-analyzer.md`
- `test-coverage-analyzer.md`
- `error-path-reviewer.md`

## Not Yet Promoted
- `code-reviewer`
  We already have a strong first-party `code-reviewer`. Only selected ideas should be merged.
- `code-simplifier`
  Potentially useful, but its current "always run after coding" posture conflicts with a pragmatic workflow and needs redesign before adoption.

## Promotion Rule
Promote a staged specialist into the live pack only if it:
- fills a real gap not already covered by the 15-agent SDLC pack
- improves review quality without adding menu fatigue
- does not conflict with no-attribution, MCP-only, or profile rules
