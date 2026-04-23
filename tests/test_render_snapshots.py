import shutil
import unittest

from helpers import render_template


FULL_STATE = {
    "capability_pack": "software-development",
    "profile_selected": "full",
    "profile_mode": "preset",
    "selection_enabled_mcps": [
        "playwright",
        "context7",
        "figma",
        "stitch",
        "filesystem",
        "git",
        "memory",
        "obsidian",
        "thinking",
        "github",
        "shell",
        "docker",
        "process",
        "terraform",
        "kubernetes",
        "http",
        "firebase",
        "aws",
        "tailscale",
        "magic",
        "replicate",
    ],
    "selection_enabled_skills": [
        "context7-mcp",
        "context-budget",
        "dispatching-parallel-agents",
        "executing-plans",
        "obsidian-memory",
        "receiving-code-review",
        "requesting-code-review",
        "systematic-debugging",
        "test-driven-development",
        "using-git-worktrees",
        "verification-before-completion",
        "writing-plans",
    ],
    "selection_enabled_agents": [
        "delivery-orchestrator",
        "planner",
        "product-manager",
        "workflow-architect",
        "backend-engineer",
        "frontend-engineer",
        "staff-engineer",
        "quality-engineer",
        "code-reviewer",
        "debugger",
        "git-workflow-master",
        "devops-engineer",
        "security-engineer",
        "technical-writer",
        "incident-commander",
    ],
    "selection_enabled_rules": [
        "bitwarden-setup",
        "code-style",
        "development-workflow",
        "git-workflow",
        "performance",
        "security",
        "testing",
    ],
    "selection_enabled_permissions": [
        "core_read_write",
        "shell_readonly",
        "git_full",
        "gh_full",
        "dev_runtime",
        "local_file_mutation",
        "containers",
        "infra_local",
        "package_runtime",
        "cloud_extended",
        "secret_tools",
        "web_access",
    ],
    "memory_provider": "obsidian",
    "obsidian_vault_path": "/Users/mikhailkrasilnikov/Notes",
    "install_claude_code": "disabled",
    "install_codex": "disabled",
    "install_cursor": "disabled",
    "install_gemini_cli": "disabled",
    "install_droid": "disabled",
    "stitch_api_key": "test-stitch-key",
    "bw_gate_install": "enabled",
}


class RenderSmokeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not shutil.which("chezmoi"):
            raise unittest.SkipTest("chezmoi not installed")

    def test_claude_template_renders_expected_sections(self):
        rendered = render_template("dot_claude/settings.json.tmpl", FULL_STATE)
        self.assertIn('"permissions"', rendered)
        self.assertNotIn("DOTFILES_RUNTIME_PROFILE", rendered)
        self.assertIn("governance-capture.js", rendered)

    def test_codex_template_renders_expected_servers(self):
        rendered = render_template("dot_codex/config.toml.tmpl", FULL_STATE)
        self.assertIn("[mcp_servers.stitch]", rendered)
        self.assertIn("[mcp_servers.obsidian]", rendered)
        self.assertIn('@bitbonsai/mcpvault@latest', rendered)

    def test_cursor_template_renders_expected_servers(self):
        rendered = render_template("dot_cursor/mcp.json.tmpl", FULL_STATE)
        self.assertIn('"MCP_DOCKER"', rendered)
        self.assertIn('"stitch"', rendered)
        self.assertIn('"obsidian"', rendered)

    def test_claude_mcp_script_renders_expected_servers(self):
        rendered = render_template(
            "scripts/chezmoi/run_onchange_after_install-claude-mcps.sh.tmpl",
            FULL_STATE,
        )
        self.assertIn('add_mcp stitch', rendered)
        self.assertIn('add_mcp obsidian', rendered)
        self.assertIn('add_mcp MCP_DOCKER', rendered)


if __name__ == "__main__":
    unittest.main()
