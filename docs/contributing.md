# Contributing

## Development Setup

### Prerequisites

- [Lefthook](https://github.com/evilmartians/lefthook) for git hooks
- [Terraform](https://www.terraform.io/) for testing workflow logic locally
- [actionlint](https://github.com/rhysd/actionlint) for validating GitHub Actions workflow syntax
- [act](https://github.com/nektos/act) (optional) for running workflows locally

### Installation

```bash
brew install lefthook terraform actionlint

# Install git hooks
lefthook install
```

## Workflow

### Branches

Create a branch from `main` following the naming convention:

```
<type>/<description>
```

Examples:
- `feat/terraform-plan`
- `fix/provider-version-check`
- `docs/project-foundation`

### Commits

All commits follow [Conventional Commits](https://www.conventionalcommits.org/) with a JIRA ID:

```
<type>(<JIRA-ID>): <description>
```

Examples:
- `feat(FORGE-1): add terraform plan workflow`
- `fix(FORGE-42): correct output parsing in plan step`
- `docs(FORGE-5): add terraform workflow reference`

The commit message hook enforces this format. See the [Conventional Commits specification](https://www.conventionalcommits.org/en/v1.0.0/) for the full list of allowed types.

### Pull Requests

Each PR should be:
- **Scoped**: One logical change per PR
- **Atomic**: The repo should be in a working state after each merge
- **Documented**: Update relevant docs when changing behavior

PR titles follow the same conventional commit format:
```
feat(FORGE-1): add terraform plan workflow
```

## Adding a New Workflow

1. Create the workflow file in `.github/workflows/`
2. Use `workflow_call` as the trigger
3. Define all inputs with explicit types and descriptions
4. Pin all action versions to full commit SHA
5. Pin all tool versions explicitly — no `latest`
6. Add local hooks in `lefthook.yml` for fast feedback
7. Add documentation in `docs/<toolchain>.md`
8. Update the README documentation table

## Adding a New Toolchain

1. Create a new documentation page: `docs/<toolchain>.md`
2. Add the first workflow for the toolchain
3. Add lefthook hooks for local validation
4. Update the README "Supported Toolchains" list and docs table
5. Update `CONTEXT.md` repository structure section

## Testing Changes

### Workflow Syntax

```bash
actionlint .github/workflows/*.yml
```

### Local Workflow Execution

```bash
act -W .github/workflows/terraform-validate.yml
```

### Consumer Testing

For significant changes, test with a fork or a consumer repo before merging:

1. Push the branch to your fork
2. Point a consumer's workflow reference to your fork and branch
3. Verify the workflow runs correctly
