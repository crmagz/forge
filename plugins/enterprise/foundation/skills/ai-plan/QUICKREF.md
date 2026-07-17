# ai-plan Quick Reference

`/ai-plan` inspects the repo, classifies risk, produces a plan sized
to that risk, and stops before any code changes until you confirm.

## Risk tiers

| Tier | Output | Files created |
|---|---|---|
| Small | Inline Plan (chat only) | None |
| Medium | Medium Inline Plan, or Focused Plan File if durable review is needed | None, or Plan + Test Matrix |
| Large | Large Plan File | Plan + Test Matrix + Specification (+ Review Checklist for security/state/data work) |
| High-risk | High-risk Plan File | Plan + Test Matrix + Specification + Review Checklist |

Two-tier trigger matches always resolve to the higher tier. Infra and
deployment config default to High-risk; de-escalation to Medium needs
Observed evidence for diff safety, rollback, and non-prod target.

## Evidence tags

- **Observed** — verified in the repo; needs a file:line or command output.
- **Assumed** — believed true, not yet verified; needs a verification path.
- **Proposed** — new behavior not in the repo; needs a validation approach.
- **Unknown** — info the agent lacks; needs the impact of not knowing.

## Implementation gate

Every plan ends with a gate — no code changes happen before you reply:

- `proceed` — implement as planned
- `adjust [feedback]` — revise the plan
- `stop` — abandon this approach

Full rules: `SKILL.md`. Trigger definitions: `references/risk-triggers.md`.
