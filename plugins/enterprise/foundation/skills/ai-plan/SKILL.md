---
name: ai-plan
description: Create risk-scaled planning files that persist outside the session, distinct from ephemeral built-in plan mode. Use when preparing a feature, bug fix, refactor, migration, infrastructure change, stateful workflow change, shared contract change, or any task where the agent should inspect the repo, define tests, phase implementation, and wait for confirmation before code edits.
version: 1.3.1
invocation: /ai-plan
---

# AI Plan

Risk-scaled planning skill. Inspects the repo, classifies risk, produces
global planning files proportional to that risk, and gates
implementation behind explicit user confirmation.

## Problem

AI agents leap from incomplete requirements to implementation. On larger
changes this pushes critical validation into late review — causing
repeated Blocker/Major findings around missing contracts, weak tests,
unsafe state changes, incomplete rollback paths, non-idempotent behavior,
and undocumented assumptions. This skill makes agents discover, reason,
test-plan, and phase work before coding.

## Non-Goals

- Do not generate seven planning documents by default.
- Do not generate reusable prompt libraries per change.
- Do not generate ADRs unless a real architectural decision exists.
- Do not implement application code during planning.
- Do not invent architecture that is not found in the repo.
- Do not write planning files into the target repo — durable plans belong in the agent home directory.
- Do not delegate planning to subagents by default. The main agent owns repo inspection, plan-file creation, and final recommendations; use subagents only when asked or when independently reviewing plan files.
- Do not author or modify PRDs, specs, tickets, or requirements
  documents unless explicitly asked. Treat them as inputs.

## Output Modes

| Mode | Trigger | Output |
|---|---|---|
| Inline Plan | Small risk | Chat-only plan, no files |
| Medium Inline Plan | Medium risk by default | Chat-only plan with compact test checklist, no files |
| Focused Plan File | Medium risk with durable-review need | One global `.plan.md` file with Plan and Test Matrix sections |
| Large Plan File | Large risk | One global `.plan.md` file with Plan, Test Matrix, and Specification sections; add Review Checklist section only for security, state-machine, or data-mutation work |
| High-risk Plan File | High-risk | One global `.plan.md` file with Plan, Test Matrix, Specification, and Review Checklist sections |

Medium work needs a Focused Plan File only when at least one measurable
escalation signal applies:

- The developer explicitly requests durable plan files.
- An existing global plan file is being revised.
- More than 8 files or more than 4 directories are likely to change.
- Tests need new fixtures, mocks, or a new test structure.
- An Assumed or Unknown item affects acceptance criteria, data mutation, public behavior, or test output.

## Global Plan Storage

Durable plans are stored outside the target repo:

```text
~/.{claude|cursor}/plans/<baseRepo>/<kebab-case-name>.plan.md
```

- Resolve the path with `skills/ai-plan/scripts/resolve-plan-path.mjs`. Do not hand-build the path.
- Never create repo-local planning files.

For the full path-derivation rules (`$AI_PLAN_HOME`, environment
fallbacks, `<baseRepo>`/`<kebab-case-name>` derivation, example
invocation), read `references/plan-storage.md`.

### Multi-Repo Scope

Plans may cover more than one repository (API, message processor, GitOps
config, infrastructure). When a request touches multiple repos, read
`references/multi-repo.md` before planning: it defines primary-repo
selection, per-repo evidence capture, inaccessible-repo handling, and the
escalation rule for changes spanning multiple repos or deployable units.

### Medium Inline Example

For a worked Medium Inline Plan example, read `references/examples.md`.

## Input Modes

| Input or context | Route | Behavior |
|---|---|---|
| Empty input | Clarification | Ask what should be planned before inspecting or writing plan files |
| Work request | Request planning | Classify risk from the request and repo discovery |
| Requirements source | Traceable planning | Read Markdown, PRD, ticket, issue text, or pasted requirements as source material; record the source but do not modify it |
| Code context | Targeted planning | Inspect named files, directories, repo roots, or an existing diff first, then inspect related context before planning |
| Existing global plan file or plan path | Plan revision | Read the existing plan and update only the sections affected by the new request |

Input mode tunes inspection depth and traceability; risk triggers still
control escalation. Input modifiers are not separate modes:

- If the developer asks for durable plan files, deep/Large/High-risk
  planning, generate a plan file at least that deep.
- If the developer provides a desired risk level, validate it against the
  trigger rules and explain any escalation.

## Risk Escalation Rules

The agent must classify risk using the trigger rules below. Use
deterministic scripts when available; otherwise report the files
inspected and which triggers matched. Classify from the requested
behavior, likely affected systems, repositories and files discovered
during inspection, and any existing diff — not a diff that may not exist.

When triggers match at two different risk levels, choose the higher level.

Risk may escalate during planning but must not downgrade without
justification stated in the plan.

Before classifying any change touching infrastructure, deployment config,
or multiple repositories, read `references/risk-triggers.md`.
Classification must quote the matched trigger exactly as written there — a
classification that cannot cite the trigger text is invalid. That
reference also holds the evidence-gated infrastructure de-escalation gate,
the coordinated mechanical-rollout carve-out, and the repo-type-aware
pattern and validation vocabulary for IaC and GitOps repos.

Infrastructure and deployment config default to High-risk; de-escalation
to Medium requires **Observed** evidence for all three conditions per
`references/risk-triggers.md`.
De-escalation on Assumed or Unknown is never allowed.

### Tier summary

| Tier | Trigger categories (short form) |
|---|---|
| High-risk | Auth/IAM/RBAC/secrets/permissions; persistence or schema changes; workflow orchestration or state machines; retry/idempotency/rollback/partial-progress on writes; deployment config, infrastructure, or environment configuration (defaults High; evidence-gated de-escalation — see `references/risk-triggers.md`) |
| Large | Public API endpoints or response models; event or message contracts; shared models/contracts consumed by other services; cross-service integrations; changes spanning multiple repositories or deployable units (except coordinated mechanical rollouts — see `references/risk-triggers.md`); shared libraries or framework code; behavior used by multiple workflows |
| Medium | More than 5 files or more than 3 directories likely to change; tests need new fixtures or mocks; an Assumed or Unknown item affects acceptance criteria, public behavior, data mutation, or expected test output |
| Small | Documentation-only changes; isolated config value changes with no production behavior, security, data, or integration impact (GitOps non-prod carve-out — see `references/risk-triggers.md`); typo or formatting fixes; test-only additions with no source changes |

The tier phrases above are a lookup index — match against the exact
trigger text in `references/risk-triggers.md`.

## Evidence Rules

Every meaningful repo-specific claim (risk classification, patterns,
current behavior, affected files, phase behavior, risks, rollback notes)
must carry one of four tags. Untagged claims in those sections are
rejected — rewrite as one of these:

- **Observed** — verified in the repo; cite a file path + line, or a command and its output.
- **Assumed** — believed true but not yet verified; cite a verification path.
- **Proposed** — new behavior/pattern not in the repo; cite a validation approach.
- **Unknown** — info the agent lacks and cannot infer; cite the impact of not knowing.

Reject vague claims like "the service probably does X." Rewrite them as
Unknown or Assumed with verification steps.

For fenced examples of each tag and a bad/corrected evidence pair, read
`references/examples.md` in this skill's directory.

## Workflow

### Step 0: Clarify vague requests

If the request does not name a specific behavior change, affected system,
or expected outcome, ask the developer to clarify before proceeding. Do
not fabricate requirements to fill templates.

Examples that need clarification:
- "help me plan this" — plan what?
- "fix the service" — which service, which behavior?
- "make it better" — what is wrong with it now?

### Small Fast Path

Use this path only when the request clearly matches Small risk and no
higher-risk trigger is plausible, to keep everyday planning lightweight.

1. Restate the request.
2. Name the likely file(s) or area with Observed evidence. If evidence is
   unavailable without deeper discovery, label it Assumed and state how to
   verify.
3. State why no Medium/Large/High-risk trigger appears to match, using
   evidence tags for repo-specific claims.
4. List one validation command or manual check.
5. Emit the implementation gate.

Skip full repo discovery, baseline validation, and plan-file checks here.
If any uncertainty appears, exit the fast path and resume the full
workflow. If the fast path completes, stop after the implementation gate;
do not continue unless the developer asks for deeper planning.

### Step 1: Confirm branch safety

Verify the primary repo before implementation and record branch context
for every accessible repo before writing a durable plan file. For
chat-only inline planning, report an unsafe or non-git branch as a
warning and remain read-only.

```bash
BRANCH=$(git branch --show-current)
```

- For each repo expected to change, branch must NOT be `master`/`main`,
  and should contain the ticket ID (e.g., `PROJ-1234`) unless the repo's
  normal workflow says otherwise.
- If either check fails and the mode creates a global plan file, continue
  only if the file records the branch warning per repo and the gate states
  that code changes in that repo are blocked until branch safety is fixed.
- If either check fails in Small inline mode, continue only with a
  chat-only plan and repeat that implementation is blocked until fixed.

### Step 2: Restate the request

Restate the developer's request in concrete terms. Name the specific
behavior change, the affected system, and the expected outcome. Do not
parrot the request — demonstrate understanding.

### Step 3: Inspect repo context

Read these if they exist:

- `README.md`, `docs/CONTEXT.md`, `AGENTS.md`, `CLAUDE.md`
- Build/test config (`package.json`, `pyproject.toml`, `build.gradle`,
  `Makefile`, `tsconfig.json`)
- Source files and tests likely affected by the change
- Related repos named by the request, if they are locally accessible

If the input includes a requirements source, record it as the plan's
Source of Request; do not mutate external requirement docs unless asked.

For multi-repo work, inspect each accessible repo separately and keep
repo-qualified evidence such as `api-repo:src/routes/payments.ts:42` when
a path alone is ambiguous.

### Step 4: Capture patterns to mirror

For each category, find the existing repo pattern and record it in a
table. If none is found, say "Not found in repo" and propose one.

| Category | Repo / Source File | Pattern |
|---|---|---|
| Naming | `repo:path/to/file:line` | Description of convention |
| Error handling | `repo:path/to/file:line` | How errors are raised/caught |
| Logging | `repo:path/to/file:line` | Logger style and level usage |
| Data access | `repo:path/to/file:line` | How data stores are read/written |
| Tests | `repo:path/to/file:line` | Test style, fixtures, assertions |
| Validation | — | Commands that verify correctness |

This table is code-shaped. For IaC and GitOps repos, most of its
categories do not apply — substitute the repo-type-aware category table
in `references/risk-triggers.md` instead of forcing them.

### Step 5: Establish validation baseline

Run validation commands that do not edit source-controlled application
files (tests and linters may write caches, coverage, or build outputs —
that is acceptable). Use whatever the repo actually uses:

```bash
npm run test
npm run lint
```

For IaC and GitOps repos, the baseline is repo-type-specific
(`cdk synth`/`cdk diff`, `helm template`/`kustomize build`,
`argocd app diff`) — see `references/risk-triggers.md`. A
rendered-manifest or stack diff is the infra equivalent of a passing test
baseline: both the validation check and the Observed evidence input to the
de-escalation gate.

If validation is expensive, flaky, or needs unavailable setup, document
why the baseline was not run and the command that should establish it
before implementation. Skip this step in the Small fast path unless the
command is cheap and directly relevant. Record the result; if tests
already fail, note which and why — do not plan on top of a broken
baseline without informing the developer.

### Step 6: Classify risk

Apply the risk escalation rules from the section above. State:

- The risk level chosen.
- Which specific triggers matched, quoting each exactly as written in
  `references/risk-triggers.md`, with file path evidence. A classification
  that cannot cite the trigger text is invalid.
- Whether any triggers were close but did not match (borderline cases).

### Step 7: Resolve and check the global plan file

Before generating or updating a global plan file, resolve the plan path
using the Global Plan Storage rules, then check whether it exists:

```bash
test -e "$PLAN_PATH"
```

If an existing plan file is found:

- Read it before writing.
- If it reflects a prior pass for the same work, update surgically —
  preserve sections the developer may have edited, update changed
  sections, and note modifications in the Revision History.
- If it is from unrelated work, choose a different slug or ask the
  developer before overwriting.
- Never silently overwrite a global plan file.

### Step 8: Generate the plan

Based on the risk level, generate the appropriate output. For durable
plans, create one global `.plan.md` file composed from the section
templates in `references/`, copying only the content inside the fenced
markdown blocks — do not include the fence markers (` ```markdown ` /
` ``` `) in the generated plan file.

- **Small**: inline plan in the chat, including restated request, files to
  change, expected behavior change, validation command, and the gate. No
  files are created.
- **Medium**: inline plan with a compact test checklist. Create a global
  plan file (Plan + Test Matrix) only when durable review context is
  needed (see Output Modes).
- **Large**: global plan file with Plan, Test Matrix, and Specification.
  Add a Review Checklist only for security, state-machine, or
  data-mutation work.
- **High-risk**: global plan file with Plan, Test Matrix, Specification,
  and Review Checklist.

#### Greenfield and under-tested repos

If the repo has no existing test patterns, test infrastructure, or docs:

- Flag the gap as an Unknown with impact.
- Propose a test structure as Proposed with validation steps.
- For Medium and above, do not skip the TEST_MATRIX — define it against the proposed structure.
- For Small inline mode, include a minimal inline test checklist instead of a plan file.

### Step 9: Emit the implementation gate

The global plan file and the agent's final chat response must end with
the implementation gate.

```markdown
---

## Implementation Gate

**Status**: Awaiting user confirmation.

No application code changes will be made until you confirm.

- **proceed** — implement as planned (or `implement phase 1` for phased work)
- **adjust [feedback]** — revise the plan with your feedback
- **stop** — abandon this approach
```

**The agent MUST NOT edit any application source, config, infrastructure,
or test file before receiving explicit confirmation.** Validation
commands that do not edit source-controlled application files are
allowed. Writing or editing source files is not.

### Step 10: Wait for confirmation

Do nothing until the developer responds. Do not "start with a small
change" or "set up the scaffolding." Wait.

### On adjust: revising the plan

When the developer responds with "adjust [feedback]":

1. Update only affected sections in place; respect Step 7 overwrite safety.
2. Re-validate risk classification if the feedback changes scope.
3. Add a Revision History entry noting what changed.
4. Re-emit the implementation gate.
5. Do not re-run full repo discovery unless the feedback requires it.

## Handoff Guidance

After the developer confirms, the planning skill's job is done. Use the
repo's normal implementation, testing, review, and PR workflow — use the
repository's configured commit and PR review workflows once code
changes are ready. Do not invoke them until the developer asks or the
environment provides them. This section sets expectations for the
implementing agent (same or different), not obligations on the planner:

- Implement one phase at a time from the Plan section.
- After each phase, run its validation commands and report results.
- For Large and High-risk work, stop between phases and wait for confirmation.
- For Medium work, proceed through phases and report at the end.
- For Medium work that discovers contract, persistence, test-strategy, or
  operational-safety changes, add an inter-phase gate before proceeding.
- If a phase's validation fails, do not proceed; report it, propose a fix, wait.
- If repo reality diverges from the plan, update the remaining sections first.
- When implementation pauses, moves to another agent, or approaches context
  limits, invoke `engineering-foundation:session-handoff` to preserve the plan,
  decisions, validation results, and immediate next step.

## Plan File Lifecycle

Global plan files are working documents, not permanent project docs:

- **During development**: kept outside the target repo for easy reference without adding branch technical debt.
- **Before merge**: nothing needs to be removed from the target repo.
- **Staleness**: plan files are point-in-time snapshots. After the branch merges, the code is the source of truth — not the plan.

## Plan File Sections

- **Specification** — narrative intent ("what"/"why"): requirements, contracts, failure modes, acceptance criteria.
- **Test Matrix** — the executable behavior contract ("how to verify"): makes requirements testable, gives reviewers concrete evidence.
- **Plan** — the implementation roadmap, the "how" and "when."
- **Review Checklist** — the change-specific verification guide.

The spec defines what is correct; the test matrix proves it — neither outranks the other.

## Section Templates

Templates for each plan section live in `references/`:

- `references/plan-template.md` — Plan section structure
- `references/test-matrix-template.md` — Test Matrix section structure
- `references/spec-template.md` — Specification section structure
- `references/review-checklist-template.md` — Review Checklist section structure
- `references/severity-definitions.md` — static Blocker/Major/Medium/Minor definitions

Conditional-read references (read before classifying the relevant change):

- `references/risk-triggers.md` — full trigger definitions, de-escalation gate, mechanical-rollout carve-out, IaC/GitOps vocabulary
- `references/multi-repo.md` — multi-repo scope rules
- `references/plan-storage.md` — full global plan path-derivation rules
- `references/examples.md` — Medium inline plan and evidence-tag examples

## Definition of Done

Each tier includes the requirements from the tiers above it.

### Inline Plans (Inline Plan, Medium Inline Plan)

- [ ] Risk level is justified with trigger evidence
- [ ] Repo claims have Observed/Assumed/Proposed/Unknown labels
- [ ] Assumptions have explicit verification paths
- [ ] Implementation gate is emitted
- [ ] No application code was changed during planning
- [ ] Validation command is listed or documented why not
- [ ] Medium Inline Plan includes a compact test checklist covering expected behavior and the main failure mode

### Plan Files (Focused, Large, High-risk Plan File)

- [ ] Required global plan file sections for the selected mode are created or updated
- [ ] Test matrix defines expected behavior for all applicable coverage categories
- [ ] Phases are independently reviewable and map to conventional commits
- [ ] Validation commands are listed and the baseline is recorded (or documented why not)
- [ ] Patterns-to-mirror table cites source files (not prose assertions)
- [ ] Large Plan File includes a Specification section with acceptance criteria, failure modes, and contracts

### High-risk Plan File

- [ ] Plan, Test Matrix, Specification, and Review Checklist sections are all created or updated
- [ ] Test matrix includes coverage or explicit validation evidence for each matched High-risk trigger
- [ ] Review checklist includes change-specific Blocker/Major checks
