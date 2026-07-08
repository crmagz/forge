# Forge - AI Context

This file provides AI agents and LLMs with the context needed to work effectively in this repository.

## What This Repo Is

Forge is a **reusable GitHub Actions workflow library**. It is not an application — it produces no deployable artifacts of its own. Repositories consume Forge by calling its workflows via `uses: <org>/forge/.github/workflows/<workflow>.yml@<ref>`.

## Core Principles

### Deterministic Builds

Every workflow pins all tool and dependency versions explicitly. No `latest` tags, no floating version ranges, no implicit defaults. A build today must produce the same result as the same build six months from now.

When adding or modifying workflows:
- Pin action versions to full SHA, not tags (e.g., `actions/checkout@<sha>` not `actions/checkout@v4`)
- Pin tool versions explicitly (e.g., `terraform_version: "1.9.8"` not `terraform_version: "latest"`)
- Pin provider and module versions in lock files

### Shift-Left Cost Model (1x / 10x / 100x)

The cost of catching an issue increases by an order of magnitude at each stage:

- **1x (Local)**: Git hooks via Lefthook run format checks, linting, and validation before code leaves the developer's machine. This is the cheapest place to catch problems.
- **10x (CI)**: GitHub Actions workflows run comprehensive checks — plan, test, security scan, policy enforcement. Catching issues here means a PR cycle, reviewer time, and pipeline minutes.
- **100x (Production)**: Issues in prod mean incidents, rollbacks, customer impact, and engineering hours. Everything Forge does is designed to prevent this.

When designing workflows, always ask: "Can this check run earlier?" If a CI check could be a git hook, make it a git hook first and keep it in CI as a safety net.

### Reusable Over Repeatable

Workflows are designed as callable units (`workflow_call`). Consumers pass inputs; Forge handles orchestration. This means:
- Workflow logic lives in one place (this repo)
- Bug fixes and improvements propagate to all consumers on version bump
- Consumers configure, they don't implement

## Repository Structure

```
forge/
├── .github/
│   └── workflows/          # Reusable GitHub Actions workflows
├── docs/                   # Detailed documentation
│   ├── architecture.md     # System design and decisions
│   ├── terraform.md        # Terraform workflow reference
│   ├── contributing.md     # Development standards
│   └── versioning.md       # Release and pinning strategy
├── scripts/                # Supporting scripts used by workflows
├── lefthook.yml            # Git hook configuration
├── CONTEXT.md              # This file — AI context
└── README.md               # Project overview and quick start
```

## Conventions

- **Workflow files**: Kebab-case, prefixed by toolchain (e.g., `terraform-plan.yml`, `terraform-apply.yml`)
- **Commit messages**: Conventional Commits with JIRA ID in scope — `feat(JIRA-123): add terraform plan workflow`
- **Branches**: `<type>/<description>` (e.g., `feat/terraform-plan`, `docs/project-foundation`)
- **PRs**: Scoped and atomic — one concern per PR, curated commit history
- **Versions**: Semver tags (`v1.0.0`), consumers reference major version tags (`@v1`)

## Working in This Repo

### Adding a New Workflow

1. Create the workflow file in `.github/workflows/`
2. Define inputs via `workflow_call` with explicit types and descriptions
3. Pin all action versions to full SHA
4. Pin all tool versions explicitly
5. Add corresponding lefthook hooks for local validation
6. Document in `docs/<toolchain>.md`
7. Update the README documentation table if adding a new toolchain

### Modifying Existing Workflows

1. Check which repositories consume the workflow (search org for `uses:.*forge.*<workflow>`)
2. Ensure backward compatibility or bump the major version
3. Update documentation to reflect changes
4. Test with `act` or a fork before merging

## AI Agent Guidelines

- Do not add `Co-Authored-By` lines to commits
- Follow the conventional commit format strictly — ask for JIRA ID if not provided
- Keep PRs scoped: one logical change per PR
- Prefer explicit over implicit in all configuration
- When in doubt about a version, check the latest stable release rather than guessing
- Never use `latest` as a version for any tool, action, or dependency
