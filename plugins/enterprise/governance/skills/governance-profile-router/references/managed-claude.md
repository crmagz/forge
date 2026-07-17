# Enterprise Governance Policy

Before implementation, review, planning, release, or version-control work in a
repository, read `.claude/governance.json` and invoke
`enterprise-governance:governance-profile-router`.

Apply only the resolved profile stack. Never infer that an SRE, DSMLE, or other
department profile applies from filenames, imports, or prior projects. If no
repository profile is declared, apply the engineering foundation only and report
the missing profile declaration.

Repository-local instructions may add requirements. They may replace a resolved
profile rule only through a documented, unexpired exception in
`.claude/governance.json`.

Do not declare work complete until the validation commands required by the
resolved profiles have passed or their exact failure has been reported.

When the user requests a pause, handoff, saved state, or later resumption,
invoke `engineering-foundation:session-handoff`. Before resuming from a
handoff, run its staleness check and complete the resume checklist before
editing application files.
