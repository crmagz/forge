---
description: GTS, ESLint, Prettier, and strict TypeScript conventions derived from Foundry
---

# Node.js Code Style

Use the repository's configured GTS, ESLint, and Prettier commands. Foundry's
baseline is GTS-backed ESLint plus Prettier and strict TypeScript; preserve that
toolchain instead of hand-formatting or substituting a second linter.

## Formatting

The baseline Prettier settings are:

```javascript
module.exports = {
    ...require('gts/.prettierrc.json'),
    endOfLine: 'auto',
    tabWidth: 4,
    useTabs: false,
    printWidth: 100,
};
```

Use single quotes, semicolons, four-space indentation, and a 100-column print
width. Let Prettier decide wrapping. Use `npm run format:check` to verify and
`npm run format` to repair formatting when those scripts exist.

## Linting and Types

- Extend the GTS ESLint configuration and keep Prettier violations as ESLint
  errors.
- Use explicit named imports; use `import type` when an import is type-only.
- Prefer `const`, strict equality, arrow callbacks, and lowercase camelCase
  values. Types, interfaces, and classes use PascalCase.
- Keep `strict`, `noUnusedLocals`, `noUnusedParameters`, `noImplicitReturns`,
  and `noFallthroughCasesInSwitch` enabled in TypeScript configuration.
- Do not use `any`; use a concrete type, `unknown` with narrowing, or a
  documented, narrowly scoped lint exception when an external API makes it
  unavoidable.

Run `npm run lint`, `npm run build`, and the repository's test command after
the relevant change.
