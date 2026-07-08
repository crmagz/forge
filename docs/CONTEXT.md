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

### Workflows Orchestrate Taskfiles

This is the foundational architectural pattern of Forge. There are two layers:

1. **Taskfiles** (`tasks/`) — the implementation layer. Taskfiles contain the actual tool commands (terraform, lint, build). They are portable, tool-agnostic, and identical whether run locally or in CI.
2. **Workflows** (`.github/workflows/`) — the orchestration layer. Workflows handle CI-only concerns: permissions, concurrency groups, environment gates, artifact passing, job summaries, and PR comments. They call taskfiles to do the actual work.

**Why this matters:**
- A developer running `task iac:plan` locally executes the exact same commands as CI
- Taskfile changes are testable locally before pushing
- Workflows stay thin — they orchestrate, they don't implement
- Adding a new check means adding a task first, then wiring it into a workflow

**When adding new functionality, always ask:** "Does this belong in a task or a workflow?" If it's a tool command or validation logic, it's a task. If it's about job ordering, permissions, or CI integration, it's a workflow.

### Reusable Over Repeatable

Workflows are designed as callable units (`workflow_call`). Consumers pass inputs; Forge handles orchestration. This means:
- Workflow logic lives in one place (this repo)
- Bug fixes and improvements propagate to all consumers on version bump
- Consumers configure, they don't implement

## Repository Structure

```
forge/
├── .github/
│   ├── workflows/              # Reusable GitHub Actions workflows
│   │   └── terraform.yml       # Terraform plan/apply/destroy workflow
│   ├── pull_request_template.md
│   └── release_template.md
├── tasks/                      # Taskfile implementation layer
│   ├── iac/                    # Infrastructure-as-code tasks (Terraform)
│   │   └── Taskfile.yml
│   ├── gitops/                 # GitOps tasks (future)
│   │   └── Taskfile.yml
│   └── build/                  # Build tasks (future)
│       └── Taskfile.yml
├── docs/                       # Detailed documentation
│   ├── CONTEXT.md              # This file — AI context
│   ├── architecture.md         # System design and decisions
│   ├── terraform.md            # Terraform workflow reference
│   ├── contributing.md         # Development standards
│   └── versioning.md           # Release and pinning strategy
├── Taskfile.yml                # Root taskfile (includes task modules)
├── lefthook.yml                # Git hook configuration
└── README.md                   # Project overview and quick start
```

### Task Directory Convention

Each task directory (`tasks/<domain>/`) contains a `Taskfile.yml` scoped to that domain. The root `Taskfile.yml` includes all task modules, creating namespaced commands:

```bash
task iac:plan          # from tasks/iac/Taskfile.yml
task gitops:sync       # from tasks/gitops/Taskfile.yml (future)
task build:docker      # from tasks/build/Taskfile.yml (future)
```

When adding a new task domain:
1. Create `tasks/<domain>/Taskfile.yml`
2. Add an include entry in the root `Taskfile.yml`
3. Wire tasks into relevant workflows

## Conventions

- **Workflow files**: Kebab-case, named by toolchain (e.g., `terraform.yml`)
- **Task namespaces**: Short lowercase names matching directory (e.g., `iac`, `gitops`, `build`)
- **Commit messages**: Conventional Commits — `feat: add terraform plan workflow`
- **Branches**: `<type>/<description>` (e.g., `feat/terraform-workflow`, `docs/project-foundation`)
- **PRs**: Scoped and atomic — one concern per PR, curated commit history
- **Versions**: Semver tags (`v1.0.0`), consumers reference tags like `@terraform/v1`

## Working in This Repo

### Adding a New Workflow

1. Create the task(s) in `tasks/<domain>/Taskfile.yml` — test locally first
2. Create the workflow in `.github/workflows/` — orchestrate the tasks
3. Define inputs via `workflow_call` with explicit types and descriptions
4. Pin all action versions to full SHA
5. Pin all tool versions explicitly
6. Add corresponding lefthook hooks for local validation
7. Document in `docs/<toolchain>.md`
8. Update the README task reference and documentation tables

### Adding a New Task Domain

1. Create `tasks/<domain>/Taskfile.yml`
2. Add include in root `Taskfile.yml`
3. Wire tasks into relevant workflows
4. Add local hooks in `lefthook.yml`
5. Document in `docs/<domain>.md`

### Modifying Existing Workflows

1. Check which repositories consume the workflow (search org for `uses:.*forge.*<workflow>`)
2. Ensure backward compatibility or bump the major version
3. Update documentation to reflect changes
4. Test with `act` or a fork before merging

## AI Agent Guidelines

- Do not add `Co-Authored-By` lines to commits
- Do not include JIRA IDs in commit scopes — this is a personal project
- Follow the conventional commit format strictly
- Keep PRs scoped: one logical change per PR
- Prefer explicit over implicit in all configuration
- When in doubt about a version, check the latest stable release rather than guessing
- Never use `latest` as a version for any tool, action, or dependency
- New tool commands belong in taskfiles; CI concerns belong in workflows
