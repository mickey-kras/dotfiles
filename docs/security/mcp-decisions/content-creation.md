# Content Creation MCP Decisions

Review basis:
- Anthropic security guidance for hooks, MCP, and hostile content handling
- MCP best practices around least privilege, user consent, and tool poisoning
- official registry and vendor documentation

| Candidate | Decision | Profiles | Risk summary | Main constraints | Sources |
|---|---|---|---|---|---|
| Context7 | approved | focused, studio, campaign | low-risk docs surface | use for reference, not unsupported claims | https://docs.anthropic.com/en/docs/mcp , https://registry.modelcontextprotocol.io/ |
| Filesystem | approved-with-constraints | focused, studio, campaign | local file access | keep workspace narrow and intentional | https://modelcontextprotocol.io/specification/2025-06-18/basic/security_best_practices , https://registry.modelcontextprotocol.io/ |
| Git | approved | focused, studio, campaign | local repo inspection | safe for editorial repos and history | https://docs.anthropic.com/en/docs/mcp , https://registry.modelcontextprotocol.io/ |
| Memory / Obsidian | approved-with-constraints | focused, studio, campaign | local notes and drafts | explicit vault path only when requested | https://docs.anthropic.com/en/docs/claude-code/security , https://registry.modelcontextprotocol.io/ |
| Sequential Thinking | approved | focused, studio, campaign | local reasoning only | no extra constraints | https://docs.anthropic.com/en/docs/mcp , https://registry.modelcontextprotocol.io/ |
| Playwright | approved-with-constraints | studio, campaign | hostile-page exposure | treat captured web content as untrusted input | https://docs.anthropic.com/en/docs/claude-code/security , https://registry.modelcontextprotocol.io/ |
| Figma | approved-with-constraints | studio, campaign | remote design and asset context | restrict use to inspected files and design review | https://docs.anthropic.com/en/docs/mcp , https://registry.modelcontextprotocol.io/ |
| Process | approved | studio, campaign | local inspection only | support local creative tooling, no admin expansion | https://docs.anthropic.com/en/docs/mcp , https://registry.modelcontextprotocol.io/ |
| HTTP Fetch | approved-with-constraints | campaign | open web content and injection risk | campaign only, primary-source bias, no blind reuse | https://docs.anthropic.com/en/docs/claude-code/security , https://modelcontextprotocol.io/specification/2025-06-18/basic/security_best_practices |
| Exa | approved-with-constraints | campaign | secret-backed web search | campaign only, source-quality review required before use in claims | https://docs.anthropic.com/en/docs/claude-code/security , https://registry.modelcontextprotocol.io/ |
| Firecrawl | approved-with-constraints | campaign | broad crawling and extraction | campaign only, explicit scope, no default enablement | https://docs.anthropic.com/en/docs/claude-code/security , https://registry.modelcontextprotocol.io/ |
| fal-ai | approved-with-constraints | campaign | external asset generation | campaign only, track prompt and output provenance | https://docs.anthropic.com/en/docs/claude-code/security , https://registry.modelcontextprotocol.io/ |

Rejected or deferred:
- publishing and social-network integrations: defer until there is a clearer trust model for credentials, publication scope, and rollback.
- analytics and reporting integrations: defer until the pack has a stable measurement workflow worth productizing.
