---
description: Testing standards
globs: ["**/*.test.*", "**/*.spec.*", "**/*Tests.*", "**/*Test.*"]
---

- Prefer behavior-first tests over implementation-coupled tests.
- Unit tests should be fast, isolated, and deterministic.
- Integration tests should validate real boundaries and meaningful interactions.
- Use clear names that describe what is being tested, under which conditions, and what is expected.
- Prefer Arrange-Act-Assert or an equally readable structure.
- Aim for meaningful coverage, not vanity metrics.
- For bug fixes, add or update a test that would have caught the regression.
