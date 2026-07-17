---
name: cdk-development-standards
description: Apply the SRE-owned AWS CDK infrastructure profile when implementing, modifying, reviewing, or documenting a TypeScript CDK repository.
---

# SRE CDK Standards

This profile requires `engineering-foundation`. Before changing or reviewing
CDK code, apply the foundation profile, inspect the repository, and read every
relevant reference below. Other departments may define their own infrastructure
profiles rather than inheriting this one.

## References

- `references/rules/cdk-directory-structure.md` for repository layout and ownership boundaries.
- `references/rules/cdk-code-style.md` for TypeScript naming, imports, and formatting.
- `references/rules/cdk-environment-config.md` for typed environment configuration.
- `references/rules/cdk-stack-pattern.md` for minimal, configuration-driven stacks and construct selection.
- `references/rules/cdk-service-pattern.md` for interface-first supporting services.
- `references/rules/cdk-resource-naming.md` for collision-safe, kebab-case resource names.
- `references/rules/cdk-documentation.md` for README and detailed documentation placement.

Treat deployment safety as a first-class concern: identify the affected
environment configuration, resource names, and validation commands before
editing, and report any check that could not be run.
