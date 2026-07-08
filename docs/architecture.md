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
┌─────────────────────────────────────────────────┐
│                    Forge                         │
│                                                  │
│  .github/workflows/                              │
│    terraform-plan.yml    (workflow_call)          │
│    terraform-apply.yml   (workflow_call)          │
│    terraform-validate.yml (workflow_call)         │
│                                                  │
│  scripts/                                        │
│    (supporting scripts used by workflows)        │
└──────────────────────────────────────────────────┘
```

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

Lefthook enforces the same checks locally that CI runs remotely. The hook configuration mirrors the first two layers (format and validate) so developers get immediate feedback before pushing.

```
Developer workstation              GitHub Actions
┌──────────────────────┐          ┌──────────────────────┐
│  pre-commit hooks    │          │  Reusable workflows  │
│    fmt               │    ──►   │    fmt (verify)      │
│    validate          │          │    validate           │
│                      │          │    lint               │
│  pre-push hooks      │          │    plan / test        │
│    lint              │          │    apply (gated)      │
│    validate          │          │                      │
└──────────────────────┘          └──────────────────────┘
        1x cost                         10x cost
```

## Decision Log

| Decision | Rationale |
|----------|-----------|
| Pin actions to SHA | Tags are mutable — a compromised action could be re-tagged. SHA is immutable. |
| Pin tool versions explicitly | Reproducibility. A workflow must produce the same result regardless of when it runs. |
| Lefthook over Husky | Lefthook is language-agnostic, fast, and supports parallel hook execution. |
| `workflow_call` over composite actions | Workflows provide full job control, secrets handling, and environment support. |
| Monorepo for workflows | Single source of truth. Versioned together. Easier to maintain consistency. |
