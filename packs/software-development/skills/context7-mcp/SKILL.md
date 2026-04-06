---
name: context7-mcp
description: Use when the task depends on current library, framework, or API documentation and code examples from Context7
---

# Context7 MCP

## Use for
- library or framework setup questions
- API reference questions
- code generation that depends on current library behavior
- version-specific guidance for libraries, frameworks, and SDKs

## Do not use for
- questions that do not depend on external library documentation
- speculative answers when no relevant Context7 library match exists

## Primary users
- `backend-engineer`
- `frontend-engineer`
- `staff-engineer`
- `quality-engineer`
- `technical-writer`

## Inputs
- library or framework name
- user question
- version constraint if the user provided one

## Outputs
- selected Context7 library identifier
- answer grounded in current documentation
- relevant code examples or API details when useful

## Overview

Use Context7 when the answer depends on current library behavior or official API documentation. Do not rely on memory for version-sensitive library questions when Context7 can provide current documentation.

**Core principle:** Resolve the right library first, then query the docs with the real user question.

## Method

Follow this sequence:
- resolve the library ID
- choose the best match
- query the documentation with the user question
- answer from the returned docs, not from guesswork

## Library Selection

When choosing a library match, prefer:
- the exact package or framework the user named
- official or primary documentation over forks
- version-specific IDs when the user mentioned a version
- stronger documentation quality and relevance over looser name matches

If the result set is ambiguous and the answer would materially differ, ask for clarification.

## Querying

Pass the full user question as the documentation query whenever practical. Broad keyword-only queries usually return weaker results than the actual task phrasing.

## Response Rules

- answer with the documentation-backed behavior
- include version context when it matters
- provide code examples only when they help answer the request
- say when Context7 did not provide a confident match

## Related Skills

- `systematic-debugging`
- `technical-writer`
