---
name: ai-adjudicate
description: Resolve disagreements between AI models or reviewers using structured evidence. Use when Claude and Codex (or any two reviewers) produce conflicting findings and the dispute needs evidence-based resolution rather than prose arguments.
version: 0.1.0
---

# AI Adjudicate

**Status: Planned — not yet implemented.**

This skill is reserved for structured cross-model and cross-reviewer
dispute resolution. The reference material in `references/` captures
the evidence types, process, and anti-patterns identified during the
design of the `ai-plan` skill.

When this skill is built, it should:

- Accept a specific disputed claim with file, line, and behavior.
- Classify the dispute type (behavioral, security, performance,
  architecture).
- Require evidence appropriate to the dispute type.
- Resolve with tests for behavioral disputes, and with cited
  requirements, threat models, benchmarks, or platform constraints
  for non-behavioral disputes.
- Escalate requirement gaps to the developer.
- Cap rounds to prevent infinite loops.

See `references/dispute-resolution.md` for the starting design.
