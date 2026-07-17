# Plan Template

Use this template when generating the Plan section inside a global
`.plan.md` file for Medium, Large, or High-risk work.

Copy only the content inside the fenced block below. Do not include the
fence markers in the generated plan file.

---

```markdown
# Plan

## Plan File

- **Plan path**: [resolved with `scripts/resolve-plan-path.mjs`; default shape `~/.claude/plans/[baseRepo]/[kebab-case-name].plan.md`]
- **Created**: YYYY-MM-DD
- **Primary repo**: [repo name]
- **Target branch / ticket**: [branch and ticket ID or warning]

## Source of Request

- **ticket**: [ticket ID or "not provided"]
- **Requirements doc**: [path/link or "not provided"]
- **User prompt**: [short summary of the prompt that initiated planning]
- **Related PR/issue**: [path/link or "not provided"]

## Repository Scope

| Repo | Role | Local path / URL | Branch | Branch safety | Evidence status | Planned change |
|---|---|---|---|---|---|---|
| [primary-repo] | Primary implementation repo | `/path/to/repo` | `feature/ticket-1234-name` | Safe | Observed: `git -C /path branch --show-current` | [files/sections likely affected] |
| [related-repo] | [api/mqp/gitops/cdk/etc.] | `/path/to/repo` or [URL] | [branch or Unknown] | [safe/warning/unknown] | [Observed/Unknown evidence] | [planned or unknown impact] |

For inaccessible repos, use Unknown with impact:

- Unknown: [repo] is required for [reason] but is not locally accessible.
  Impact: implementation cannot verify [contract/config/deployment] until
  the repo is checked out or provided.

## Request Restatement

[Concrete restatement of what the developer asked for. Name the behavior
change, affected system, and expected outcome.]

## Risk Classification

**Level**: [Small | Medium | Large | High-risk]

**Triggers matched**:
- [trigger description — Observed: file path or command evidence]
- [trigger description — Observed: file path or command evidence]

**Borderline triggers** (did not match but worth noting):
- [trigger — why it did not match]

## Requirements Traceability

| ID | Requirement / acceptance criterion | Source | Covered by |
|---|---|---|---|
| AC-001 | [testable criterion] | [ticket, requirements doc, prompt, or Observed evidence] | TM-001, Phase 1 |
| AC-002 | [testable criterion] | [source] | TM-002, Phase N |

## Validation Baseline

Commands run before planning:

| Command | Result | Notes |
|---|---|---|
| `npm run test` | 42 passed, 0 failed | Clean baseline |
| `npm run lint` | 0 warnings | — |

If baseline was not run, state why and list the command that should
establish it before implementation.

## Repo Patterns to Mirror

| Category | Repo / Source File | Pattern |
|---|---|---|
| Naming | `repo:path/to/file:line` | [convention description] |
| Error handling | `repo:path/to/file:line` | [how errors are raised/caught] |
| Logging | `repo:path/to/file:line` | [logger style, levels] |
| Data access | `repo:path/to/file:line` | [read/write patterns] |
| Tests | `repo:path/to/file:line` | [fixture style, assertions] |
| Build/deploy | — | [commands used] |

If a pattern is not found: "Not found in repo — proposing [pattern]
based on [reasoning]."

## Files Likely to Change

- Observed: `repo:path/to/file.ts` currently owns [responsibility]
  Evidence: `repo:path/to/file.ts:line`
  Proposed: [what changes and why]
- Observed: `repo:path/to/other.ts` currently owns [responsibility]
  Evidence: `repo:path/to/other.ts:line`
  Proposed: [what changes and why]

## Phases

### Phase 1: [Name]

- **Objective**: [one sentence — what this phase accomplishes]
- **Behavior change**:
  - Proposed: [what changes from the user/system perspective]
  - Validation: [test or command that proves the change]
- **Files**:
  - Observed: `repo:path/to/file.ts` currently [responsibility]
    Evidence: `repo:path/to/file.ts:line`
    Proposed: [specific change]
  - Proposed: `repo:path/to/test.ts` adds/updates [test coverage]
- **Tests to add/update**:
  - TM-001 / `test_name` — covers AC-001 [scenario covered]
- **Risks**:
  - Assumed: [risk — severity, likelihood, mitigation]
    Verification needed: [how to validate the risk or mitigation]
- **Rollback**:
  - Proposed: [how to undo this phase if needed]
  - Validation: [how to confirm rollback is viable]
- **Validation commands**:
  - `command` — [expected result]
- **Completion criteria**: [AC-* and TM-* IDs that must pass for this phase]
- **Suggested commit**: `type(ticket ID): description`

### Phase N: [Name]

[Same structure as Phase 1]

## Assumptions

- Assumed: [claim]
  Verification needed: [how to verify]

## Open Questions

- [question — blocks Phase N — who can answer]

## Revision History

| Date | Change |
|---|---|
| YYYY-MM-DD | Initial plan |

---

## Implementation Gate

**Status**: Awaiting user confirmation.

No application code changes will be made until you confirm.

- **proceed** — implement as planned (or `implement phase 1` for phased work)
- **adjust [feedback]** — revise the plan with your feedback
- **stop** — abandon this approach
```
