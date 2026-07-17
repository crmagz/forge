---
name: governance-profile-router
description: Resolve and apply the governance profile declared by a repository before implementation, review, planning, or release work. Use at the start of every repository task when enterprise governance is enabled.
---

# Governance Profile Router

Repository governance is a resolved hierarchy, not a collection of every
available standard. Read `.claude/governance.json` at the repository root
before applying department or language standards. Validate its shape against
`references/governance-profile.schema.json` and resolve each declared profile
through `references/governance-catalog.json`.

## Resolution Rules

1. Resolve each selected profile's `requires` dependency before the profile
   itself. A dependency is inherited exactly once.
2. Apply enterprise policy, then foundation, language, department, repository,
   and component guidance in that order. More-specific guidance may replace a
   broader rule only when the profile documents the replacement explicitly.
3. Do not apply an unrelated department profile. A DSMLE repository and an SRE
   service may share `engineering-python-core`, but their implementation rules
   remain separate.
4. Treat repository-local instructions as the next layer after the declared
   profiles. Escalate conflicting instructions to the profile owner instead of
   silently choosing one.
5. Honor an exception only when `.claude/governance.json` references an ID in
   the centrally released `approved-exceptions.json` registry, the record is
   assigned to the repository's canonical SCM identifier, and it is unexpired.
   Repository-authored exception details are invalid.

## Current Profile Map

- `engineering-foundation`: planning, session handoff, adjudication, and Git
  workflow.
- `engineering-python-core`: shared Python style, dependency, typing, and test
  standards; requires `engineering-foundation`.
- `engineering-nodejs-core`: native ESM TypeScript, GTS/ESLint/Prettier,
  factory service, and Jest test standards; requires `engineering-foundation`.
- `sre-python-service`: SRE FastAPI service conventions; requires
  `engineering-python-core`.
- `sre-cdk`: SRE AWS CDK conventions; requires `engineering-foundation`.

If `.claude/governance.json` is missing, apply only the enterprise and
foundation policies already required by the environment, report the missing
profile declaration, and do not infer a department-specific implementation.
