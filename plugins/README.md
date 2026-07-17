# Forge Enterprise Governance Plugins

This marketplace packages portable engineering governance without
organization-specific names, internal packages, paths, teams, or ticket-system
assumptions. It separates common foundations from department-owned profiles so
one Python implementation does not silently govern another.

## Hierarchy

| Tier | Plugin | Source path | Purpose |
| --- | --- | --- | --- |
| Enterprise | `enterprise-governance` | `enterprise/governance` | Resolves the repository's declared profile stack |
| Foundation | `engineering-foundation` | `enterprise/foundation` | Planning, session handoff, adjudication, and Git workflow |
| Language | `engineering-python-core` | `engineering/python/core` | Shared Python style, dependency, typing, and testing rules |
| Language | `engineering-nodejs-core` | `engineering/nodejs/core` | Native ESM TypeScript, GTS/ESLint/Prettier, and typed service rules |
| Department | `sre-python-service` | `engineering/python/sre-service` | FastAPI service conventions and endpoint/service workflows |
| Department | `sre-cdk` | `engineering/cdk/sre` | AWS CDK infrastructure conventions |

`sre-python-service` inherits `engineering-python-core`, which inherits
`engineering-foundation`. `sre-cdk` inherits `engineering-foundation` directly.
`engineering-nodejs-core` also inherits `engineering-foundation` and is the
base for future Node.js department profiles.
The complete catalog and dependency declarations are machine-readable in
`enterprise-governance`.

## Repository Selection

Each governed repository commits `.claude/governance.json`. Start from
[`example-governance.json`](./enterprise/governance/skills/governance-profile-router/references/example-governance.json):

```json
{
  "version": 1,
  "profiles": ["sre-python-service"],
  "exceptions": []
}
```

The `enterprise-governance:governance-profile-router` skill resolves required
profiles before department-specific work. Do not select two profiles that own
the same implementation concern unless their documented contract explicitly
allows composition.

## Exception Authority

Repositories cannot authorize exceptions to enterprise rules. Their
`.claude/governance.json` may contain only centrally approved exception IDs:

```json
{
  "version": 1,
  "profiles": ["sre-python-service"],
  "exceptions": ["architecture-temporary-exception"]
}
```

The central governance release owns
[`approved-exceptions.json`](./enterprise/governance/skills/governance-profile-router/references/approved-exceptions.json).
Each record must include its ID, canonical SCM repository identifier, rule,
reason, accountable owner, approver, approval reference, and an ISO-8601
expiry timestamp. Update that registry through the centrally controlled plugin
release process, not through the governed repository.

Managed CI or a centrally managed hook must validate the repository with its
canonical SCM identifier supplied outside the working tree:

```bash
node enterprise/governance/scripts/validate-governance.mjs \
  --repository /path/to/repository \
  --repository-id example-org/example-repository
```

Unknown, expired, or repository-mismatched IDs fail validation. A repository
may add stricter local requirements, but it cannot weaken a resolved profile
through local exception text.

## Department Extensions

Use [`templates/department-profile`](./templates/department-profile) to create
a new department profile, such as `dsmle-python`. It requires an explicit
owner, dependencies, implementation boundary, and validation command. Add the
completed plugin and its descriptor to the governance catalog only after the
profile has an owner and tests.

Install this local marketplace in Claude Code with:

```bash
claude plugin marketplace add /Users/bluewizard/git/forge/plugins
```

In an enterprise deployment, force-enable `enterprise-governance` and the
foundation through managed settings. Add only department profiles approved for
the target organization or entitlement group; repositories choose among those
approved profiles through `.claude/governance.json`. Start from
[`managed-settings.example.json`](./enterprise/governance/skills/governance-profile-router/references/managed-settings.example.json)
and deploy the content of
[`managed-claude.md`](./enterprise/governance/skills/governance-profile-router/references/managed-claude.md)
through the Enterprise managed `claudeMd` policy.

The managed-settings template intentionally does not set
`allowManagedHooksOnly`. Do not enable that restriction until centrally managed
hooks provide the required replacements for repository-level controls, such as
governance validation and secret scanning, and the rollout verifies that no
required control is suppressed.

Validate the marketplace catalog and a repository declaration with:

```bash
node enterprise/governance/scripts/validate-governance.mjs
node enterprise/governance/scripts/validate-governance.mjs --repository /path/to/repository
```

Run the portable smoke suite before publishing a marketplace release:

```bash
node tests/run-smoke-tests.mjs
```

It validates the catalog and fixture repository, rejects a repository-authored
exception ID that has no central approval, and resolves an AI plan path from an
arbitrary working directory using `CLAUDE_SKILL_DIR`-compatible plugin paths.
