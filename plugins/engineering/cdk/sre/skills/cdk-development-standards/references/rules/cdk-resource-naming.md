---
description: Collision-safe kebab-case resource naming conventions for CDK
alwaysApply: true
version: 1.0.0
---

# CDK Resource Naming Conventions

## Naming Format

All resources must follow this collision-safe pattern:

```typescript
`resource-name-${props.env.name}-${props.env.region}`
```

Examples:

```typescript
`secret-service-kms-${props.env.name}`
`secret-metadata-inventory-${props.env.name}`
`secret-create-lambda-${props.env.name}`
`secret-create-rule-${props.env.name}`
`secret-create-lambda-role-${props.env.name}`
```

## Kebab-Case Standard

Use kebab-case (lowercase with dashes) for all resource names:

```
project-api-dev              # correct
project-tests-prod           # correct
secret-create-lambda-dev    # correct
```

Do NOT use camelCase (`projectApiDev`), snake_case (`project_api_dev`), or mixed case (`Project-API-Dev`).

## No Redundant Type Suffixes

Do NOT append the resource type to the name. The resource type is already known from the SDK/construct context.

```
project-tests-prod              # correct
project-tests-prod-secret       # incorrect — redundant suffix
project-tests-prod-bucket       # incorrect — redundant suffix
```
