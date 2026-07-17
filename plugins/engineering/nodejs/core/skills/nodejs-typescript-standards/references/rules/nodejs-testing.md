---
description: Co-located Jest BDD tests for dependency-injected Node.js services
---

# Node.js Service Testing

Co-locate Jest tests in `__tests__/` next to the module under test. Follow
Foundry's BDD structure: nested `describe` blocks, specific `it` descriptions,
and Given/When/Then comments around nontrivial setup and assertions.

```typescript
import {getWidgetService} from '../widgetService.js';

describe('WidgetService', () => {
    describe('createWidget', () => {
        it('should create a widget with valid input', async () => {
            // Given: a mocked dependency and valid input
            const client = {create: jest.fn().mockResolvedValue({widget: {id: 'widget-1'}})};
            const log = {info: jest.fn()} as never;
            const service = getWidgetService({client, log});

            // When: the service creates the widget
            const result = await service.createWidget({name: 'example'});

            // Then: it returns the dependency result
            expect(result).toEqual({id: 'widget-1'});
            expect(client.create).toHaveBeenCalledWith({name: 'example'});
        });
    });
});
```

- Mock external clients and injected dependencies; do not make network calls in
  unit tests.
- Cover success, invalid input, dependency failure, and any branch that changes
  output or observable side effects.
- Reset or recreate mocks in `beforeEach` so tests remain independent.
- Do not commit focused tests such as `describe.only` or `it.only`.
- Run `npm test` and coverage when the repository supplies those scripts.
