# Telegram MCP Integration Research

## Status: Deferred

## Findings (April 2026)

### Available MCP Servers

Multiple Telegram MCP server implementations exist in the ecosystem:

1. **sparfenyuk/mcp-telegram** - Read-only access via MTProto. Python/Telethon.
2. **chigwell/telegram-mcp** - Full-featured (read, write, manage groups). Python/Telethon.
3. **dryeab/mcp-telegram** - Send, edit, delete, search, media download. Python/Telethon.
4. **fast-mcp-telegram** (PyPI) - Production-ready with search, messaging, and direct API access.
5. **IQAIcom/mcp-telegram** - Focused on channel interaction.

### Security Assessment

All mature implementations use Telethon (MTProto protocol), which requires:
- User account authentication (phone number + 2FA code)
- Full user-level API access (not bot-level)
- Session files stored locally that grant persistent access

**Risk level: HIGH**

- MTProto session gives full account access (read all chats, send as user, manage groups)
- Session file compromise = full account takeover
- No granular permission scoping (cannot restrict to specific channels)
- Rate limits are user-level, not bot-level

### Recommendation

For our use cases (notifications, channel publishing, monitoring), a Bot API approach
would be more appropriate:
- Bots have scoped permissions (only access channels they are added to)
- Bot tokens are revocable without affecting user accounts
- Bot API is simpler and lower risk than MTProto

However, no production-quality Bot API MCP server was found. Building one is feasible
(grammy or python-telegram-bot + MCP SDK) but out of scope for this iteration.

### Decision

Deferred. When a Bot API-based Telegram MCP server reaches maturity, revisit adoption.
The MTProto-based servers are too permissive for our security model.

### Use Cases by Pack (for future implementation)

- **content-creation (campaign)**: Publish content to Telegram channels, cross-post
- **research-and-strategy (investigation)**: Monitor Telegram channels for signals
- **software-development (full)**: CI/CD notifications, incident alerts
