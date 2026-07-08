# Forge

Centralized GitHub Actions reusable workflow library for deterministic, version-pinned CI/CD pipelines.

## Overview

Forge provides callable GitHub Actions workflows that enforce consistent standards across repositories. Every workflow follows a **deterministic build** philosophy: all tool versions, provider versions, and module versions are pinned to produce reproducible results regardless of when or where they run.

### Shift-Left Cost Model

Forge is designed around the principle that catching issues earlier is exponentially cheaper:

| Stage | Relative Cost | Enforcement |
|-------|--------------|-------------|
| Local (git hooks) | **1x** | Lefthook runs format, lint, and validate on every commit and push |
| CI (GitHub Actions) | **10x** | Reusable workflows run full plan, test, and security scans |
| Production | **100x** | Issues that reach prod cost orders of magnitude more to resolve |

### Supported Toolchains

- **Terraform** - Format, validate, plan, apply with pinned provider and module versions

## Getting Started

### As a Consumer

Call Forge workflows from your repository:

```yaml
jobs:
  terraform:
    uses: <org>/forge/.github/workflows/terraform-plan.yml@v1
    with:
      working-directory: infra/
```

### As a Contributor

```bash
# Install lefthook for git hooks
brew install lefthook
lefthook install
```

## Documentation

| Document | Description |
|----------|-------------|
| [Architecture](docs/architecture.md) | System design, workflow structure, and design decisions |
| [Terraform Workflows](docs/terraform.md) | Terraform reusable workflow reference |
| [Contributing](docs/contributing.md) | Development workflow, commit standards, and PR process |
| [Versioning](docs/versioning.md) | Release strategy and version pinning philosophy |
| [Context](docs/CONTEXT.md) | AI agent context and repo conventions |

## License

ISC
