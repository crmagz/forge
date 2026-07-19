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

### Architecture: Workflows Orchestrate Taskfiles

Forge separates **what to run** from **how to orchestrate it**:

```
Developer workstation          GitHub Actions
┌────────────────────┐        ┌────────────────────────────┐
│  $ task iac:fmt    │        │  .github/workflows/        │
│  $ task iac:plan   │──────► │    terraform.yml            │
│  $ task iac:apply  │  same  │      ├─ task iac:validate  │
│                    │  tasks  │      ├─ task iac:plan      │
│  Taskfile.yml      │        │      └─ task iac:apply     │
└────────────────────┘        └────────────────────────────┘
```

- **Taskfiles** (`tasks/`) contain the implementation — the actual tool commands
- **Workflows** (`.github/workflows/`) orchestrate taskfiles with CI concerns: permissions, concurrency, environment gates, job summaries, and PR comments
- **Developers run the same tasks locally** that CI runs remotely — identical commands, identical behavior

### Supported Toolchains

- **Terraform** — Format, validate, Trivy security scan, plan, apply, destroy with pinned provider and module versions
- **Helm 3** — Strict linting for repository-owned charts, including umbrella charts without independently linting vendored dependencies

## Getting Started

### As a Consumer

Call Forge workflows from your repository:

```yaml
jobs:
  terraform:
    uses: <org>/forge/.github/workflows/terraform.yml@terraform/v1
    with:
      action: ${{ inputs.action }}
      environment: ${{ inputs.environment }}
      working-directory: ${{ inputs.working-directory }}
```

Terraform and Task versions are managed centrally by Forge — consumers don't specify them.

### As a Contributor

```bash
# Install prerequisites
brew install helm lefthook go-task terraform

# Install git hooks
lefthook install

# Run tasks locally
task iac:fmt TF_DIR=./infra
task iac:validate TF_DIR=./infra
task iac:plan TF_DIR=./infra
```

### Helm chart hooks

The Helm module checks chart roots below `charts/` on each commit. A chart root
is a directory containing `Chart.yaml` that is not inside another chart's
`charts/` directory. This supports umbrella charts: their dependency charts
remain available to Helm, but are not selected as independent lint targets.

- `helm lint --strict` fails on Helm warnings and errors.
- YAML comments in repository-owned chart files must use `# ` (or a bare `#`).
  Helm parses template comments such as `{{/* comment */}}` during linting.

Consumer repositories can opt in by extending `lefthook/helm.yml` and should
place their chart roots below `charts/`.

## Task Reference

| Task | Description |
|------|-------------|
| `task iac:fmt` | Check Terraform formatting |
| `task iac:fmt-fix` | Fix Terraform formatting |
| `task iac:validate` | Init (no backend) + validate |
| `task iac:init` | Initialize with backend |
| `task iac:plan` | Generate plan |
| `task iac:plan-destroy` | Generate destroy plan |
| `task iac:apply` | Apply a saved plan |
| `task iac:trivy` | Run Trivy IaC security scan |
| `task iac:test` | Run Terraform tests |
| `task iac:show` | Show plan in human-readable format |

All tasks accept `TF_DIR` to specify the Terraform root module path.

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
