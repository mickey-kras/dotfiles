---
description: Bitwarden CLI setup guide for API-key MCPs
globs: ["**/chezmoi*", "**/.chezmoi*"]
---

# Bitwarden CLI Setup for API-Key MCPs

When `enable_api_mcps` is set to `true` in chezmoi config, the dotfiles use
Bitwarden CLI to fetch API keys at template-render time. If the Bitwarden
vault is locked or the required items don't exist, `chezmoi apply` will fail.

## Install Bitwarden CLI

```bash
# macOS
brew install bitwarden-cli

# Any platform with Node.js
npm install -g @bitwarden/cli
```

## Login and unlock

```bash
bw login            # one-time, authenticates with Bitwarden
export BW_SESSION=$(bw unlock --raw)   # every session, unlocks the vault
```

`BW_SESSION` must be exported in the shell where you run `chezmoi apply`.

## Required Bitwarden items

Create these as **Login** items in your Bitwarden vault. Put the API key in
the **Password** field of each item.

| Bitwarden item name  | API key source    | Where to get it                                      |
|----------------------|-------------------|------------------------------------------------------|
| `exa-api-key`        | Exa API key       | https://exa.ai -- sign up, go to API Keys            |
| `firecrawl-api-key`  | Firecrawl API key | https://firecrawl.dev -- sign up, Dashboard > API Keys |
| `fal-api-key`        | fal.ai API key    | https://fal.ai -- sign up, go to Keys                |

### Creating items

The easiest way is through the Bitwarden web vault or desktop app:

1. Create a new **Login** item.
2. Set the **Name** to exactly the value in the table above (e.g. `exa-api-key`).
3. Paste the API key into the **Password** field.
4. Save.

Alternatively, use the CLI:

```bash
bw get template item | jq \
  '.name = "exa-api-key" | .login.password = "your-api-key-here" | .type = 1' \
  | bw encode | bw create item
```

## Verify

```bash
bw get password exa-api-key        # should print the API key
bw get password firecrawl-api-key
bw get password fal-api-key
```

## Apply

Once the vault is unlocked and items exist:

```bash
chezmoi apply
```

## Troubleshooting

- **`chezmoi apply` fails with "bw: command not found"** -- Install the
  Bitwarden CLI (see above).
- **`chezmoi apply` fails with Bitwarden session/auth errors** -- Run
  `export BW_SESSION=$(bw unlock --raw)` in the same shell, then retry.
- **`chezmoi apply` fails with "item not found"** -- The Bitwarden item
  name must match exactly (e.g. `exa-api-key`). Check with
  `bw list items --search exa-api-key`.
- **Don't want API MCPs at all?** -- Re-run `chezmoi init` and answer `n`
  to the `enable_api_mcps` prompt, then `chezmoi apply`.
