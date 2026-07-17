---
description: Interface-first service design pattern with factory functions for CDK
alwaysApply: true
version: 1.0.0
---

# CDK Service Pattern

Follow interface-first design for all services: define the interface, implement the service, export a factory function.

## Structure

1. Define interface with method signatures in `src/interfaces/`
2. Implement service in `src/services/`
3. Export a factory function that returns the service implementation

## Interface

```typescript
// src/interfaces/initializer.ts
import {SecretsManagerClient} from '@aws-sdk/client-secrets-manager';
import {AzureClientCredential} from '../types/azure';
import {Initializer} from '../types/initializer';

export interface InitializerService {
    getInitializer(name: string): Promise<Initializer>;
    getAzureCredentials(smClient: SecretsManagerClient): Promise<AzureClientCredential>;
    getAzureToken(azureClientCredential: AzureClientCredential): Promise<string>;
}
```

## Implementation

```typescript
// src/services/initializer.ts
import {InitializerService} from '../interfaces/initializer';

export const getInitializerService = (): InitializerService => {
    const getInitializer = async (name: string): Promise<Initializer> => {
        // implementation
    };

    const getAzureCredentials = async (smClient: SecretsManagerClient): Promise<AzureClientCredential> => {
        // implementation
    };

    const getAzureToken = async (azureClientCredential: AzureClientCredential): Promise<string> => {
        // implementation
    };

    return {getInitializer, getAzureCredentials, getAzureToken};
};
```

## Usage

```typescript
import {getInitializerService} from '../services/initializer';

const initializerService = getInitializerService();
const initializer = await initializerService.getInitializer('my-lambda');
```

This pattern provides type safety through clear contracts, testability via easy mocking of interfaces, and separation of concerns between definition and implementation.
