# Multi-Repo Scope

Plans may cover more than one repository, such as an API repo, message
processor repo, GitOps config repo, and infrastructure repo.

- Treat the current working repo as the primary repo unless the
  developer explicitly names a different primary repo.
- If multiple repos are named and the primary repo is not obvious, ask
  the developer which repo should own the plan path.
- If a request names multiple repos or paths, inspect each accessible
  repo enough to classify risk, identify ownership, and capture patterns.
- For each repo, record: repo name, local path or URL, role in the
  change, current branch, branch-safety status, relevant evidence, and
  planned files or sections likely to change.
- If a related repo is not checked out or cannot be read, do not block
  planning. Mark it Unknown with impact and list exactly what must be
  checked out or verified before implementation.
- Do not clone, fetch, switch branches, or edit related repos during
  planning unless explicitly asked.
- Changes spanning multiple repos or deployable units escalate to at
  least Large unless they are documentation-only, explicitly read-only,
  or qualify as a coordinated mechanical rollout (see Risk Escalation
  Rules).
