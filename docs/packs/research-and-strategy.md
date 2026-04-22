# Research And Strategy Pack Candidate

Status: implemented

## Primary job

- deep investigation and evidence gathering
- source comparison and synthesis
- strategic recommendation with uncertainty reporting
- executive-style reporting and decision support

## Why this pack is distinct

- software-development centers on code delivery and operational execution
- content-creation centers on editorial production and publishing
- research-and-strategy centers on evidence quality, synthesis rigor, and recommendation clarity

## Candidate profiles

### `desk`

Low-risk reading and local synthesis.

MCPs: filesystem, git, memory, thinking, context7
Permissions: core_read_write, shell_readonly, git_safe
Use when: structured reading, local note-taking, evidence grading from existing materials

### `analyst`

Broader repo, standards, and documentation research.

MCPs: filesystem, git, memory, thinking, context7, playwright, process
Permissions: core_read_write, shell_readonly, git_safe, local_file_mutation
Use when: cross-repo investigation, standards comparison, structured report generation

### `investigation`

Wider crawling and search with stronger security constraints.

MCPs: filesystem, git, memory, thinking, context7, playwright, process, http, exa, firecrawl
Permissions: core_read_write, shell_readonly, git_safe, local_file_mutation, web_access, secret_tools
Use when: market research, competitive analysis, broad evidence gathering from remote sources
Security: high injection risk from web content, requires trusted personal machines only

## Candidate agents

### trend-researcher
- Scan sources for emerging patterns, market signals, and competitive moves.
- Produce a structured trend brief with confidence levels and source quality notes.
- Tools: Read, Glob, Grep, WebSearch, WebFetch

### competitive-analyst
- Compare products, services, or approaches across defined dimensions.
- Produce comparison matrices with evidence links and gap analysis.
- Tools: Read, Glob, Grep, WebSearch, WebFetch

### evidence-reviewer
- Grade source quality, flag contradictions, and identify evidence gaps.
- Produce an evidence map separating strong claims from weak or unsupported ones.
- Tools: Read, Glob, Grep

### report-writer
- Turn research briefs into structured reports with executive summary, findings, and recommendations.
- Maintain citation discipline and uncertainty reporting throughout.
- Tools: Read, Glob, Grep, Edit, Write

### executive-summary-writer
- Compress a full research output into a decision-ready summary.
- Highlight key decisions, risks, and recommended actions.
- Tools: Read, Glob, Grep, Write

## Candidate rules

### evidence-over-claims
- Require evidence links for factual assertions.
- Flag unsupported claims explicitly rather than silently including them.
- Distinguish first-party data from third-party commentary.

### uncertainty-reporting
- Report confidence levels for key conclusions.
- Separate verified facts from reasonable inference from speculation.
- Call out what is unknown and what cannot be verified with available sources.

### citation-discipline
- Same as content-creation: prefer primary sources, flag stale or conflicting evidence.

### report-structure
- Executive summary first, then findings, then detailed analysis.
- Recommendations section must reference specific findings.
- Appendix for raw source lists and methodology notes.

## Candidate skills

- context-budget
- obsidian-memory
- writing-plans
- verification-before-completion

## Candidate docs and playbooks

- Research intake checklist: define question, scope, source types, and output format
- Evidence matrix template: structured grid for source quality grading
- Executive summary playbook: compress findings into decision-ready format
- Source quality rubric: criteria for rating primary, secondary, and tertiary sources

## Settings schema

- memory_provider: builtin or obsidian
- obsidian_vault_path: conditional on obsidian selection
- research_workspace: path for local research output

## Guardrails

Same shared hard bans as software-development.
No profile-specific bans beyond the shared set.

## MCP security notes

- http, exa, firecrawl carry high prompt-injection risk from web content
- these are gated to `investigation` profile only
- same Bitwarden-backed credential handling as other packs
- no new MCP candidates beyond the existing approved set

## Implementation decision

Implemented. The pack was promoted from design-complete to full implementation because:
1. All MCPs are drawn from the existing approved catalog with no new additions
2. The research agents and rules provide distinct value beyond content-creation
3. Evidence-focused workflows (grading, synthesis, uncertainty reporting) do not overlap with editorial workflows
