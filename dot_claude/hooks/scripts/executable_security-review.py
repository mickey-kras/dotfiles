#!/usr/bin/env python3
"""
Managed first-party security review hook for Claude Code.

Blocks the first risky write per file and rule within a session so the model
must acknowledge the security concern before proceeding.
"""

import json
import os
import re
import sys
from pathlib import Path


WORKFLOW_UNTRUSTED_FIELDS = (
    "github.event.issue.title",
    "github.event.issue.body",
    "github.event.pull_request.title",
    "github.event.pull_request.body",
    "github.event.comment.body",
    "github.event.review.body",
    "github.event.review_comment.body",
    "github.event.commits.*.message",
    "github.event.head_commit.message",
    "github.head_ref",
)

RULES = (
    {
        "id": "workflow-injection",
        "matches": lambda file_path, content: (
            ".github/workflows/" in file_path
            and file_path.endswith((".yml", ".yaml"))
            and any(field in content for field in WORKFLOW_UNTRUSTED_FIELDS)
        ),
        "message": (
            "Blocked: workflow edit references untrusted GitHub event data. "
            "Do not interpolate issue, PR, comment, or commit text directly "
            "inside run steps. Bind untrusted values through env and quote them."
        ),
    },
    {
        "id": "child-process-exec",
        "matches": lambda _file_path, content: bool(
            re.search(r"\bchild_process\.exec\b|\bexecSync\s*\(", content)
        ),
        "message": (
            "Blocked: child_process.exec or execSync detected. Prefer execFile, "
            "spawn, or equivalent argument-safe APIs to avoid shell injection."
        ),
    },
    {
        "id": "dynamic-code-eval",
        "matches": lambda _file_path, content: bool(
            re.search(r"\beval\s*\(|\bnew Function\b", content)
        ),
        "message": (
            "Blocked: dynamic code evaluation detected. Avoid eval and new Function "
            "unless the requirement explicitly depends on evaluated code."
        ),
    },
    {
        "id": "unsafe-html",
        "matches": lambda _file_path, content: bool(
            re.search(
                r"dangerouslySetInnerHTML|document\.write|\.innerHTML\s*=",
                content,
            )
        ),
        "message": (
            "Blocked: unsafe HTML sink detected. Prefer textContent, safe DOM APIs, "
            "or a sanitizer before rendering untrusted HTML."
        ),
    },
    {
        "id": "python-command-exec",
        "matches": lambda _file_path, content: bool(
            re.search(
                r"\bos\.system\b|\bsubprocess\.(run|Popen|call)\b.*shell\s*=\s*True",
                content,
            )
        ),
        "message": (
            "Blocked: shell-style Python command execution detected. Avoid os.system "
            "and shell=True when arguments could be influenced by user input."
        ),
    },
    {
        "id": "unsafe-pickle",
        "matches": lambda _file_path, content: bool(
            re.search(r"\bpickle\.(load|loads)\s*\(", content)
        ),
        "message": (
            "Blocked: pickle deserialization detected. Do not load pickle data from "
            "untrusted sources. Prefer safer formats such as JSON when possible."
        ),
    },
)


def state_path(session_id: str) -> Path:
    safe_session = re.sub(r"[^A-Za-z0-9_.-]", "_", session_id or "default")
    return Path.home() / ".claude" / "hook-state" / f"security-review-{safe_session}.json"


def load_state(session_id: str) -> set[str]:
    path = state_path(session_id)
    if not path.exists():
        return set()
    try:
        return set(json.loads(path.read_text()))
    except (OSError, json.JSONDecodeError):
        return set()


def save_state(session_id: str, shown: set[str]) -> None:
    path = state_path(session_id)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(sorted(shown)))


def extract_content(tool_name: str, tool_input: dict) -> str:
    if tool_name == "Write":
        return tool_input.get("content", "")
    if tool_name == "Edit":
        return tool_input.get("new_string", "")
    if tool_name == "MultiEdit":
        return " ".join(edit.get("new_string", "") for edit in tool_input.get("edits", []))
    return ""


def main() -> int:
    try:
        payload = json.loads(sys.stdin.read() or "{}")
    except json.JSONDecodeError:
        return 0

    tool_name = payload.get("tool_name", "")
    if tool_name not in {"Write", "Edit", "MultiEdit"}:
        return 0

    tool_input = payload.get("tool_input", {}) or {}
    file_path = tool_input.get("file_path") or tool_input.get("path") or ""
    if not file_path:
        return 0

    content = extract_content(tool_name, tool_input)
    session_id = payload.get("session_id") or os.environ.get("CLAUDE_SESSION_ID") or "default"
    shown = load_state(session_id)
    normalized_path = file_path.replace("\\", "/")

    for rule in RULES:
        if not rule["matches"](normalized_path, content):
            continue

        key = f"{normalized_path}:{rule['id']}"
        if key in shown:
            return 0

        shown.add(key)
        try:
            save_state(session_id, shown)
        except OSError:
            pass

        print(rule["message"], file=sys.stderr)
        return 2

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
