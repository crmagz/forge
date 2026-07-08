# Terraform Workflows

## Overview

Forge provides a unified reusable workflow for Terraform operations. The Terraform version is managed centrally by Forge — consumer repos do not specify it.

## Workflow: `terraform.yml`

A single workflow handles plan, apply, and destroy through the `action` input. Jobs are conditional based on the action selected.

### Inputs

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `action` | string / choice | yes | `plan`, `apply`, or `destroy` |
| `environment` | string | yes | Target environment name |
| `working-directory` | string | yes | Path to the Terraform root module |

### Managed Versions

These versions are pinned in the workflow and enforced across all consumers:

| Tool | Version | Location |
|------|---------|----------|
| Terraform | `1.15.7` | `env.TERRAFORM_VERSION` |
| Task | `3.52.0` | `env.TASK_VERSION` |
| Trivy | `0.72.0` | `env.TRIVY_VERSION` |

To update a version, change the `env:` block in `terraform.yml` and release a new Forge version.

### Jobs

```
validate ──► plan ──┬──► apply   (if action == apply)
                    └──► destroy (if action == destroy)
```

1. **Validate** — input validation, `terraform fmt -check`, `terraform validate`, Trivy IaC scan
2. **Plan** — `terraform plan` (or `plan -destroy`), job summary, PR comment, artifact upload
3. **Apply** — downloads plan artifact, `terraform apply` (gated by environment approval)
4. **Destroy** — downloads plan artifact, applies destroy plan (gated by environment approval)

### Permissions

| Permission | Scope | Purpose |
|-----------|-------|---------|
| `id-token` | write | OIDC authentication to cloud providers |
| `contents` | read | Checkout repository |
| `pull-requests` | write | Post/update plan comments on PRs |

### Concurrency

Concurrent runs are grouped by `terraform-{environment}-{working-directory}`. In-progress runs are **not** cancelled — they complete to avoid partial applies.

### Usage

```yaml
jobs:
  terraform:
    uses: <org>/forge/.github/workflows/terraform.yml@terraform/v1
    with:
      action: ${{ inputs.action }}
      environment: ${{ inputs.environment }}
      working-directory: ${{ inputs.working-directory }}
    secrets: inherit
```

## Taskfile Reference

The workflow delegates to tasks in `tasks/iac/Taskfile.yml`. These same tasks run locally.

| Task | Description |
|------|-------------|
| `iac:fmt` | Check formatting (`terraform fmt -check -diff -recursive`) |
| `iac:fmt-fix` | Fix formatting (`terraform fmt -recursive`) |
| `iac:init` | Initialize with backend |
| `iac:init-local` | Initialize without backend (for validation) |
| `iac:validate` | Init (no backend) + validate |
| `iac:plan` | Generate plan (`-out=tfplan`) |
| `iac:plan-destroy` | Generate destroy plan (`-destroy -out=tfplan`) |
| `iac:show` | Show plan in human-readable format |
| `iac:trivy` | Run Trivy IaC security scan |
| `iac:test` | Run Terraform tests |
| `iac:apply` | Apply a saved plan |

All tasks accept `TF_DIR` to specify the Terraform root module path:

```bash
task iac:plan TF_DIR=./infra
```

## Version Pinning Requirements (Consumer Repos)

While Forge manages the Terraform CLI version, consumer repos are responsible for pinning their own provider and module versions.

### Provider Versions

Use `.terraform.lock.hcl` to lock provider versions. This file must be committed to the repository.

```hcl
# versions.tf
terraform {
  required_version = "= 1.15.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.82.2"
    }
  }
}
```

### Module Versions

Pin modules to exact versions or commit SHAs:

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.16.0"  # exact version, not range
}
```
