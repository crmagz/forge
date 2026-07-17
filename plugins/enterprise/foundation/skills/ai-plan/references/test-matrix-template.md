# Test Matrix Template

Use this template when generating the Test Matrix section inside a global
`.plan.md` file for Medium, Large, or High-risk work.

Copy only the content inside the fenced block below. Do not include the
fence markers in the generated plan file.

The test matrix is the executable behavior contract. It defines expected
behavior in testable terms. The Specification section defines narrative
intent — the test matrix makes those requirements verifiable.

---

```markdown
# Test Matrix

## Baseline

- Existing test count: [N]
- Existing test status: [all passing | N failures — list which]
- Test runner: [pytest | jest | gradle | etc.]
- Test command: [exact command]

If baseline was not run, state why and list the command.

## Required Tests

| ID | Test Name | Type | Covers | Scenario | Input | Expected Output | Failure Mode | Files Involved | Validation Command | Blocks Merge |
|---|---|---|---|---|---|---|---|---|---|---|
| TM-001 | `test_name` | unit | AC-001 | [scenario] | [input] | [output] | — | `repo:file.py` | `command` | Yes |
| TM-002 | `test_name` | unit | AC-002 | [scenario] | [input] | [output] | [failure covered] | `repo:file.py` | `command` | Yes |
| TM-003 | `test_name` | integration | AC-003 | [scenario] | [input] | [output] | [failure covered] | `repo:file.py` | `command` | No |

## Multi-Repo Validation

| Repo | Required validation | Command / evidence | Blocks Merge |
|---|---|---|---|
| [repo] | [unit/integration/contract/deploy validation] | `command` or evidence | Yes |
| [repo] | [manual/platform validation] | [evidence needed] | [Yes/No] |

## Coverage Checklist

Check all categories that apply to this change. Each checked category
must have at least one test in the table above.

- [ ] Happy path — normal input produces expected output
- [ ] Invalid input — validation rejects bad data with correct status/message
- [ ] Missing data — not-found cases return appropriate error
- [ ] Duplicate/replayed execution — idempotent behavior on retry
- [ ] Conflict/conditional failure — optimistic locking or conditional writes
- [ ] Retryable failure — transient errors trigger retry with backoff
- [ ] Terminal failure — non-retryable errors surface correct error response
- [ ] Timeout — operations that exceed time limits fail gracefully
- [ ] Partial progress recovery — interrupted work resumes correctly
- [ ] State transition correctness — only valid transitions are allowed
- [ ] Observability — expected logs, metrics, or traces are emitted

## Risk Trigger Required Coverage

When a risk trigger matches, the test matrix must include test rows or
explicit validation evidence for the matching category. Use `N/A` only
with a short justification.

| Matched trigger | Required coverage / evidence | Covered by |
|---|---|---|
| Auth, IAM, RBAC, secrets, credentials, or permissions | least-privilege check, unauthorized/forbidden path, no secret exposure in logs/config | TM-* or evidence |
| Persistence or schema changes | migration/backfill, backward compatibility, destructive-write prevention, rollback/restore path | TM-* or evidence |
| Workflow orchestration or state machines | valid transitions, invalid transitions rejected, catch/failure path, replay/duplicate execution | TM-* or evidence |
| Retry, idempotency, rollback, or partial-progress recovery affecting writes/state | retryable failure, terminal failure, idempotent replay, partial progress recovery | TM-* or evidence |
| Deployment config, infrastructure, or environment config | config validation, environment compatibility, deployment rollback, startup/smoke validation | TM-* or evidence |
| Infrastructure de-escalation (High-risk → Medium) claimed | Observed diff evidence (`cdk diff` update-in-place only, or rendered manifest diff), Observed rollback path, Observed non-prod target | TM-* or evidence |
| Public API endpoints or response models | request/response contract, compatibility, validation failure, documented status/error behavior | TM-* or evidence |
| Event or message contracts | producer schema, consumer compatibility, versioning/backward compatibility, malformed event handling | TM-* or evidence |
| Cross-service integrations | dependency failure, timeout, retry/circuit behavior, contract mismatch | TM-* or evidence |
| Changes spanning multiple repositories or deployable units | per-repo validation commands, contract compatibility, deployment ordering, rollback coordination | TM-* or evidence |
| Shared libraries/framework code or behavior used by multiple workflows | representative workflow regression coverage and compatibility checks | TM-* or evidence |
```
