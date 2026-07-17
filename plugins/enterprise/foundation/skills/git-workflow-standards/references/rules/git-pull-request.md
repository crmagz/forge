---
name: git-pull-request
description: Standards for creating and reviewing pull requests.
version: 1.1.0
---

# Pull Request Workflow

## PR Title Format

All PR titles MUST follow Conventional Commits:

```
<type>: <description>
<type>(<scope>): <description>
```

### Types

| Type       | Purpose                                           |
| ---------- | ------------------------------------------------- |
| `feat`     | New feature or capability                         |
| `fix`      | Bug fix                                           |
| `docs`     | Documentation only changes                        |
| `style`    | Formatting, whitespace (no logic change)          |
| `refactor` | Code change that neither fixes nor adds a feature |
| `perf`     | Performance improvement                           |
| `test`     | Adding or correcting tests                        |
| `build`    | Build system or dependency changes                |
| `ci`       | CI configuration changes                          |
| `chore`    | Maintenance tasks                                 |
| `revert`   | Reverts a previous commit                         |

Breaking changes: Add `!` before the colon, e.g., `feat(api)!: redesign API`

## Required Sections

Every PR must include:

1. **Type of Change**: Feature, bug fix, refactor, etc.
2. **Summary**: What problem does this solve? What's the motivation?
3. **What Changed**: What did you change and why this approach?
4. **How You Tested**: Test coverage and verification steps
5. **Checklist**: Style, warnings, review readiness

Include a work-tracking ticket link only when the repository or team workflow
requires one.

## Code Change Requirements

### Tests (`/tests`)

Code changes SHOULD be accompanied by test updates:

- **New features**: Add unit tests covering the new functionality
- **Bug fixes**: Add regression tests that would have caught the bug
- **Refactors**: Ensure existing tests still pass, add tests for edge cases

Exceptions (document in PR):

- Pure documentation changes
- Configuration-only changes
- Trivial changes (typos, formatting)

### Documentation (`/docs`)

Feature and behavior changes SHOULD include documentation:

- **New features**: Add usage docs, examples, API reference
- **Breaking changes**: Update migration guides
- **Configuration changes**: Update setup/config docs

## Pre-PR Checklist

Before creating a PR:

1. **Branch**: Work on a feature branch, never `master`/`main`. Create it
   from the freshly fetched remote default, not a stale local tip. Bring it
   up to date by rebasing onto the default branch
   (`git fetch origin && git rebase origin/<default>`), not by merging the
   default branch in. See `git-branch-workflow`.
2. **Commits**: Follow conventional commit format, curated
   into a clean story (squash fixups, reword as needed)
3. **Tests**: Run tests locally - all tests must pass
   - Node.js: `npm run test`
   - Python: `uv run test`
   - Java: `./gradlew test`
4. **Lint**: Run linter - no new warnings
5. **Build**: Run build - must succeed

The AI MAY run `gh pr create` directly once these pass. Opening or
updating a PR is allowed; **merging** the PR is a human decision.

## gh CLI Requirements

PRs are created using the GitHub CLI (`gh`):

- **Install**: `brew install gh` (macOS) or `sudo apt install gh` (Linux)
- **Authenticate**: `gh auth login`
- **Verify**: `gh auth status`

## Creating a PR

Use the `/pr` skill or manually:

```bash
gh pr create \
  --title "feat: add new feature" \
  --body "$(cat <<'EOF'
## Type of Change

- [x] Feature (new functionality)

## Summary

Brief description of what problem this solves and the motivation.

## What Changed

What you changed and why this approach.

## How You Tested

- [x] Tests added/updated in `/tests`
- [x] All tests pass locally

## Checklist

- [x] PR title follows conventional commit format
- [x] Self-reviewed my own code
- [x] Docs updated (if behavior changed)
- [x] No new warnings generated
EOF
)"
```
