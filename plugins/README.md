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
foundation through managed settings. Force-enable only the department profiles
approved for the organization; repositories choose among those approved
profiles through `.claude/governance.json`. Start from
[`managed-settings.example.json`](./enterprise/governance/skills/governance-profile-router/references/managed-settings.example.json)
and deploy the content of
[`managed-claude.md`](./enterprise/governance/skills/governance-profile-router/references/managed-claude.md)
through the Enterprise managed `claudeMd` policy.

Validate the marketplace catalog and a repository declaration with:

```bash
node enterprise/governance/scripts/validate-governance.mjs
node enterprise/governance/scripts/validate-governance.mjs --repository /path/to/repository
```
