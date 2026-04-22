# Software Development Skills

This directory contains the managed first-party workflow skills used by the `software-development` capability pack.

## Intent
- keep useful workflow discipline
- keep ownership and review inside this repository
- adapt the skills to local dotfiles policy, agents, and runtime profiles

---

## Full Inventory

39 skills total: 12 managed workflow skills, 4 Figma skills, 24 design/dev
skills. Organized below by category with overlap notes and when-to-use
guidance.

### Workflow Discipline (12 managed, first-party)

These encode process guardrails. They are always active and do not
conflict with each other.

| Skill | When to use |
|-------|-------------|
| context-budget | Delegating work, reading large files, long sessions. Keeps context lean. |
| context7-mcp | Task depends on current library/framework docs. Fetches from Context7. |
| dispatching-parallel-agents | 2+ independent tasks with no shared state. |
| executing-plans | You have a written plan to execute with review checkpoints. |
| obsidian-memory | Memory provider is Obsidian; task needs durable notes or recall. |
| receiving-code-review | Before implementing review feedback, especially if unclear. |
| requesting-code-review | Completing tasks, major features, or pre-merge verification. |
| systematic-debugging | Any bug, test failure, or unexpected behavior -- before proposing fixes. |
| test-driven-development | Implementing any feature or bugfix -- before writing implementation. |
| using-git-worktrees | Feature work needing isolation; before executing plans. |
| verification-before-completion | About to claim work is done -- run verification first. |
| writing-plans | You have a spec or requirements for a multi-step task. |

### Figma Pipeline (4 skills, ported from openai/skills)

Install as a set -- cross-references assume sibling layout.
Requires the Figma MCP server (`mcp__figma__*` tools).

| Skill | Direction | When to use |
|-------|-----------|-------------|
| figma-use | Prerequisite | **MANDATORY** before every `use_figma` call. Encodes Plugin API rules. |
| figma-implement-design | Figma -> Code | User provides a Figma URL or says "implement design." |
| figma-generate-design | Code -> Figma | User says "write to Figma", "create a screen", "push page to Figma." |
| figma-create-design-system-rules | Meta | Generate CLAUDE.md/AGENTS.md rules for Figma-to-code workflows. |

### Design Philosophy (5 skills -- OVERLAP GROUP)

These are **aesthetic directives** that define a visual style. They
overlap heavily and **must not be combined**. Pick ONE per project.

| Skill | Aesthetic | Best for |
|-------|-----------|----------|
| taste | High-agency frontend. Metric-based, strict architecture, CSS perf. | **Wick (recommended)**. General-purpose premium UI. |
| soft | $150k agency-level. Cinematic, haptic depth, Awwwards-tier. | Portfolio sites, landing pages, marketing. |
| impeccable | Anti-AI-slop. Distinctive, production-grade. Context-aware. | When you need project-aware design decisions. Has `craft`/`teach`/`extract` modes. |
| minimalist | Editorial warmth. Monochrome, bento grids, muted pastels. | Content-heavy apps, dashboards, workspace tools. |
| brutalist | Swiss print + military terminal. Rigid grids, CRT effects. | Data-heavy dashboards, portfolios needing raw aesthetic. |

**Overlap notes:**
- `taste` and `soft` are both by Leonxlnx. `taste` is the more
  structured/engineering-focused one; `soft` leans harder into creative
  variance. For Wick, **use taste** -- it has the React/Next.js
  conventions and Tailwind version guards that match the stack.
- `impeccable` is the only one with project context gathering (reads
  your codebase for existing patterns). Use it when starting a new
  project's design context (`/impeccable teach`), then let `taste`
  guide individual component builds.
- `minimalist` and `brutalist` are specialized aesthetics. Only use if
  the project explicitly calls for that look.

### Design Intelligence (2 skills)

Reference databases for design decisions. No real overlap -- different
scopes.

| Skill | Scope | When to use |
|-------|-------|-------------|
| uiux-pro-max | 50+ styles, 161 palettes, 57 font pairings, 99 UX guidelines | **Primary reference.** Broadest coverage. Use for any design decision. |
| uiux-ui-styling | shadcn/ui + Tailwind + canvas | When building React UI components with shadcn. |

### Design Deliverables (5 skills)

Specialized skills for specific design artifacts. `uiux-design` is the
umbrella that also contains built-in logo, CIP, icon, and social photo
generators (with Gemini AI scripts). The others handle one deliverable
type each. Call whichever matches the task directly.

| Skill | When to use |
|-------|-------------|
| uiux-design | Logo generation, corporate identity programs (CIP), icon design, social photos. Has built-in Gemini scripts. Also routes to the 4 skills below for their domains. |
| uiux-brand | Brand voice, visual identity, style guides, messaging frameworks. |
| uiux-banner-design | Social media covers, ad banners, hero sections, print banners. |
| uiux-slides | HTML presentations with Chart.js, copywriting formulas, layouts. |
| uiux-design-system | Token architecture (primitive->semantic->component), CSS vars, specs. |

### Design System Synthesis (3 skills)

For generating DESIGN.md files as sources of truth.

| Skill | Target | When to use |
|-------|--------|-------------|
| design-md | Stitch | Analyze a Stitch project, synthesize DESIGN.md. |
| taste-design | Stitch | Same goal as design-md but with the taste anti-slop rules baked in. |
| enhance-prompt | Stitch | Polish a vague UI idea into a Stitch-optimized prompt. |

**Overlap notes:**
- `design-md` and `taste-design` both generate DESIGN.md for Stitch.
  `taste-design` produces more opinionated output (anti-generic rules).
  **Use taste-design** when you want premium aesthetics enforced;
  use `design-md` for neutral analysis of existing designs.

### Stitch Pipeline (3 skills)

For working with Google Stitch MCP.

| Skill | When to use |
|-------|-------------|
| stitch-design | Unified entry point for Stitch work: prompt enhancement, design system, screen generation. |
| stitch-loop | Autonomous iterative site building using a baton-passing pattern. |
| react-components | Convert Stitch designs into modular Vite/React components. |

### Code Quality (3 skills)

| Skill | When to use |
|-------|-------------|
| output | Task requires exhaustive, unabridged output. Bans `// ...` and truncation. |
| redesign | Upgrading an existing site to premium quality without rewriting. |
| shadcn-ui | Installing, customizing, or building with shadcn/ui components. |

### Specialized (2 skills)

| Skill | When to use |
|-------|-------------|
| emil-design-eng | UI polish, animation philosophy, invisible details. Reference Emil Kowalski's principles. |
| remotion | Generate walkthrough videos from Stitch projects using Remotion. |

## Decision Tree for Wick

When building Wick UI components, use this order:

1. **Design tokens exist in Figma?**
   - Yes -> `figma-implement-design` (Figma -> code)
   - No -> design them first with `figma-use` + `figma-generate-design`

2. **Building a new component?**
   - `taste` for aesthetic rules + `shadcn-ui` for component primitives
   - `uiux-pro-max` for palette/font/style reference
   - `impeccable teach` if design context not yet established

3. **Reviewing existing UI?**
   - `redesign` to audit and upgrade

4. **Need full untruncated output?**
   - `output` alongside any other skill

---

## Normalization Rules
- ASCII-safe content
- no upstream plugin prefixes
- no connector assumptions
- no Sentry references
- no policy conflicts with runtime profiles
- no AI attribution text
- keep source provenance in repository history or local docs, not in generated output
