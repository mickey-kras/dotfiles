# Superpowers Vendoring Plan

## Goal
- Keep the useful workflow discipline from `superpowers`.
- Stop relying on a third-party plugin as a moving instruction surface for core development behavior.
- Move selected skills under dotfiles control so updates are explicit and reviewable.

## Why
- Third-party plugin updates can change prompting behavior without review.
- Your current SDLC pack already covers the role model. What remains valuable from `superpowers` is the workflow library.
- `superpowers` is MIT licensed, so vendoring selected content is allowed.

## Recommendation
- Keep the currently installed `superpowers` plugin temporarily.
- Vendor only the high-value workflow skills first.
- Once the vendored copies are active and verified, remove the plugin dependency.

## Candidate Skills To Vendor First
- `verification-before-completion`
- `systematic-debugging`
- `test-driven-development`
- `requesting-code-review`
- `receiving-code-review`
- `using-git-worktrees`
- `writing-plans`
- `executing-plans`
- `dispatching-parallel-agents`

## Skills To Treat Carefully
- `using-superpowers`
  Reason: it is specific to the plugin ecosystem and should be replaced with local instructions, not copied verbatim.
- `brainstorming`
  Reason: useful, but large and opinionated. Review before adoption.
- `subagent-driven-development`
  Reason: overlaps with your own agent pack and needs adaptation.
- `finishing-a-development-branch`
  Reason: useful, but must be aligned with your branch, PR, and authorship policies.

## Migration Shape
1. Create a vendored skills area in dotfiles.
2. Copy selected upstream skills into the vendored area.
3. Review and trim each copied skill for:
   - no plugin-specific assumptions
   - no unwanted attribution
   - no unwanted connector assumptions
   - compatibility with your runtime profiles and agent pack
4. Install vendored skills into the managed local skill path.
5. Verify the vendored skills cover the desired workflows.
6. Remove the `superpowers` plugin from live plugin state.

## Acceptance Criteria
- Core workflow help is available without the `superpowers` plugin.
- No vendored skill contradicts the global charset, authorship, MCP-only, or profile rules.
- Updates to the vendored skills happen through dotfiles commits only.

## Notes
- Keep the vendored copies as close to upstream as practical, but adapt where your policies differ.
- Prefer small, explicit deltas over large rewrites.
