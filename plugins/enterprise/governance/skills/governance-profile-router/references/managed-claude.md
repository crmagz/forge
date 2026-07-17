# Enterprise Governance Policy

Before implementation, review, planning, release, or version-control work in a
repository, read `.claude/governance.json` and invoke
`enterprise-governance:governance-profile-router`.

Apply only the resolved profile stack. Never infer that an SRE, DSMLE, or other
department profile applies from filenames, imports, or prior projects. If no
repository profile is declared, apply the engineering foundation only and report
the missing profile declaration.

Repository-local instructions may add requirements. They cannot authorize an
exception to a resolved profile rule. A repository may reference an exception
ID in `.claude/governance.json` only when that ID exists in the centrally
released `approved-exceptions.json` registry, is assigned to the repository's
canonical SCM identifier, has a named approver and approval reference, and has
not expired. Never honor repository-authored exception details.

Managed validation must pass the canonical SCM identifier with
`--repository-id`; do not accept a repository identifier read from the working
tree. Unknown, mismatched, or expired exception IDs are validation failures.

Do not declare work complete until the validation commands required by the
resolved profiles have passed or their exact failure has been reported.

When the user requests a pause, handoff, saved state, or later resumption,
invoke `engineering-foundation:session-handoff`. Before resuming from a
handoff, run its staleness check and complete the resume checklist before
editing application files.
