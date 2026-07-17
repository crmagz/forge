---
name: git-branch-workflow
description: Permitted and forbidden git operations for AI, default-branch protection, and the rebase-onto-default branch-cleanup workflow.
alwaysApply: true
version: 1.0.0
---

# Git Branch Workflow

The AI is trusted to drive the full lifecycle of a **feature branch** and
to assemble it into a clean, reviewable conventional-commit story. The
default branch (`master`/`main`) is protected: it changes only through a
reviewed pull request.

## Operation Matrix

| Operation | Feature branch | `master` / `main` |
| --- | --- | --- |
| `git commit` | ✅ Allowed | ❌ Forbidden |
| `git add` (stage) | ✅ Allowed | — |
| `git pull` / `git fetch` | ✅ Allowed | ✅ Allowed (read-only) |
| `git rebase` (incl. onto default) | ✅ Allowed | ❌ Never rebase the default branch |
| `git push` | ✅ Allowed | ❌ Forbidden — use a PR |
| `git push --force-with-lease` | ✅ Allowed (after rebase) | ❌ Forbidden |
| `git push --force` (bare) | ❌ Forbidden — use `--force-with-lease` | ❌ Forbidden |
| `git merge <default>` into branch | ❌ Forbidden — rebase instead | — |
| Merge / close a PR | ❌ Forbidden (human decision) | ❌ Forbidden |
| `git reset --hard`, `git clean -fdx`, branch deletion | ⚠️ Only when explicitly instructed | ❌ Forbidden |

A `pre-push` hook blocks pushes, force-pushes, and deletions targeting
`master`/`main` locally — a fast guardrail that catches mistakes before
they leave your machine. It is NOT authoritative: client-side hooks can be
bypassed (`--no-verify`, unset `core.hooksPath`) and are absent in a fresh
clone until the repository configures hooks, so the system of record for
default-branch protection is **server-side GitHub branch protection**.
Treat the hook as a backstop, not a license to attempt those pushes.

### Authoritative Enforcement (server-side)

The unbypassable control is a **GitHub branch protection ruleset** on
`master`/`main`: *Restrict creations/updates* (no direct pushes, no
force-push, no deletion) plus *Require a pull request before merging*. The
server rejects direct pushes for everyone regardless of local git config —
this is the system of record. The client `pre-push` hook cannot enforce
this (`--no-verify` skips it entirely); it only catches honest mistakes
faster.

## Starting Development — Safety Check

ALWAYS verify the working tree is safe to develop on BEFORE making any
change. The AI MUST confirm all of the following first:

1. **Not on a default branch** — `git branch --show-current` MUST NOT
   return the default branch (`master`/`main`).
2. **Descriptive branch name** — the branch name SHOULD identify the work
   (e.g. `feat/add-retry`). Follow repository-local naming rules when present.

The check has teeth — it returns non-zero, it does not just warn. It is a
function using `return` (not `exit`), so running it in your current shell
signals failure via `$?` without killing the session:

```bash
check_branch_safe() {
  local branch
  branch=$(git branch --show-current)

  # Refuse to develop on the default branch
  case "$branch" in
    master | main)
      echo "On default branch — create a feature branch first" >&2
      return 1
      ;;
  esac

}

check_branch_safe   # inspect $? — non-zero means do not start development
```

### Creating a Branch — Always Off the Freshly Fetched Default

ALWAYS create a new branch from the **up-to-date remote default**, NEVER
from a stale local `master`/`main`. Fetch first, then branch directly off
the remote-tracking ref so you start from what is actually on the server:

```bash
git fetch origin
git switch -c feat/short-description origin/<default>   # <default> = master or main
```

Branching off local `master` without fetching is a common mistake — it
bases the work on a stale tip and guarantees an avoidable rebase later.
When the developer asks to "create a branch", fetch and branch off the
remote default by default; do not silently branch from the local tip.

## Curated Conventional-Commit Story

The goal of a branch is a history a reviewer can read top to bottom:

- One logical change per commit, each a valid Conventional Commit (see
  `git-conventional-commits`)
- Rewrite **un-pushed local** history freely — squash fixups, reorder,
  reword, and split commits so the final sequence tells a clean story
- Do NOT rewrite commits already pushed to a branch others collaborate on
  unless the developer explicitly asks
- No "wip", "fix typo", or "address review" commits left in the final
  history — fold them into the commit they belong to

## Cleaning a Branch: Rebase Onto Default

To bring a branch up to date with the default branch, **rebase onto it** —
never merge the default branch back in. Merging creates merge commits that
clutter history and make every subsequent rebase harder to reason about.

```bash
# 1. Update remote-tracking refs (does not touch your working tree)
git fetch origin

# 2. Replay your branch's commits on top of the latest default branch
git rebase origin/<default>     # <default> = master or main

# 3. Resolve conflicts if any, then continue
#    git rebase --continue   (or --abort to bail out safely)

# 4. Re-publish the rebased branch — history was rewritten, so a plain
#    push is rejected. Use --force-with-lease (never bare --force):
git push --force-with-lease
```

`--force-with-lease` refuses to overwrite the remote branch if someone
else has pushed to it since your last fetch — protecting collaborators
while still letting you re-publish your own rebased work.

### Do Not Merge Default Into a Feature Branch

```bash
# ❌ WRONG — pollutes history with a merge commit and complicates rebasing
git merge origin/<default>

# ✅ RIGHT — linear history, easy to rebase again later
git rebase origin/<default>
```

## Landing Changes

Open a pull request against the default branch with the `gh` CLI (see
`git-pull-request`). The AI MAY create, update, and comment on PRs, but the
merge itself is a human decision.

When opening or updating a PR, check whether the base branch has advanced
since the branch diverged (`git rev-list --count HEAD..origin/<default>`).
If it has and the rebase is clean, rebase and re-push with
`--force-with-lease`. If it would **conflict**, surface that to the
developer and rewrite history only after they approve — the AI surfaces,
the human decides.
