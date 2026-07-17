# Spec Template

Use this template when generating the Specification section inside a
global `.plan.md` file for Large or High-risk work only.

Copy only the content inside the fenced block below. Do not include the
fence markers in the generated plan file.

The spec defines narrative intent — the "what" and "why." It captures
the problem, current behavior, desired behavior, contracts, failure
modes, and acceptance criteria. The Test Matrix section makes these
requirements testable and verifiable.

---

```markdown
# Specification

## Problem Statement

[What is broken or missing, and why it matters. Be specific about the
impact — who is affected, what breaks, what is the cost of inaction.]

## Current Behavior

[How the system works today. Cite file paths and line numbers for every
claim. Use Observed tags.]

## Desired Behavior

[How the system should work after this change. Use Proposed tags for
new behavior.]

## Affected Repositories

| Repo | Role | Current behavior evidence | Desired change | Verification needed |
|---|---|---|---|---|
| [repo] | [api/mqp/gitops/cdk/etc.] | Observed: `repo:path:line` | [change] | [test/command/review] |
| [repo] | [role] | Unknown: [reason] | [possible change] | [what must be checked out or verified] |

## Requirements

| ID | Requirement | Source / Evidence | Notes |
|---|---|---|---|
| REQ-001 | [required behavior] | [ticket, requirements doc, prompt, or Observed evidence] | [constraints or assumptions] |
| REQ-002 | [required behavior] | [source] | [notes] |

## Scope

### In Scope

- [item — with rationale for inclusion]

### Out of Scope

- [item — with rationale for exclusion]

## Behavior Contract

### Inputs

| Field | Type | Required | Validation | Source |
|---|---|---|---|---|
| `field_name` | `string` | Yes | non-empty | request body |

### Outputs

| Field | Type | Condition | Description |
|---|---|---|---|
| `field_name` | `string` | always | [description] |

### Status Codes / Response Types

| Status | Condition | Response Shape |
|---|---|---|
| 200 | Success | `ResponseModel` |
| 404 | Not found | `ErrorResponse` |
| 422 | Validation failure | `ErrorResponse` |

## Data Contract Changes

### Before

[Current schema, table definition, or event shape — Observed from code]

### After

[Proposed schema — Proposed]

### Migration Path

[How existing data transitions to the new contract. Address:
- Backward compatibility during rollout
- Data backfill requirements
- Schema versioning approach]

## State and Lifecycle

### State Diagram

[Text-based state diagram if the change involves state transitions.
Omit this section if no state changes are involved.]

### Transition Rules

| From | To | Trigger | Side Effects | Reversible |
|---|---|---|---|---|
| `initial` | `processing` | API call | Creates record | No |
| `processing` | `complete` | Task success | Emits event | No |
| `processing` | `failed` | Task error | Logs error | Yes (retry) |

## Failure Modes

| Failure | Impact | Mitigation | Detection |
|---|---|---|---|
| [scenario] | [data loss / degraded / etc.] | [retry / fallback / alert] | [metric / log / alarm] |

## Retry and Idempotency

- **Retry strategy**: [exponential backoff / fixed / none]
- **Max retries**: [N]
- **Idempotency key**: [what makes a request idempotent]
- **Duplicate detection**: [how duplicates are identified and handled]

## Security Considerations

- [consideration — Observed or Proposed, with evidence]

## Observability

- **Logs**: [what is logged, at what level, structured fields]
- **Metrics**: [counters, histograms, gauges to emit]
- **Alarms**: [conditions that should page or alert]
- **Traces**: [span boundaries and attributes]

## Rollback Strategy

[How to undo this change if it fails in production. Address:
- Code rollback (revert the deploy)
- Data rollback (if schema or data changed)
- Feature flag (if applicable)
- Partial rollback (if some phases can be kept)]

## Acceptance Criteria

| ID | Criterion | Covers | Validation |
|---|---|---|---|
| AC-001 | [criterion — must be testable, not subjective] | REQ-001 | TM-001 |
| AC-002 | [criterion] | REQ-002 | TM-002 |

## Assumptions

- Assumed: [claim]
  Verification needed: [how to verify]

## Unknowns

- Unknown: [missing information]
  Impact: [why this matters and what it blocks]

## Open Questions

- [question — who can answer, what blocks on it]
```
