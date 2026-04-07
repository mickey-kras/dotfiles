# Research Baseline

This repo now treats external host and MCP documentation as a hard input to
pack design and tool adoption.

Primary references used for the current migration:

- Claude Code settings:
  https://docs.anthropic.com/en/docs/claude-code/settings
- Claude Code hooks:
  https://docs.anthropic.com/en/docs/claude-code/hooks
- Claude Code sub-agents:
  https://docs.anthropic.com/en/docs/claude-code/sub-agents
- Claude Code security:
  https://docs.anthropic.com/en/docs/claude-code/security
- MCP overview:
  https://docs.anthropic.com/en/docs/mcp
- MCP security best practices:
  https://modelcontextprotocol.io/specification/2025-06-18/basic/security_best_practices
- MCP registry:
  https://registry.modelcontextprotocol.io/

Current design conclusions from those sources:

- Settings should stay explicit and layered. Local overrides exist, but the
  managed defaults should stay small and auditable.
- Hooks are useful when they are deterministic, low-noise, and tied to clear
  quality or safety gates. They should not become a hidden automation swamp.
- Sub-agents work best as narrow, role-specific specialists. Packs should keep
  the count curated and avoid giant agent catalogs.
- MCP servers must be treated as code execution or remote-trust expansions,
  not as harmless configuration.
- Remote search, crawling, and user-generated content increase prompt-injection
  risk and need stronger profile gating.
- Secret-backed and admin-capable MCPs need explicit trust assumptions and
  should be opt-in or profile-gated.
- The MCP registry is a discovery input, not an approval by itself.

Pack-level implications:

- `software-development` keeps the broadest curated tool surface but still
  gates shell, cloud, and web-heavy MCPs by profile.
- `content-creation` defaults to lower-risk editorial and design workflows,
  with campaign research and generation tools gated to the highest-trust
  profile.
- `research-and-strategy` stays design-complete only until its crawl and search
  surface is reviewed with the same bar.
