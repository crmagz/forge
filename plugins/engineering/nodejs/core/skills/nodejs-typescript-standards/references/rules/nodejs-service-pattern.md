---
description: Typed interface, dependency-injected factory, and closure implementation pattern for Node.js services
---

# Node.js Service Pattern

Define a typed service contract, inject dependencies through a factory, and
keep implementation helpers private to the module. This follows Foundry's
service modules, where a factory such as `getRepositoryService` returns a
typed interface backed by private async functions.

## Module Shape

```typescript
import type {Logger} from 'loglevel';

export interface WidgetService {
    createWidget: (input: CreateWidgetInput) => Promise<Widget>;
}

export interface WidgetServiceDependencies {
    readonly client: WidgetClient;
    readonly log: Logger;
}

const createWidget = async (
    {client, log}: WidgetServiceDependencies,
    input: CreateWidgetInput
): Promise<Widget> => {
    log.info(`Creating widget: ${input.name}`);
    const response = await client.create(input);
    return response.widget;
};

export const getWidgetService = (
    dependencies: WidgetServiceDependencies
): WidgetService => {
    return {
        createWidget: input => createWidget(dependencies, input),
    };
};
```

## Rules

- Export the interface and factory; keep helper functions private unless they
  are an intentional reusable API.
- Name factories `get<Name>Service`; do not construct global singleton clients
  inside a service.
- Inject clients, loggers, clocks, configuration, and other side effects so
  tests can replace them.
- Keep domain input and output types in the relevant `types/` module, not as
  anonymous object shapes repeated across services.
- Return typed results and throw contextual errors for failed operations. A
  caller translates domain failures into transport-specific responses.
- Use a class only when mutable instance state or inheritance is necessary;
  factories and closures are the default implementation style.
