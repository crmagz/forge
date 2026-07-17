---
name: nodejs-add-service
description: Add a typed Node.js service using an exported interface, dependency-injected factory, private implementation helpers, and co-located Jest tests. Use when creating or extending a service in a native ESM TypeScript project.
---

# Add Node.js Service

Before implementation, apply `engineering-nodejs-core:nodejs-typescript-standards`
and inspect the repository's existing service directory, barrel exports, module
configuration, and test conventions.

## Workflow

1. Identify the service responsibility, public methods, input/output types, and
   injected dependencies. Do not start from an untyped dependency object.
2. Add or update domain types in the repository's established `types/` location.
3. Create or update `src/<area>/services/<name>Service.ts` using the interface,
   dependency type, private async helpers, and `get<Name>Service` factory from
   `nodejs-service-pattern.md`.
4. Export the service only through the repository's established public module
   boundary. Use ESM imports and the emitted `.js` extension for relative
   runtime imports when the project is native ESM.
5. Add a co-located `__tests__/<name>Service.test.ts` suite. Mock each injected
   side effect and cover success, validation, and dependency-failure behavior.
6. Wire the factory at the composition root, where real clients and loggers are
   created. Route handlers and commands depend on the interface, not private
   helpers.
7. Run format, lint, build/type-check, and test commands from `package.json`.

## Completion Criteria

- The public interface has typed parameters and returns.
- The service factory accepts dependencies and returns the interface.
- Implementation helpers are private, deterministic given their dependencies,
  and free of transport-layer concerns.
- Tests use mocked dependencies and do not rely on execution order or network
  access.
- The repository's configured checks pass, or the exact failure is reported.
