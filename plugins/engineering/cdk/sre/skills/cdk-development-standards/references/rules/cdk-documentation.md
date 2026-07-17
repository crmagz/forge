---
description: Documentation standards for CDK repositories — README and docs folder
alwaysApply: true
version: 1.0.0
---

# CDK Documentation Standards

## README.md

Keep the README concise and high-level:

- Project overview and purpose
- Installation instructions
- Quick start guide
- Table of Contents linking to `/docs` folder
- Links to external documentation

Do NOT include detailed implementation guides, API references, or architectural deep-dives in the README.

## /docs Folder

Place detailed technical documentation in `/docs`:

- Architecture diagrams
- API specifications
- Deployment guides
- Troubleshooting guides
- Design decisions (ADRs)

Do NOT repeat information from the README. The README is the entry point; `/docs` provides depth.

## Example

```markdown
# README.md

## Description
Brief project description.

## Installation
Quick installation steps.

## Documentation
- [Architecture](./docs/architecture.md)
- [API Reference](./docs/api-reference.md)
- [Deployment Guide](./docs/deployment.md)

## Links
- [Platform Documentation](https://docs.example.com/)
```
