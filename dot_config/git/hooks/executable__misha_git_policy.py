#!/usr/bin/env python3
"""Global Git policy checks for charset and AI attribution."""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

ALLOWED_REGEX = r"^[A-Za-zА-Яа-яЁё0-9 !\"#$%&'()*+,\-./:;<=>?@[\\\]^_`{|}~\r\n\t]*$"

BANNED_PATTERNS = [
    re.compile(r"(?im)^\s*(co-authored-by|generated-by)\s*:"),
    re.compile(r"(?im)^\s*(made-with|created-with|written-with|built-with)\s*:"),
    re.compile(
        r"(?i)claude\s+opus\s+4\.6(?:\s*\(1m\s+context\))?\s*<noreply@anthropic\.com>"
    ),
    re.compile(
        r"(?i)\b(created|generated|written|made|built)\s+with\s+"
        r"(claude(?:\s+code)?|cursor|codex|openai|anthropic|ai)\b"
    ),
    re.compile(
        r"(?i)\b(co-authored|coauthored)\s+by\s+"
        r"(claude|cursor|codex|openai|anthropic|ai)\b"
    ),
]

TEXT_EXTENSIONS = {
    ".cs",
    ".cshtml",
    ".config",
    ".css",
    ".fs",
    ".fsi",
    ".fsx",
    ".graphql",
    ".htm",
    ".html",
    ".java",
    ".js",
    ".json",
    ".jsx",
    ".kt",
    ".kts",
    ".less",
    ".md",
    ".mdx",
    ".mjs",
    ".ps1",
    ".py",
    ".rb",
    ".scss",
    ".sh",
    ".sql",
    ".svg",
    ".toml",
    ".ts",
    ".tsx",
    ".txt",
    ".xml",
    ".yaml",
    ".yml",
}


def is_allowed_char(ch: str) -> bool:
    if ch in "\r\n\t":
        return True
    if " " <= ch <= "~":
        return True
    code = ord(ch)
    return code == 0x401 or code == 0x451 or 0x410 <= code <= 0x44F


def find_invalid_char(text: str) -> tuple[int, int, str] | None:
    line = 1
    col = 1
    for ch in text:
        if not is_allowed_char(ch):
            return line, col, ch
        if ch == "\n":
            line += 1
            col = 1
        else:
            col += 1
    return None


def describe_char(ch: str) -> str:
    code = ord(ch)
    if ch == "\n":
        return "newline"
    if ch == "\r":
        return "carriage return"
    if ch == "\t":
        return "tab"
    if ch == " ":
        return "space"
    return f"{ch!r} U+{code:04X}"


def find_banned_pattern(text: str) -> str | None:
    for pattern in BANNED_PATTERNS:
        match = pattern.search(text)
        if match:
            return match.group(0).strip()
    return None


def decode_text(data: bytes, origin: str) -> str | None:
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError:
        if b"\0" in data:
            return None
        sys.stderr.write(f"policy: {origin}: not valid UTF-8 text\n")
        return "__INVALID_UTF8__"


def run_git(args: list[str], cwd: str) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(
        ["git", *args],
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )


def check_text(text: str, label: str) -> list[str]:
    errors: list[str] = []
    invalid = find_invalid_char(text)
    if invalid:
        line, col, ch = invalid
        errors.append(
            f"{label}: invalid character at line {line}, column {col}: {describe_char(ch)}"
        )
    banned = find_banned_pattern(text)
    if banned:
        errors.append(f"{label}: banned attribution text matched: {banned}")
    return errors


def is_text_path(path: str) -> bool:
    name = os.path.basename(path)
    if "." not in name:
        return name in {"COMMIT_EDITMSG", "MERGE_MSG", "TAG_EDITMSG"}
    return Path(path).suffix.lower() in TEXT_EXTENSIONS


def cmd_check_commit_msg(path: str) -> int:
    try:
        text = Path(path).read_text(encoding="utf-8")
    except UnicodeDecodeError:
        sys.stderr.write(f"policy: {path}: not valid UTF-8 text\n")
        return 1

    errors = check_text(text, path)
    if errors:
        sys.stderr.write("Commit message policy check failed:\n")
        for err in errors:
            sys.stderr.write(f"  - {err}\n")
        sys.stderr.write(f"Allowed regex: {ALLOWED_REGEX}\n")
        return 1
    return 0


def iter_staged_paths(repo_root: str) -> list[str]:
    result = run_git(["diff", "--cached", "--name-only", "--diff-filter=ACMR", "-z"], repo_root)
    if result.returncode != 0:
        sys.stderr.write(result.stderr.decode("utf-8", errors="replace"))
        return []
    data = result.stdout.decode("utf-8", errors="replace")
    return [p for p in data.split("\0") if p]


def check_blob(repo_root: str, object_expr: str, label: str) -> list[str]:
    blob = run_git(["show", object_expr], repo_root)
    if blob.returncode != 0:
        return [f"{label}: unable to read blob {object_expr}"]
    text = decode_text(blob.stdout, label)
    if text is None:
        return []
    if text == "__INVALID_UTF8__":
        return [f"{label}: not valid UTF-8 text"]
    return check_text(text, label)


def cmd_check_staged(repo_root: str) -> int:
    errors: list[str] = []
    for path in iter_staged_paths(repo_root):
        if not is_text_path(path):
            continue
        errors.extend(check_blob(repo_root, f":{path}", path))
    if errors:
        sys.stderr.write("Pre-commit policy check failed:\n")
        for err in errors:
            sys.stderr.write(f"  - {err}\n")
        sys.stderr.write(f"Allowed regex: {ALLOWED_REGEX}\n")
        return 1
    return 0


def rev_list(repo_root: str, revspec: str) -> list[str]:
    result = run_git(["rev-list", revspec], repo_root)
    if result.returncode != 0:
        sys.stderr.write(result.stderr.decode("utf-8", errors="replace"))
        return []
    return [line for line in result.stdout.decode("utf-8").splitlines() if line]


def changed_paths(repo_root: str, commit: str) -> list[str]:
    result = run_git(
        ["diff-tree", "--root", "--no-commit-id", "--name-only", "-r", "--diff-filter=ACMR", commit],
        repo_root,
    )
    if result.returncode != 0:
        sys.stderr.write(result.stderr.decode("utf-8", errors="replace"))
        return []
    return [line for line in result.stdout.decode("utf-8").splitlines() if line]


def commit_message(repo_root: str, commit: str) -> str | None:
    result = run_git(["show", "-s", "--format=%B", commit], repo_root)
    if result.returncode != 0:
        sys.stderr.write(result.stderr.decode("utf-8", errors="replace"))
        return None
    return result.stdout.decode("utf-8", errors="replace")


def cmd_check_range(repo_root: str, revspec: str) -> int:
    errors: list[str] = []
    for commit in rev_list(repo_root, revspec):
        message = commit_message(repo_root, commit)
        if message is None:
            errors.append(f"{commit}: unable to read commit message")
            continue
        errors.extend(check_text(message, f"{commit} commit message"))
        for path in changed_paths(repo_root, commit):
            if not is_text_path(path):
                continue
            errors.extend(check_blob(repo_root, f"{commit}:{path}", f"{commit}:{path}"))
    if errors:
        sys.stderr.write(f"Pre-push policy check failed for range {revspec}:\n")
        for err in errors:
            sys.stderr.write(f"  - {err}\n")
        sys.stderr.write(f"Allowed regex: {ALLOWED_REGEX}\n")
        return 1
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    commit_msg = subparsers.add_parser("check-commit-msg")
    commit_msg.add_argument("path")

    staged = subparsers.add_parser("check-staged")
    staged.add_argument("--repo-root", default=os.getcwd())

    range_parser = subparsers.add_parser("check-range")
    range_parser.add_argument("revspec")
    range_parser.add_argument("--repo-root", default=os.getcwd())

    return parser


def main() -> int:
    args = build_parser().parse_args()
    if args.command == "check-commit-msg":
        return cmd_check_commit_msg(args.path)
    if args.command == "check-staged":
        return cmd_check_staged(args.repo_root)
    if args.command == "check-range":
        return cmd_check_range(args.repo_root, args.revspec)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
