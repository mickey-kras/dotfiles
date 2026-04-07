---
description: Bitwarden CLI setup guide for secret-backed MCPs
globs: ["**/chezmoi*", "**/.chezmoi*"]
---

# Bitwarden CLI Setup for Secret-Backed MCPs

The dotfiles can render secret-backed MCP configuration through Bitwarden CLI.
Whether those MCPs are enabled depends on the selected runtime profile and any
custom MCP selections.

If the Bitwarden vault is locked or the required items do not exist, `chezmoi
apply` or MCP registration steps may fail.

## Install Bitwarden CLI

```bash
# macOS
brew install bitwarden-cli

# Any platform with Node.js
npm install -g @bitwarden/cli
```

## Login and unlock

```bash
bw-login
export BW_SESSION="$(cat ~/.bw_session)"
```

`bw-login` stores the unlocked session token in `~/.bw_session` so Claude
Desktop, Claude Code, Codex, and Cursor can all use the same Bitwarden-backed
helpers. Export `BW_SESSION` in the current shell when you want shell-driven
operations like `chezmoi apply` to use the same session immediately.

## Required Bitwarden items

Use **Login** items with the secret stored in the **Password** field unless
noted otherwise.

Core items used by the current MCP catalog:

| Bitwarden item name | Purpose | Notes |
|---------------------|---------|-------|
| `mcp-github` | GitHub token | Password = PAT |
| `mcp-aws` | AWS API access | Custom fields: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` |
| `mcp-tailscale` | Tailscale API access | Password = API key, custom field `TAILSCALE_TAILNET` |
| `exa-api-key` | Exa API key | Password = API key |
| `firecrawl-api-key` | Firecrawl API key | Password = API key |
| `fal-api-key` | fal.ai API key | Password = API key |

Only create the items required by the MCPs you actually enable.

Item names must be unique if you reference them by name. If you keep multiple
items with the same name, either rename them or switch the MCP wrapper to use a
specific Bitwarden item id.

## Verify

```bash
bw get password mcp-github
bw get item mcp-aws
bw get password exa-api-key
```

## Apply

```bash
chezmoi apply
```

## Troubleshooting

- **`bw: command not found`**: install Bitwarden CLI first.
- **unlock or auth errors**: run `bw-login` again, then export `BW_SESSION` from `~/.bw_session` in the same shell if needed.
- **item not found**: the Bitwarden item name must match the expected name exactly.
- **do not want secret-backed MCPs on this machine**: choose a runtime profile that omits them, or disable them in custom mode and re-run setup.
