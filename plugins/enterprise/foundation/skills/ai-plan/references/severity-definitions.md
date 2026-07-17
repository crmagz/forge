# Severity Definitions

Static reference for review severity levels. These definitions are stable
across all changes — they do not vary per task.

## Blocker

The change cannot merge. Immediate fix required.

- Fails an acceptance criterion from the spec
- Data loss or corruption risk under normal or failure conditions
- Security exposure (auth bypass, credential leak, privilege escalation)
- Deployment-breaking issue (app will not start, infra will not deploy)
- Incorrect state transition (system enters an invalid or unrecoverable state)
- Non-idempotent retry behavior where retries are possible
- Missing rollback path for a destructive or irreversible operation

## Major

Likely production bug or significant gap. Should be fixed before merge
unless there is a documented exception with a follow-up ticket.

- Bug that will manifest under realistic production conditions
- Missing test for a critical path or failure mode
- Incorrect error handling (wrong status code, swallowed exception, missing error propagation)
- Missing rollback path for a reversible operation
- Observability gap on a critical path (no logging, metrics, or alerting for a failure mode that needs detection)
- Performance or cost problem at realistic scale (N+1 queries, unbounded scans, missing pagination)

## Medium

Edge case, maintainability issue, or best-practice gap. Should be
addressed but does not block merge.

- Edge case not covered by tests
- Maintainability concern (tight coupling, unclear responsibility boundaries)
- Minor deviation from repo conventions
- Weak test coverage (happy path only, no failure modes)
- Ambiguous naming or contract that could confuse future contributors

## Minor

Non-blocking cleanup. Fix if convenient, skip if not.

- Formatting inconsistency
- Small documentation gap
- Non-blocking code cleanup
- Naming preference (stylistic, not ambiguous)
- Comment quality
