# MCP Decisions

This table records the current decision state for the MCP candidates in the
repo. Source links favor the official vendor or official source repository,
with the registry used as a secondary trust signal.

| Candidate | Official source | Trust and risk summary | Pack placement | Decision |
| --- | --- | --- | --- | --- |
| Playwright | https://github.com/microsoft/playwright-mcp | Official Microsoft publisher. Reads hostile web content and executes a local browser process. | software-development `restricted`, `balanced`, `open`; content-creation `studio`, `campaign` | approved-with-constraints |
| Context7 | https://docs.context7.com/ https://mcp.context7.com/mcp | Low-risk remote docs source. Good fit for current-doc retrieval. | software-development all profiles; content-creation all profiles | approved |
| Figma | https://mcp.figma.com/mcp | Official design surface. Remote workspace data and possible mutation. | software-development all profiles; content-creation `studio`, `campaign` | approved-with-constraints |
| Filesystem | https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem | Official MCP server. Local read surface must stay rooted narrowly. | software-development all profiles; content-creation all profiles; research-and-strategy all profiles | approved-with-constraints |
| Git | https://github.com/cyanheads/git-mcp-server | Git-specific local inspection. Lower risk than shell, but still local repo access. | software-development all profiles; content-creation all profiles; research-and-strategy all profiles | approved |
| Memory | https://github.com/modelcontextprotocol/servers/tree/main/src/memory | Official local memory server. Local persistence only. | software-development all profiles; content-creation all profiles | approved |
| Sequential Thinking | https://github.com/modelcontextprotocol/servers/tree/main/src/sequentialthinking | Official reasoning server with low blast radius. | software-development all profiles; content-creation all profiles; research-and-strategy all profiles | approved |
| GitHub | https://github.com/modelcontextprotocol/servers/tree/main/src/github | Official server, but remote user-generated content plus repo mutation and PAT handling. | software-development all profiles | approved-with-constraints |
| Azure DevOps | https://www.npmjs.com/package/@azure-devops/mcp | Official Microsoft package with repo and work-item mutation potential. | software-development all profiles when org is configured | approved-with-constraints |
| Shell | https://www.npmjs.com/package/super-shell-mcp | High-risk local execution surface. Strong blast radius if misused. | software-development `balanced`, `open` only | approved-with-constraints |
| Docker MCP Gateway | https://docs.docker.com/ai/mcp-catalog-and-toolkit/toolkit/ | Docker-managed local gateway with container and daemon reach. | software-development `balanced`, `open` only | approved-with-constraints |
| Process | https://www.npmjs.com/package/@ai-capabilities-suite/mcp-process | Local process inspection. Lower blast radius than shell. | software-development `balanced`, `open`; content-creation `studio`, `campaign` | approved |
| Terraform | https://www.npmjs.com/package/terraform-mcp-server | IaC inspection surface with local execution. | software-development `balanced`, `open` | approved |
| Kubernetes | https://www.npmjs.com/package/mcp-server-kubernetes | Cluster mutation depends on kube context, so blast radius can be large. | software-development `balanced`, `open` | approved-with-constraints |
| HTTP Fetch | https://github.com/modelcontextprotocol/servers/tree/main/src/fetch | Official fetch server, but broad remote prompt-injection exposure. | software-development `open`; content-creation `campaign`; research-and-strategy `investigation` | approved-with-constraints |
| AWS API MCP | https://awslabs.github.io/aws-api-mcp-server/ | Official AWS Labs server. Secret-backed cloud-admin surface. | software-development `open` only | approved-with-constraints |
| Tailscale | https://www.npmjs.com/package/@hexsleeves/tailscale-mcp-server | Community publisher, admin API surface, secret-backed. | software-development `open` only on personal machines | defer |
| Exa | https://www.npmjs.com/package/exa-mcp-server | Secret-backed remote search with prompt-injection and data-quality risk. | software-development `open`; content-creation `campaign`; research-and-strategy `investigation` | approved-with-constraints |
| Firecrawl | https://www.npmjs.com/package/firecrawl-mcp | Secret-backed crawling and extraction with broad remote content risk. | software-development `open`; content-creation `campaign`; research-and-strategy `investigation` | approved-with-constraints |
| fal-ai | https://www.npmjs.com/package/fal-ai-mcp-server | Secret-backed remote generation service. Medium risk, lower system blast radius. | software-development `open`; content-creation `campaign` | approved-with-constraints |

Constraint summary:

- `approved-with-constraints` means profile-gated, trust-gated, or both.
- Secret-backed servers stay opt-in through Bitwarden-backed wrappers.
- High-injection search and crawl surfaces do not belong in low-risk profiles.
- No Sentry MCP or plugin is adopted.
