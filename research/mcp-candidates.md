# MCP Candidates for Research-and-Strategy Pack

## Existing approved MCPs to reuse

The research-and-strategy pack reuses MCPs already approved in `docs/security/mcp-decisions.md`.
No new MCP candidates are proposed.

| MCP | Risk | Profile placement | Notes |
|-----|------|-------------------|-------|
| context7 | low | all profiles | Current library docs |
| filesystem | low | all profiles | Rooted narrowly to research workspace |
| git | low | all profiles | Repo inspection |
| memory | low | all profiles | Local persistence |
| thinking | low | all profiles | Structured reasoning |
| playwright | medium | analyst, investigation | Browser for structured research |
| process | low | analyst, investigation | Local process support |
| http | high | investigation only | Remote fetch, injection risk |
| exa | high | investigation only | Secret-backed search |
| firecrawl | high | investigation only | Secret-backed crawl |

## Candidates NOT adopted

| Candidate | Reason |
|-----------|--------|
| Slack MCP | Not needed for research workflows; connector-backed in Claude |
| Notion MCP | Not in current approved set; would need full security review |
| Brave Search MCP | Exa already covers search; adding another search surface increases risk |
| Any new external MCP | No concrete need beyond existing approved set |

## Security decision

The research-and-strategy pack does not introduce any new MCP servers.
All MCPs are drawn from the existing approved catalog with the same
profile gating and constraint policies.
