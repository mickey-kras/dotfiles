# Software Development Skills

This directory contains the managed first-party workflow skills used by the `software-development` capability pack.

## Intent
- keep useful workflow discipline
- keep ownership and review inside this repository
- adapt the skills to local dotfiles policy, agents, and runtime profiles

## Managed Skills
- context7-mcp
- context-budget
- verification-before-completion
- systematic-debugging
- test-driven-development
- obsidian-memory
- requesting-code-review
- receiving-code-review
- using-git-worktrees
- writing-plans
- executing-plans
- dispatching-parallel-agents

## Figma Skill Set (ported + normalized)
Ported from openai/skills .curated and normalized to the charset policy.
Install as a set -- cross-references assume sibling layout.
- figma-implement-design: Figma URL -> production code (React/TS). 7-step workflow: parse URL, get_design_context, get_screenshot, download assets, translate to project conventions, 1:1 parity, validate.
- figma-generate-design: code or description -> full Figma screen, built section-by-section from the design system's components/variables/styles.
- figma-create-design-system-rules: generate project-level CLAUDE.md rules that encode component paths, token locations, and the Figma-to-code flow.
- figma-use: mandatory prerequisite for every use_figma call. Encodes Plugin API rules (color ranges, font loading, page context resets, atomic error recovery).
Requires the Figma MCP server (mcp__figma__* tools).

## Normalization Rules
- ASCII-safe content
- no upstream plugin prefixes
- no connector assumptions
- no Sentry references
- no policy conflicts with runtime profiles
- no AI attribution text
- keep source provenance in repository history or local docs, not in generated output
