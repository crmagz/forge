# Worked Examples

## Medium Inline Example

```markdown
## Plan

Request: Rename the internal scanner helper used by unit tests.
Risk: Medium — Observed: likely touches 6 files, which matches the
"More than 5 files likely to change" trigger.
Evidence: `rg "oldHelper" src tests` returned 6 files.

Patterns to mirror:
- Tests — Observed: scanner tests use Jest table tests.
  Evidence: `tests/scanner.test.ts:18`

Compact test checklist:
- [ ] Existing scanner unit tests still pass: `npm test -- scanner`
- [ ] No public API or persisted data behavior changes.
- [ ] Assumed: helper is internal only.
  Verification needed: confirm no exports outside `src/scanner`.

## Implementation Gate

Status: Awaiting user confirmation. No application code changes will be
made until you confirm.
```

## Evidence tag examples

**Observed** — verified in the repo.

```
Observed: error handling uses ServiceError with error code, detail, status
Evidence: src/services/migration.py:45
```

**Assumed** — believed true but not yet verified.

```
Assumed: the retry decorator respects DynamoDB throughput exceptions
Verification needed: inspect src/services/dynamo.py for retry logic
```

**Proposed** — new behavior or pattern not in the repo today.

```
Proposed: add circuit breaker on external API calls
Validation: test_circuit_breaker_opens_after_3_failures
```

**Unknown** — information the agent does not have and cannot infer.

```
Unknown: whether the downstream consumer handles schema v2
Impact: shipping a v2 event without consumer support causes silent data loss
```

Bad evidence:

```
The service probably retries failed writes.
```

Corrected:

```
Assumed: the service retries failed writes.
Verification needed: inspect the write path and retry wrapper before
planning implementation.
Impact if false: the plan may miss terminal failure and duplicate-write
coverage.
```
