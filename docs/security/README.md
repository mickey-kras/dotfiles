# MCP And Plugin Governance

Decision sources used for this branch:
- Anthropic Claude Code settings: https://docs.anthropic.com/en/docs/claude-code/settings
- Anthropic Claude Code hooks: https://docs.anthropic.com/en/docs/claude-code/hooks
- Anthropic Claude Code sub-agents: https://docs.anthropic.com/en/docs/claude-code/sub-agents
- Anthropic MCP overview: https://docs.anthropic.com/en/docs/mcp
- Anthropic Claude Code security: https://docs.anthropic.com/en/docs/claude-code/security
- MCP security best practices: https://modelcontextprotocol.io/specification/2025-06-18/basic/security_best_practices
- Official MCP registry: https://registry.modelcontextprotocol.io/

Review rules:
- prefer official vendors and official registry entries
- prefer least privilege and narrow filesystem roots
- gate high prompt-injection and secret-backed tools by profile
- prefer pack-local docs, agents, and rules over opaque plugins
