# Terraform Workflows

## Overview

Forge provides reusable workflows for Terraform operations. All workflows enforce deterministic builds by requiring explicit version pinning for Terraform, providers, and modules.

## Workflows

### `terraform-plan.yml`

Runs `terraform plan` and posts the plan output as a PR comment.

**Inputs**:

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `working-directory` | string | yes | Path to the Terraform root module |
| `terraform-version` | string | yes | Exact Terraform version (e.g., `1.9.8`) |
| `environment` | string | yes | Target environment name |

**Usage**:

```yaml
jobs:
  plan:
    uses: <org>/forge/.github/workflows/terraform-plan.yml@v1
    with:
      working-directory: infra/
      terraform-version: "1.9.8"
      environment: dev
    secrets: inherit
```

### `terraform-apply.yml`

Runs `terraform apply` with an approved plan. Requires environment protection rules.

**Inputs**:

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `working-directory` | string | yes | Path to the Terraform root module |
| `terraform-version` | string | yes | Exact Terraform version (e.g., `1.9.8`) |
| `environment` | string | yes | Target environment name |

### `terraform-validate.yml`

Runs `terraform fmt -check`, `terraform validate`, and linting. Used in both local hooks and CI.

**Inputs**:

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `working-directory` | string | yes | Path to the Terraform root module |
| `terraform-version` | string | yes | Exact Terraform version (e.g., `1.9.8`) |

## Version Pinning Requirements

### Terraform Version

Always specify an exact version — never `latest` or a version range.

```yaml
terraform-version: "1.9.8"  # correct
terraform-version: "latest"  # incorrect — non-deterministic
terraform-version: "~> 1.9"  # incorrect — range allows drift
```

### Provider Versions

Use `.terraform.lock.hcl` to lock provider versions. This file must be committed to the repository.

```hcl
# versions.tf
terraform {
  required_version = "= 1.9.8"

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

## Local Development

Lefthook runs Terraform format and validate checks locally:

```bash
# Runs automatically on pre-commit
terraform fmt -check -recursive

# Runs automatically on pre-push
terraform validate
```

Install Lefthook to enable these hooks:

```bash
brew install lefthook
lefthook install
```
