---
name: python-core-standards
description: Apply shared Python language standards before implementing, modifying, or reviewing Python code in any declared department profile.
---

# Python Core Standards

These rules are the portable Python foundation. They intentionally do not
prescribe a web-service, data-science, or infrastructure repository layout.
Read every relevant reference before changing or reviewing Python code.

## References

- `references/rules/python-code-style.md` for naming, imports, docstrings,
  formatting, and Ruff.
- `references/rules/python-dependency-management.md` for `uv`, Python versions,
  dependency pinning, and container builds.
- `references/rules/python-type-checking.md` for strict typing and mypy.
- `references/rules/python-testing.md` for pytest configuration, fixtures,
  async tests, mocking, and coverage.

A department profile may add domain requirements but cannot weaken these rules
without an explicit, unexpired repository exception.
