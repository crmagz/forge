---
description: TypeScript naming conventions, import rules, and code formatting for CDK
alwaysApply: true
version: 1.0.0
---

# CDK Code Style

## Formatting

All code MUST adhere to ESLint, Prettier, and GTS (Google TypeScript Style). Run these tools before committing.

## TypeScript Naming Conventions

### PascalCase: Types, Interfaces, Enums

```typescript
export type ProjectEnvironment = EnvironmentConfig & { azure: AzureConfig };
export interface InitializerService { getInitializer(name: string): Promise<Initializer> }
export enum AzureApplicationName { DEV_APPLICATION = 'project-api-dev' }
```

Abbreviations in PascalCase — capitalize only the first letter:

```typescript
export interface AwsClient {}     // correct
export enum HttpStatusCode {}     // correct
export interface AWSClient {}     // incorrect
export enum HTTPStatusCode {}     // incorrect
```

### camelCase: Functions, Variables

Use verbAction convention for function names:

```typescript
export const createSecret = (): void => {};
export const updateSecretManager = (): void => {};
export const syncSecretWithAzure = (): void => {};
```

## Import Conventions

NEVER use wildcard imports (`import * as`). Always use explicit, named imports.

```typescript
// incorrect
import * as cdk from 'aws-cdk-lib';

// correct
import {Stack, RemovalPolicy} from 'aws-cdk-lib';
import {Bucket, BucketEncryption} from 'aws-cdk-lib/aws-s3';
```

### Import Order

1. Node.js built-in modules (`path`, `fs`)
2. External dependencies (`@aws-sdk/*`, `@microsoft/*`)
3. AWS CDK constructs (`constructs`, `aws-cdk-lib`)
4. Internal project modules (`../types/*`, `../services/*`)

```typescript
import {readFileSync} from 'fs';

import {SecretsManagerClient} from '@aws-sdk/client-secrets-manager';

import {Construct} from 'constructs';
import {Stack, RemovalPolicy} from 'aws-cdk-lib';
import {Bucket, BucketEncryption} from 'aws-cdk-lib/aws-s3';

import {ProjectEnvironment} from '../../src/types/project';
import {getInitializerService} from '../../src/services/initializer';
```
