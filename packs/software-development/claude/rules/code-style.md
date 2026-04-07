---
description: Engineering principles for all code
globs: ["**/*"]
---

- Prefer readable, explicit code over clever code.
- Use meaningful names. Avoid abbreviations unless they are standard for the language or domain.
- Keep functions and methods focused. If one unit does multiple unrelated jobs, split it.
- Apply DRY when duplication is real and stable. Do not abstract too early.
- Use design patterns when they simplify ownership, extensibility, or testing. Do not add patterns for ceremony.
- Handle errors explicitly. Do not swallow failures silently.
- Favor small, composable units over large multi-purpose modules.
- Add tests for new behavior and bug fixes. Prefer behavior-focused tests over implementation-coupled tests.
