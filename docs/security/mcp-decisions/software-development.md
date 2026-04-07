# Software Development MCP Decisions

Review basis:
- Anthropic security guidance for MCP and Claude Code
- MCP security best practices on least privilege, user consent, and tool-poisoning resistance
- official registry presence and vendor docs

| Candidate | Decision | Profiles | Risk summary | Main constraints | Sources |
|---|---|---|---|---|---|
| Context7 | approved | restricted, balanced, open | remote docs, low injection | docs-only use, no secrets | https://docs.anthropic.com/en/docs/mcp , https://registry.modelcontextprotocol.io/ |
| Filesystem | approved-with-constraints | restricted, balanced, open | local read surface | keep rooted to `~/Dev` only | https://modelcontextprotocol.io/specification/2025-06-18/basic/security_best_practices , https://registry.modelcontextprotocol.io/ |
| Git | approved | restricted, balanced, open | repo history and diff | no special constraints beyond local repo scope | https://docs.anthropic.com/en/docs/mcp , https://registry.modelcontextprotocol.io/ |
| Memory / Obsidian | approved-with-constraints | restricted, balanced, open | local data persistence | keep local-first, vault path explicit when used | https://docs.anthropic.com/en/docs/claude-code/security , https://registry.modelcontextprotocol.io/ |
| Sequential Thinking | approved | restricted, balanced, open | local reasoning only | no external side effects | https://docs.anthropic.com/en/docs/mcp , https://registry.modelcontextprotocol.io/ |
| Playwright | approved-with-constraints | restricted, balanced, open | hostile-page exposure | browser automation only, no blanket trust in fetched content | https://docs.anthropic.com/en/docs/claude-code/security , https://registry.modelcontextprotocol.io/ |
| Figma | approved-with-constraints | restricted, balanced, open | remote workspace and design data | use only for inspected files and design-system context | https://docs.anthropic.com/en/docs/mcp , https://registry.modelcontextprotocol.io/ |
| GitHub | approved-with-constraints | restricted, balanced, open | user-generated remote content and PAT-backed mutation | Bitwarden-backed secret only, no plugin fallback | https://docs.anthropic.com/en/docs/claude-code/security , https://registry.modelcontextprotocol.io/ |
| Azure DevOps | approved-with-constraints | restricted, balanced, open | remote work-item and repo mutation | org must be explicit, no implicit tenancy | https://docs.anthropic.com/en/docs/claude-code/security , https://registry.modelcontextprotocol.io/ |
| Shell | approved-with-constraints | balanced, open | direct local execution | never in restricted, keep hard bans, prefer explicit allowlists | https://docs.anthropic.com/en/docs/claude-code/security , https://modelcontextprotocol.io/specification/2025-06-18/basic/security_best_practices |
| Docker | approved-with-constraints | balanced, open | daemon and container mutation | require local Docker availability and trusted machine | https://docs.anthropic.com/en/docs/claude-code/security , https://registry.modelcontextprotocol.io/ |
| Process | approved | balanced, open | local inspection | keep read-oriented usage | https://docs.anthropic.com/en/docs/mcp , https://registry.modelcontextprotocol.io/ |
| Terraform | approved | balanced, open | local IaC inspection | inspection-focused use | https://docs.anthropic.com/en/docs/mcp , https://registry.modelcontextprotocol.io/ |
| Kubernetes | approved-with-constraints | balanced, open | live cluster mutation | current kube context must be explicit and reviewed | https://docs.anthropic.com/en/docs/claude-code/security , https://registry.modelcontextprotocol.io/ |
| HTTP Fetch | approved-with-constraints | open | high prompt-injection exposure | open profile only, prefer primary sources, no silent trust | https://docs.anthropic.com/en/docs/claude-code/security , https://modelcontextprotocol.io/specification/2025-06-18/basic/security_best_practices |
| AWS | approved-with-constraints | open | cloud admin mutation | Bitwarden-backed credentials only, trusted machine only | https://docs.anthropic.com/en/docs/claude-code/security , https://registry.modelcontextprotocol.io/ |
| Tailscale | approved-with-constraints | open | network-admin mutation | trusted machine only, explicit tailnet credential item | https://docs.anthropic.com/en/docs/claude-code/security , https://registry.modelcontextprotocol.io/ |

Rejected for default software-development profiles:
- Exa: defer for content or research only because the search value is real but the prompt-injection and secret-backed search surface is unnecessary for daily development.
- Firecrawl: defer for content or research only because broad crawling is disproportionate for the default development pack.
- fal-ai: reject for software-development because it is not pack-essential.
