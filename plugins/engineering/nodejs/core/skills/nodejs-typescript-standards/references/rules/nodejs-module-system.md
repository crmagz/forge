---
description: Native ESM conventions for TypeScript Node.js services
---

# Node.js Native ESM

Node.js services use ESM source and runtime modules. Use `import` and `export`;
never introduce `require`, `module.exports`, or `__dirname`/`__filename`.

## Required Configuration

For a native ESM TypeScript package, use a package-level ESM declaration and
Node-aware TypeScript resolution:

```json
// package.json
{
  "type": "module"
}
```

```json
// tsconfig.json
{
  "compilerOptions": {
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "target": "ES2022",
    "strict": true
  }
}
```

Use `import type` for type-only imports. In TypeScript files that compile to
Node ESM, relative runtime imports use their emitted `.js` extension:

```typescript
import {getWidgetService} from './services/widgetService.js';
import type {WidgetService} from './services/widgetService.js';
```

Do not change an existing repository's module system as an incidental service
change. If it is not yet ESM, record the migration as a separate, reviewed
task. Foundry uses ESM-style TypeScript imports but currently compiles with
CommonJS; this profile makes native ESM an explicit target requirement.
