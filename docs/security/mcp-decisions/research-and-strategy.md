# Research and Strategy MCP Decisions

All MCPs in this pack are drawn from the existing approved catalog.
No new MCP servers are introduced.

## Profile placement

### desk (low risk)

| MCP | Decision | Notes |
| --- | --- | --- |
| context7 | approved | Low-risk remote docs |
| filesystem | approved-with-constraints | Rooted narrowly |
| git | approved | Local repo inspection |
| memory | approved | Local persistence |
| thinking | approved | Local reasoning |

### analyst (low-medium risk)

Adds to desk:

| MCP | Decision | Notes |
| --- | --- | --- |
| playwright | approved-with-constraints | Browser for structured research; reads hostile web content |
| process | approved | Local process inspection |

### investigation (medium-high risk)

Adds to analyst:

| MCP | Decision | Notes |
| --- | --- | --- |
| http | approved-with-constraints | Broad remote fetch; high injection risk; trusted machines only |
| exa | approved-with-constraints | Secret-backed search; high injection risk; trusted machines only |
| firecrawl | approved-with-constraints | Secret-backed crawl; high injection risk; trusted machines only |

## Security notes

- http, exa, and firecrawl carry high prompt-injection risk from web content
- these are gated to `investigation` profile only
- Bitwarden-backed credentials for exa and firecrawl
- no new MCP candidates beyond the existing approved set
- same constraint policies as software-development and content-creation
