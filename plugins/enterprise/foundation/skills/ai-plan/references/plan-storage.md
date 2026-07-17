# Global Plan Storage — Path Rules

Durable plans are stored outside the target repo:

```text
~/.{claude|cursor}/plans/<baseRepo>/<kebab-case-name>.plan.md
```

Path rules:

- Resolve durable plan paths with
  `node "${CLAUDE_SKILL_DIR}/scripts/resolve-plan-path.mjs"` when the script is
  available. Do not hand-build the path.
- Use `$AI_PLAN_HOME` as the plan root if it is set.
- Otherwise use `~/.claude` when running under claude.
- Otherwise use `~/.cursor` when running under cursor.
- If the agent environment is unknown, default to `~/.claude`.
- Do not infer or use `~/.codex` unless `$AI_PLAN_HOME` explicitly points
  there.
- Store plans under `plans/<baseRepo>/`.
- Derive `<baseRepo>` from the primary repo root and sanitize its
  directory basename to kebab-case. A repo root like
  `/path/to/repository` must produce `repository`, not the full
  path.
- Derive `<kebab-case-name>` from the ticket ID plus a short request title
  when available, for example `proj-1234-payment-retry`; otherwise use
  a concise kebab-case title from the request.
- Create the parent directory if needed.
- Include plan path, primary repo, all related repos, branch context,
  source of request, and creation date in the plan file header.
- Do not create repo-local planning files.

Example:

```bash
node "${CLAUDE_SKILL_DIR}/scripts/resolve-plan-path.mjs" \
  --repo-root /path/to/repository \
  --ticket PROJ-1234 \
  --title "Payment retry"
```

This resolves under `~/.claude/plans/repository/` by default.
