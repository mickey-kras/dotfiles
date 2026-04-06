# PR Review Toolkit Migration Plan

## Goal
- keep the useful review depth from `pr-review-toolkit`
- avoid depending on the plugin for core review behavior
- merge only the parts that improve the existing first-party system

## Recommendation
- keep `pr-review-toolkit` installed temporarily
- stage the most useful review specialists in dotfiles first
- compare overlapping roles before promoting or removing anything
- remove the plugin once the first-party replacements cover the needed value

## Stage First
- `comment-analyzer` -> `comment-quality-analyzer`
- `pr-test-analyzer` -> `test-coverage-analyzer`
- `silent-failure-hunter` -> `error-path-reviewer`

## Compare Carefully
- `code-reviewer`
  Useful idea to preserve:
  - explicit confidence filtering to reduce noisy findings

  Current issue:
  - overlaps heavily with the first-party `code-reviewer`
  - too tied to generic "check CLAUDE.md compliance" posture

  Recommendation:
  - keep the first-party `code-reviewer`
  - later borrow the confidence-threshold idea if it proves useful

- `code-simplifier`
  Useful ideas to preserve:
  - clarity over cleverness
  - remove redundant abstractions after implementation
  - improve readability without changing behavior

  Current issues:
  - assumes it should run automatically after every coding task
  - overlaps with `staff-engineer`, `backend-engineer`, and `frontend-engineer`
  - would add friction if promoted as a default live agent in its current form

  Recommendation:
  - do not promote directly
  - later consider a first-party `code-simplifier` skill or a lighter specialist only if repeated real need appears

## Promotion Criteria
- fills a real gap in the current agent pack
- improves review quality without duplicating existing agents
- works within no-attribution, MCP-only, and profile rules
- feels native to the first-party workflow rather than imported

## Current Status
- first-party staging area created under `packs/software-development/review-specialists`
- three adapted specialists staged
- the strongest ideas from those specialists were merged into the live `quality-engineer`, `technical-writer`, and `code-reviewer`
- the staged specialists remain out of the default live pack to avoid menu fatigue
- plugin remains installed only for comparison and gradual migration
