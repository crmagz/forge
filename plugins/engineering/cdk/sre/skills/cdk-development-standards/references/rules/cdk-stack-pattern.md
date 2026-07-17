---
description: Configuration-driven CDK stack implementation patterns and array handling
alwaysApply: true
version: 1.0.0
---

# CDK Stack Pattern

Stacks should be minimal and configuration-driven. All configuration comes from `ProjectEnvironment` in `bin/environments.ts`, never hardcoded in stacks.

## Pattern 1: Direct Package Function Calls (Preferred)

When using shared construct packages that provide construct functions, call them directly from the stack and configure them through `ProjectEnvironment` props.

```typescript
import {Construct} from 'constructs';
import {Stack, Tags} from 'aws-cdk-lib';
import {ProjectEnvironment} from '../src/types/environment-type';
import {createPythonLambda} from '../src/constructs/python-lambda';

export class ProjectStack extends Stack {
    constructor(scope: Construct, id: string, props: ProjectEnvironment) {
        super(scope, id, props);

        Tags.of(this).add('name', 'project-name');
        Tags.of(this).add('environment', props.env.name);

        createPythonLambda(
            this,
            props.privateLambda.functionName,
            props.privateLambda.absPathToEntryFile,
            props.env.name,
            props.env.region,
            props.privateLambda
        );
    }
}
```

Benefits: minimal code duplication, single source of truth in environment config, direct and explicit.

## Pattern 2: Custom Constructs (Only When Necessary)

Create custom constructs in `src/constructs/` only when:

- Complex logic is not provided by existing packages
- Creating reusable infrastructure patterns
- Combining multiple resources with interdependencies

Custom constructs use arrow functions with explicit return types and accept `(scope: Construct, props: ProjectEnvironment)` parameters.

```typescript
export const createOpenSearchClusterInfra = (scope: Construct, props: ProjectEnvironment): Domain => {
    const vpc = getIVpc(scope, props.network.vpcId);
    const securityGroup = createOpenSearchSecurityGroup(scope, vpc, props);
    // ...
    return createOpenSearchDomain(scope, props);
};
```

## Array Handling

When creating multiple similar resources, use `forEach` loops:

```typescript
props.ecrRepositories?.forEach(repo => {
    const ecrRepo = new Repository(this, `${repo.repositoryName}-ecr-repo`, {
        repositoryName: repo.repositoryName,
        imageScanOnPush: repo.imageScanOnPush ?? false,
    });

    Tags.of(ecrRepo).add('Environment', 'build');
    Tags.of(ecrRepo).add('Platform', 'project');
});
```

Key principles:

- Use optional chaining (`?.`) for optional arrays
- Provide sensible defaults with nullish coalescing (`??`)
- Keep loop bodies clean and focused
- Apply consistent patterns (tagging, naming)
