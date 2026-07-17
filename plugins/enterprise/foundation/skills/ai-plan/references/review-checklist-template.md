# Review Checklist Template

Use this template when generating the Review Checklist section inside a
global `.plan.md` file.

Generate for all High-risk work. For Large work, generate only when the
change touches security, state machines, or data mutations. Otherwise
omit.

Copy only the content inside the fenced block below. Do not include the
fence markers in the generated plan file.

The checklist is change-specific — it tells reviewers exactly what to
verify for this change, not generic best practices.

---

```markdown
# Review Checklist

**Change**: [ticket ID] — [one-line description]
**Risk level**: [Large | High-risk]
**Triggers**: [which risk triggers matched]

## Blocker Checks

These must all pass. Any failure blocks merge.

- [ ] All acceptance criteria from the Specification section are met
- [ ] Multi-repo scope is complete; no required repo is left Unknown
      without an explicit implementation blocker or verification step
- [ ] No data loss or corruption path exists
- [ ] [change-specific blocker check — cite the specific risk]
- [ ] [change-specific blocker check]

## Major Checks

These should all pass. Exceptions require documented justification.

- [ ] All Test Matrix tests pass
- [ ] Error handling matches repo patterns (see Patterns to Mirror in
      the Plan section)
- [ ] Observability covers the critical path
- [ ] [change-specific major check]

## Medium Checks

- [ ] Edge cases in the Test Matrix are covered
- [ ] Naming follows repo conventions
- [ ] No unnecessary coupling introduced
- [ ] [change-specific medium check]

## Reviewer Instructions

- Cite file and line for every finding.
- Prefer a failing test over an opinion for behavioral findings.
- For security, performance, architecture, or operational findings,
  cite requirements, platform constraints, threat model evidence, or
  benchmark results.
- Address Blocker and Major findings before raising Medium or Minor.
- Do not suggest unrelated refactors.

## Finding Format

When reporting issues, use this format:

**[Severity]** `file:line` — [one-sentence finding]
- **Requirement**: [which acceptance criterion or check this violates]
- **Evidence**: [test output, command result, code reference, threat model, benchmark, or platform constraint]
- **Fix**: [minimal change to resolve]
- **Test/evidence that would catch or prove it**: [test name, "write: test_name", or non-test evidence required]

## Final Release Gate

Before approving merge:

- [ ] All Blocker checks pass
- [ ] All Major checks pass or have documented exceptions
- [ ] Test Matrix tests all pass
- [ ] Validation commands from the Plan section all pass
- [ ] No regressions in baseline tests
```
