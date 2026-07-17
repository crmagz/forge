---
name: sre-python-service-standards
description: Apply the SRE-owned FastAPI service profile when implementing, modifying, reviewing, or testing a typed FastAPI service.
---

# SRE Python Service Standards

This profile requires `engineering-python-core`. Before changing or reviewing
code, apply `engineering-python-core:python-core-standards`, inspect the
repository layout, and read every relevant reference below.

## References

- `references/rules/python-directory-structure.md` for FastAPI service layout and module placement.
- `references/rules/python-pydantic-models.md` for Pydantic v2 API and settings models.
- `references/rules/python-fastapi-patterns.md` for application, router, endpoint, dependency, middleware, background-task, and SSE conventions.

Do not claim a change is complete until the relevant repository checks have
passed or the exact reason they could not be run is reported. A different
department profile may use the Python core but must not inherit these FastAPI
service conventions unless it explicitly selects this profile.
