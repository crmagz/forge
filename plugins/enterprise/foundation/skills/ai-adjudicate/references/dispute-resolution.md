# Dispute Resolution

Process for resolving disagreements between AI models, between an AI
model and a human reviewer, or between two human reviewers.

## When to Use

Use this process when:

- Claude finds issues with Codex's implementation (or vice versa)
- Two review passes produce contradictory findings
- A reviewer flags a concern that the implementer disagrees with
- Two models propose incompatible solutions to the same problem

## Evidence Types

Different kinds of disputes require different kinds of evidence.

### Behavioral disputes

Disagreements about whether code does what the spec says — use tests.

- A failing test is the strongest evidence that an implementation is
  wrong.
- A passing test is the strongest evidence that a concern is speculative.

### Security, IAM, and compliance disputes

Disagreements about whether code is safe — use threat model evidence
and platform constraints.

- IAM policy analysis (least privilege evaluation)
- Credential handling review (storage, rotation, exposure surface)
- Compliance requirements (cited regulation or company policy)
- Security scanner output or CVE references

### Performance and cost disputes

Disagreements about whether code will perform — use benchmarks and
analysis.

- Load analysis with realistic traffic assumptions
- Benchmark results on representative data
- Cost projections with stated assumptions
- Platform limits (API rate limits, throughput caps, connection limits)

### Architecture and design disputes

Disagreements about whether the approach is right — use cited
requirements and constraints.

- Requirements traceability (which requirement drives the design choice)
- Platform constraints (what the infrastructure supports)
- Operational evidence (incident history, monitoring data)
- Precedent in the repo (how similar problems were solved before)

## Process

### Step 1: Identify the disputed claim

State the specific disagreement in concrete terms:

- What does Reviewer A claim is wrong?
- What does Reviewer B claim is correct?
- What file, line, and behavior is in question?

Vague disagreements ("the error handling is wrong") must be narrowed
to specific claims ("line 45 catches Exception instead of ValueError,
which swallows database connection errors").

### Step 2: Check for a requirement

Does the spec, acceptance criteria, or test matrix already define the
expected behavior?

- **Yes**: the requirement settles it. The code must match the
  requirement. If the requirement itself is wrong, escalate to the
  developer — that is a spec change, not a code dispute.
- **No**: proceed to Step 3.

### Step 3: Produce evidence

The reviewer making the claim must produce evidence appropriate to the
dispute type:

- **Behavioral**: write an executable test that fails if the claim is
  true. The test must target the specific behavior, not a broader
  integration scenario.
- **Security/compliance**: cite the specific policy, threat vector, or
  scanner finding.
- **Performance**: provide load assumptions, benchmark data, or platform
  limit documentation.
- **Architecture**: cite the requirement, constraint, or precedent that
  makes the current approach wrong.

If the reviewer cannot produce evidence, the claim is speculative.
Document it as a Medium finding with "no supporting evidence" and move
on.

### Step 4: Evaluate the evidence

- **Test fails**: the bug is real. Fix the implementation.
- **Test passes**: the provided test does not reproduce the concern. The
  reviewer must refine the evidence, downgrade the finding, or withdraw
  the claim.
- **Security/performance/architecture evidence is presented**: evaluate
  whether it demonstrates a concrete risk under realistic conditions.
  Theoretical risks without realistic scenarios are Medium findings, not
  Blockers.

### Step 5: Escalate requirement gaps

If the disagreement is about **what the behavior should be** — not
whether the code matches the spec — escalate to the developer:

- State both proposed behaviors clearly.
- Explain the tradeoffs of each.
- Ask the developer to decide.
- Update the spec and test matrix with the decision.

## Anti-patterns

- **Arguing in prose without evidence.** If neither side can produce
  a failing test, a cited requirement, a benchmark, or a threat model
  finding, the disagreement is speculative and should not block progress.
- **Appeal to authority.** "Model X is more capable" is not evidence.
  Tests, requirements, and data are evidence.
- **Scope expansion.** Dispute resolution is about the specific claim,
  not a general review of the file. Do not introduce new findings during
  adjudication.
- **Infinite loops.** If three rounds of evidence exchange do not
  resolve the dispute, escalate to the developer. Do not continue
  indefinitely.
