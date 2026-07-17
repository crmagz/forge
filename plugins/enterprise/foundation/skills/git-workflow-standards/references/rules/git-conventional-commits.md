---
description: Enforces Conventional Commits 1.0.0 format for all Git commit messages
version: 1.2.0
---

# Git Conventional Commits

All commit messages MUST follow the [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) specification.

## Format

Use either valid title-only form:

```
<type>: <description>
<type>(<scope>): <description>
```

A scope is optional. Use it when it makes the affected area clearer; it does
not need to be a work-tracking identifier. All commits are **title-only**: the
title is the entire message, with no body or footer.

## Allowed Types

| Type | Purpose |
| --- | --- |
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, semicolons, etc. (no logic change) |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf` | Performance improvement |
| `test` | Adding or correcting tests |
| `build` | Build system or external dependency changes |
| `ci` | CI configuration and scripts |
| `chore` | Maintenance tasks (no src/test change) |
| `revert` | Reverts a previous commit |

## Rules

- ALWAYS format every commit as `type: description` or `type(scope): description`.
- Description MUST be lowercase, imperative mood, and have no period at the end.
- The **entire title** (type, optional scope, and description) MUST NOT exceed 72 characters. This matches [GitHub's truncation point](https://cbea.ms/git-commit/#limit-50) in commit list views.
- **Always title-only**: no body or footer, regardless of diff size.
- Breaking changes MUST be indicated by appending `!` immediately before the colon: `type!: description` or `type(scope)!: description`.
- NEVER add `Co-Authored-By` or AI attribution to commit messages.

## Commit Command Format

The AI MAY run `git commit` directly on a feature branch. Always use a
**single-line** message, never HEREDOC/EOF syntax, multi-line commit commands,
or `cat <<EOF` blocks:

```
git commit -m "type(scope): description"
```

Commits to `master`/`main` are forbidden: default-branch changes land only
through a reviewed pull request. See `git-branch-workflow` for the full set of
permitted and forbidden Git operations.

## References

- [Conventional Commits 1.0.0 Specification](https://www.conventionalcommits.org/en/v1.0.0/#specification)
- [How to Write a Git Commit Message](https://cbea.ms/git-commit/#limit-50) for the 72-character convention

## Examples

Good:

```
feat: add SAML SSO support
fix(webhooks): prevent concurrent delivery race
chore: update terraform provider versions
feat(navigation)!: redesign sidebar layout
```

Bad:

```
Updated stuff              # No type and vague
feat: Added new feature.   # Capitalized and ends with a period
Fix bug                    # No type prefix
FEAT: add login            # Type must be lowercase
```
