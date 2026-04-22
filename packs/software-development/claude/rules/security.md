---
description: Security rules for all projects
globs: ["**/*"]
---

- Never commit secrets, API keys, tokens, or passwords.
- Never print secrets in logs, debug output, commits, PRs, or tickets.
- Never use `sudo`, `su`, or modify system files unless explicitly asked and approved.
- Never force-push to main or master. Never use `--no-verify`.
- Validate and sanitize untrusted input for injection, traversal, and XSS risks.
- Use parameterized queries. Never concatenate user input into SQL.
- Prefer maintained dependencies with active support and no known serious vulnerabilities.
- Treat workflow files, shell execution, HTML sinks, deserialization, and dynamic code evaluation as high-risk areas.
