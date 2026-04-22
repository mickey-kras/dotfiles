# Phase 8: Testing

## Goal
Expand test coverage to include the research-and-strategy pack.

## Tasks
1. Add research-and-strategy pack tests to pack-resolver.test.mjs
2. Add rendered-output test cases for research-and-strategy profiles
3. Add test fixtures for new pack profiles
4. Regenerate all fixtures
5. Run full test suite

## Verification
- `npm test` passes with new tests
- `python3 -m unittest discover tests/ -v` passes with new tests
- All fixture files exist and match
