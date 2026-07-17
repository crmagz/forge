# Department Profile Template

Create a department profile only when the department owns a distinct
implementation contract. A profile extends a foundation; it does not duplicate
or weaken it by default.

## Create a Profile

1. Copy this directory to the capability path, for example
   `plugins/data-science/python/dsmle` or `plugins/engineering/go/platform`.
2. Rename `plugin.json.template` to `.claude-plugin/plugin.json` and replace
   the example identifiers.
3. Rename `.governance-profile.json.template` to `.governance-profile.json`.
4. Rename the skill directory and `SKILL.md.template` to the chosen profile
   skill name.
5. Add the profile's owned rules under `references/rules/`, with a concrete
   validation command for each mechanically testable rule.
6. Add the profile to `enterprise-governance`'s catalog and run the governance
   validator.

## Profile Contract

A profile must define all of the following:

- A stable kebab-case ID and one accountable department owner.
- Its dependencies, normally a language or engineering foundation.
- The concerns it owns and any explicit replacements for a parent rule.
- A boundary stating which profiles it cannot be combined with.
- Versioned validation: hooks for immediate feedback and CI for merge gating.

For example, `dsmle-python` would require `engineering-python-core` and own
data contracts, reproducibility, model evaluation, and experiment-tracking
rules. It should not inherit FastAPI service layout from `sre-python-service`
unless the repository genuinely implements that service type.
