# Plugin Decisions

Decision: reject plugin adoption as part of the managed defaults for this branch.

Why:
- the product requirement is MCP-only
- plugins create a second capability surface that is harder to audit and reason about
- the same value is better expressed here as pack-local agents, rules, hooks, docs, and MCP definitions

Resulting product decisions:
- Codex plugin entries were removed from the managed config
- no new Claude plugins are approved
- connector-backed workflows stay out of scope unless an explicit future product decision reopens them

Review basis:
- https://docs.anthropic.com/en/docs/claude-code/security
- https://modelcontextprotocol.io/specification/2025-06-18/basic/security_best_practices
