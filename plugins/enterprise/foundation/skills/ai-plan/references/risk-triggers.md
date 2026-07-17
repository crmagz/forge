# Risk Escalation Triggers

This reference holds the full risk-trigger definitions, the evidence-gated
infrastructure de-escalation gate, the coordinated mechanical-rollout
carve-out, and the repo-type-aware pattern and validation vocabulary for
IaC and GitOps repos.

Classification must quote the matched trigger exactly as written here. A
classification that cannot cite the trigger text is invalid. Trigger names
are load-bearing — do not paraphrase them.

## Trigger definitions

### High-risk — any match escalates

- Auth, IAM, RBAC, secrets, credentials, or permissions
- Persistence or schema changes (e.g., database migrations, table
  definitions, destructive writes)
- Workflow orchestration or state machines (e.g., Step Functions,
  Temporal, Airflow, queue-driven pipelines)
- Retry, idempotency, rollback, or partial-progress recovery behavior
  that affects writes or state
- Deployment config, infrastructure, or environment configuration —
  High-risk by default, with evidence-gated de-escalation (below)

#### Infrastructure de-escalation — evidence-gated, never audience-gated

Infrastructure and deployment-config changes default to High-risk. The
agent may de-escalate to Medium only when it has **Observed** evidence
(never Assumed) for all three of:

1. **No resource replacement or deletion** — e.g., `cdk diff` output
   showing update-in-place only, or a rendered manifest diff
   (`helm template` / `kustomize build`) showing value-only changes.
2. **An automated or git-revertible rollback path** — e.g., ArgoCD
   auto-sync where `git revert` restores the prior state
   (Evidence: the Application manifest's sync policy), or a CDK
   stack rollback verified as safe.
3. **A non-production target environment** — e.g., the change is scoped
   to a dev/staging environment entry
   (Evidence: `bin/environments.ts:14` or the values file path).

If any of the three is Assumed or Unknown, the change stays High-risk.
Record the de-escalation and its three evidence lines in the plan's risk
classification. This gate calibrates on evidence, not on who is driving:
an operator who knows the rollback path can produce the evidence and
earns the faster lane; an agent that cannot produce it keeps full rigor.

De-escalation example — matches (High-risk → Medium):

```
Risk: Medium — infra change de-escalated from High-risk.
Observed: cdk diff shows [~] update-in-place on one resource, no
replacement or deletion. Evidence: `cdk diff` output.
Observed: rollback is git revert; ArgoCD auto-sync enabled.
Evidence: argocd/app.yaml:12 (`syncPolicy.automated`).
Observed: change targets dev only. Evidence: bin/environments.ts:14.
```

De-escalation example — does not match (stays High-risk):

```
Risk: High-risk — "just a config change" does not de-escalate.
Observed: change edits an IAM policy statement.
Evidence: lib/service-stack.ts:88 — matches the Auth/IAM trigger,
which has no de-escalation path.
Assumed: rollback is safe. De-escalation on Assumed is not allowed.
```

### Large — any match escalates to at least Large

- Public API endpoints or response models
- Event or message contracts (e.g., SNS/SQS/EventBridge, Kafka, webhook
  schemas)
- Shared models or contracts consumed by other services
- Cross-service integrations
- Changes spanning multiple repositories or deployable units, except
  coordinated mechanical rollouts (below)
- Shared libraries or framework code
- Behavior used by multiple workflows

#### Coordinated mechanical rollouts

A multi-repo change may stay at Medium (Medium Inline Plan with a
per-repo checklist) instead of escalating to Large when all of the
following hold:

- The change is identical or pattern-mirroring across every repo (e.g.,
  the same image tag bump, the same dependency version, the same config
  key rename).
- Each repo's change, judged on its own, classifies as Small or Medium —
  if any single repo's change would independently classify Large or
  High-risk, the whole rollout escalates to that level.
- The per-repo diff similarity is Observed (each accessible repo was
  inspected), not Assumed. If any repo in the batch is inaccessible,
  mark it Unknown and escalate to Large.

The Medium Inline Plan for a mechanical rollout must include one
checklist line per repo: repo name, branch-safety status, the mirrored
change, and its validation command.

### Medium — any match escalates to at least Medium

- More than 5 files likely to change
- More than 3 directories likely to change
- Tests need new fixtures or mocks
- An Assumed or Unknown item affects acceptance criteria, public
  behavior, data mutation, or expected test output

### Small

- Documentation-only changes
- Isolated config value changes with no production behavior, security,
  data, or integration impact. In config-only or GitOps repos — where
  every change is deployment config by definition — this includes
  non-production config value changes with Observed evidence of a
  git-revertible rollback path (e.g., ArgoCD auto-sync on a dev values
  file). Without that Observed evidence, classify via the
  infrastructure de-escalation gate instead
- Typo or formatting fixes
- Test-only additions with no source changes

## Repo-type-aware patterns and validation

Step 4 of the workflow captures patterns to mirror in a code-shaped
table:

| Category | Repo / Source File | Pattern |
|---|---|---|
| Naming | `repo:path/to/file:line` | Description of convention |
| Error handling | `repo:path/to/file:line` | How errors are raised/caught |
| Logging | `repo:path/to/file:line` | Logger style and level usage |
| Data access | `repo:path/to/file:line` | How data stores are read/written |
| Tests | `repo:path/to/file:line` | Test style, fixtures, assertions |
| Validation | — | Commands that verify correctness |

The table above is code-shaped. For IaC and GitOps repos, most of its
categories are structurally not applicable — do not force them. Instead
substitute categories that fit the repo type:

| Category | Repo / Source File | Pattern |
|---|---|---|
| Resource naming | `repo:lib/stack.ts:line` | Naming/tagging convention |
| Environment config | `repo:bin/environments.ts:line` | How env values are sourced |
| Diff safety | — | How change impact is previewed (`cdk diff`, rendered manifest diff) |
| Rollback | `repo:argocd/app.yaml:line` | Sync policy and revert path |
| Validation | — | Commands that verify correctness |

For IaC and GitOps repos, the Step 5 validation baseline is
repo-type-specific:

```bash
# CDK repos
npx cdk synth
npx cdk diff            # also the de-escalation evidence source

# GitOps repos
helm template <chart>           # or: kustomize build <overlay>
argocd app diff <app>           # when an ArgoCD context is available
```

A rendered-manifest or stack diff is the infra equivalent of a passing
test baseline: it is both the validation check and the Observed evidence
input to the infrastructure de-escalation gate.
