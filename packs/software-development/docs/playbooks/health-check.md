# Health Check Playbook

Use this to verify the dotfiles installation is working correctly after setup or update.

## Quick verification

```bash
# Check chezmoi status
chezmoi status

# Verify Claude Code MCPs
claude mcp list

# Verify host configs exist
cat ~/.claude/settings.json | head -5
cat ~/.cursor/mcp.json | head -5
cat ~/.codex/config.toml | head -5

# Verify agents are linked
ls -la ~/.claude/agents/

# Verify rules are linked
ls -la ~/.claude/rules/

# Verify skills are linked
ls -la ~/.claude/skills/
```

## Common issues

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Missing MCPs | Bitwarden vault locked or bw not installed | `bw-login && export BW_SESSION=$(cat ~/.bw_session) && chezmoi apply` |
| Empty agents dir | Pack assets not reconciled | `chezmoi apply` |
| Stale config | chezmoi data out of sync | `dotfiles-update` or re-run bootstrap |
| Wrong profile | chezmoi.toml has old values | Re-run `scripts/bootstrap.sh` |

## Full regression check

```bash
cd ~/dotfiles
npm install
npm test
python3 -m unittest discover tests/ -v
```
