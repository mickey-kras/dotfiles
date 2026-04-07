# Contributing New MCPs or Plugins

Follow this process before adding any new MCP server, plugin, or external tool to the managed product surface.

## Step 1: Research

1. Find the official vendor documentation or official source repository.
2. Check the official MCP registry at https://registry.modelcontextprotocol.io/ if the server claims registry presence.
3. Review the issue tracker and release history for maintenance health signals.

## Step 2: Security review

Score the candidate on each dimension:

| Dimension | Questions to answer |
| --- | --- |
| Publisher trust | Official vendor, well-known maintainer, or unknown individual? |
| Distribution trust | Official registry, signed releases, npm only, or opaque install? |
| Maintenance health | Active releases? Issue responsiveness? Risk of abandonment? |
| Permission surface | Local execution, filesystem, network, secrets, cloud admin? |
| Data sensitivity | Public docs only, private workspace, customer data, production infra? |
| Prompt-injection exposure | Docs, web search, crawling, user-generated remote content? |
| Blast radius | Read-only, limited mutation, high-impact mutation, broad admin? |
| Sandboxing feasibility | stdio local, remote HTTP, containerizable, hard to constrain? |
| Host fit | Claude, Codex, Cursor? Justified across packs or one pack only? |
| Pack relevance | Essential, useful, optional, or noise? |

## Step 3: Decision

Choose one of:
- `approved` - safe for all relevant profiles
- `approved-with-constraints` - profile-gated, trust-gated, or both (document constraints)
- `defer` - not rejected but not adopted now (document reason)
- `rejected` - does not meet the bar (document reason)

## Step 4: Record

Add a row to `docs/security/mcp-decisions.md` with:
- Candidate name
- Official source link
- Trust and risk summary
- Pack placement and profile gating
- Decision

## Step 5: Implementation

1. Add the MCP to the relevant `pack.yaml` catalogs section.
2. Add it to the appropriate profile selections.
3. Add the install/register logic to the reconcile script.
4. Add the host rendering to all templates (Codex, Cursor, Claude Desktop).
5. Regenerate test fixtures: `python3 tests/generate_fixtures.py`
6. Run `npm test && python3 -m unittest discover tests/ -v`

## Biases

- Prefer fewer, stronger servers over a large catalog.
- Prefer official vendors over community packages unless the community package clearly wins.
- Prefer local auditable assets (agents, rules, docs) over opaque plugins.
- Prefer profile gating for high-risk tools.
- Reject Sentry surfaces.
- Keep connector-backed plugins out of the managed product surface.
