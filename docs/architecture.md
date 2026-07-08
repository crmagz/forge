# Architecture

## System Design

Forge is a **workflow library**, not an application. It provides reusable GitHub Actions workflows that other repositories call via `workflow_call`. This design centralizes CI/CD logic so that improvements and fixes propagate to all consumers.

```
┌─────────────────────┐     ┌─────────────────────┐
│   Consumer Repo A   │     │   Consumer Repo B   │
│                     │     │                     │
│  .github/workflows/ │     │  .github/workflows/ │
│    deploy.yml       │     │    infra.yml        │
│      │              │     │      │              │
│      │ uses:        │     │      │ uses:        │
└──────┼──────────────┘     └──────┼──────────────┘
       │                           │
       ▼                           ▼
┌──────────────────────────────────────────────────┐
│                     Forge                         │
│                                                   │
│  .github/workflows/        tasks/                 │
│    terraform.yml  ───────►  iac/Taskfile.yml      │
│    (orchestration)          (implementation)       │
│                                                   │
│  Workflows handle:          Tasks handle:          │
│    permissions              tool commands          │
│    concurrency              format / validate      │
│    environment gates        plan / apply           │
│    job summaries            destroy                │
│    PR comments                                     │
│    artifact passing                                │
└──────────────────────────────────────────────────┘
```

## Two-Layer Architecture

### Layer 1: Taskfiles (Implementation)

Taskfiles in `tasks/` contain the actual tool commands. They are portable — the same `task iac:plan` command runs identically on a developer's laptop and in CI. Taskfiles have no knowledge of GitHub Actions, permissions, or environments.

```
tasks/
├── iac/Taskfile.yml       # terraform fmt, validate, plan, apply, destroy
├── gitops/Taskfile.yml    # (future) argocd sync, diff
└── build/Taskfile.yml     # (future) docker build, push
```

### Layer 2: Workflows (Orchestration)

Workflows in `.github/workflows/` handle CI-only concerns. They call taskfiles to do the work, adding:

- **Input validation** — reject invalid actions, block `latest` versions
- **Permissions** — `id-token: write` for OIDC, `contents: read`, `pull-requests: write`
- **Concurrency** — prevent parallel runs against the same environment
- **Environment gates** — require approval before apply/destroy
- **Artifact passing** — save plan files between jobs
- **Job summaries** — post results to the GitHub Actions summary
- **PR comments** — post/update plan output on pull requests

## Workflow Design Principles

### Inputs Over Assumptions

Every workflow accepts explicit inputs. No workflow assumes directory structure, tool versions, or environment configuration. Consumers declare what they need; Forge handles how.

### Layered Validation

Checks are layered from fastest/cheapest to slowest/most expensive:

1. **Format** — instant, deterministic, no network
2. **Validate** — syntax and configuration checks
3. **Lint** — static analysis and policy checks
4. **Plan/Test** — full execution in dry-run mode
5. **Apply/Deploy** — production changes (gated by approval)

### Fail Fast

Workflows exit on the first failure. Expensive steps (plan, apply) never run if cheap steps (format, validate) fail. This minimizes wasted compute and feedback time.

## Local Development Loop

Developers run the same tasks locally that CI runs remotely. Lefthook wires the cheapest checks into git hooks for instant feedback.

```
Developer workstation              GitHub Actions
┌──────────────────────┐          ┌──────────────────────┐
│  pre-commit hooks    │          │  Reusable workflows  │
│    task iac:fmt      │    ──►   │    task iac:fmt       │
│                      │  same    │    task iac:validate  │
│  pre-push hooks      │  tasks   │    task iac:plan      │
│    task iac:validate │          │    task iac:apply     │
└──────────────────────┘          └──────────────────────┘
        1x cost                         10x cost
```

## Decision Log

| Decision | Rationale |
|----------|-----------|
| Taskfiles as implementation layer | Same commands locally and in CI. Workflows stay thin. Changes are testable before push. |
| Pin actions to SHA | Tags are mutable — a compromised action could be re-tagged. SHA is immutable. |
| Pin tool versions explicitly | Reproducibility. A workflow must produce the same result regardless of when it runs. |
| Lefthook over Husky | Lefthook is language-agnostic, fast, and supports parallel hook execution. |
| `workflow_call` over composite actions | Workflows provide full job control, secrets handling, and environment support. |
| Monorepo for workflows | Single source of truth. Versioned together. Easier to maintain consistency. |
| Plan artifact between jobs | Apply runs the exact plan that was reviewed, not a re-plan that might drift. |
