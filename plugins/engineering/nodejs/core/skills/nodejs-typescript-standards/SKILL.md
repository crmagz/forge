---
name: nodejs-typescript-standards
description: Apply shared Node.js and TypeScript standards for native ESM services, including GTS, ESLint, Prettier, typed factory services, and Jest tests. Use before implementing, modifying, or reviewing Node.js service code.
---

# Node.js TypeScript Standards

This is the shared Node.js foundation and requires `engineering-foundation`.
Apply it before any department-specific Node.js profile. The conventions are
based on the Foundry TypeScript service pattern: strict types, typed contracts,
dependency-injected factories, GTS-backed ESLint, Prettier, and co-located Jest
tests.

## References

- `references/rules/nodejs-module-system.md` for native ESM and TypeScript module configuration.
- `references/rules/nodejs-code-style.md` for GTS, ESLint, Prettier, imports, and compiler settings.
- `references/rules/nodejs-service-pattern.md` for interface, factory, and closure-based implementations.
- `references/rules/nodejs-testing.md` for BDD-style Jest tests and mocked dependencies.

Run the repository's formatting, lint, type-check, and test commands before
declaring work complete. A department profile may add domain rules but must not
weaken these rules without an explicit, unexpired repository exception.
