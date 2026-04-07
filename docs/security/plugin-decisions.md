# Plugin Decisions

Current plugin policy for this repo:

- Preserve an MCP-only managed surface.
- Do not enable connector-backed plugins as part of the default product.
- Keep Sentry excluded.

Current decisions:

| Candidate | Reasoning | Decision |
| --- | --- | --- |
| Codex connector plugins | Connector-backed behavior conflicts with the repo-wide MCP-only policy surface and is harder to audit than local assets plus MCPs. | rejected |
| Claude plugins not managed by dotfiles | The productive local baseline showed that permissions and orchestration quality matter more than plugin count. Unmanaged plugin sprawl weakens governance. | rejected |
| Sentry plugin or MCP | Explicitly excluded by product policy. | rejected |

Preferred alternatives:

- pack-local agents
- pack-local rules
- pack-local playbooks
- security-reviewed MCP servers
