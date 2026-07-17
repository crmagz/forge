---
description: Standardized Python service repository directory layout and file organization
alwaysApply: true
version: 1.0.0
globs: "*.py"
---

# Python Directory Structure

All Python service repositories must follow this standardized `src/` layout:

```
├── src/<package_name>/
│   ├── __init__.py                     # Package marker (empty or minimal exports)
│   ├── main.py                         # FastAPI app entry point
│   ├── config.py                       # Pydantic BaseSettings configuration
│   ├── api/
│   │   ├── __init__.py                 # Router exports
│   │   ├── health.py                   # /health and /readyz endpoints
│   │   └── <domain>.py                 # Domain-specific route handlers
│   ├── models/
│   │   ├── __init__.py                 # Model exports
│   │   ├── health.py                   # HealthResponse, ReadyResponse
│   │   └── <domain>.py                 # Domain-specific Pydantic models
│   └── services/
│       ├── __init__.py                 # Service exports
│       └── <domain>.py                 # Business logic and external integrations
├── tests/
│   ├── __init__.py
│   ├── conftest.py                     # Shared pytest fixtures (async client, etc.)
│   ├── unit/
│   │   ├── __init__.py
│   │   └── test_<module>.py            # Unit tests
│   └── integration/
│       ├── __init__.py
│       └── test_<module>.py            # Integration tests
├── docs/
│   └── CONTEXT.md                      # Architecture and project context
├── pyproject.toml                      # Single source of truth for all tool config
├── Makefile                            # Developer workflow commands
├── Dockerfile                          # Multi-stage production build
├── .python-version                     # Python 3.14 pin (read by uv)
├── uv.lock                             # Dependency lockfile (committed)
├── .gitignore
├── README.md
├── AGENTS.md                           # AI governance standards
└── CLAUDE.md                           # Claude Code instructions
```

## Directory Purposes

- **`src/<package_name>/`**: Application source code
  - `main.py`: FastAPI app initialization, lifespan, and router registration
  - `config.py`: Pydantic `BaseSettings` class with env-based configuration
  - `api/`: FastAPI routers — one file per domain (e.g., `migrations.py`, `users.py`)
  - `models/`: Pydantic v2 models for request/response schemas and data transfer objects
  - `services/`: Business logic, external API clients, and data access — no FastAPI dependencies

- **`tests/`**: Test suites
  - `conftest.py`: Shared fixtures (async HTTP client, mocks, test settings)
  - `unit/`: Fast, isolated tests with mocked dependencies
  - `integration/`: Tests that exercise real dependencies or multiple layers

- **`docs/`**: Detailed technical documentation

## Naming Rules

- **Package name**: `snake_case` derived from the project name (e.g., `project-billing-api` → `project_billing_api`)
- **Module files**: `snake_case.py` (e.g., `repo_cloner.py`, `phase_runner.py`)
- **Test files**: `test_<module>.py` matching the module under test
- **Directories**: `snake_case` (e.g., `phase_runner/` for sub-packages)

## Sub-packages

When a service module grows complex, promote it to a sub-package:

```
services/
├── __init__.py                 # Re-exports: from .phase_runner import PhaseRunner
└── phase_runner/
    ├── __init__.py
    ├── runner.py
    ├── state.py
    └── tools.py
```

## What Goes Where

| File Type | Location |
| --- | --- |
| FastAPI route handlers | `src/<pkg>/api/<domain>.py` |
| Pydantic request/response models | `src/<pkg>/models/<domain>.py` |
| Business logic and integrations | `src/<pkg>/services/<domain>.py` |
| Application configuration | `src/<pkg>/config.py` |
| App entry point | `src/<pkg>/main.py` |
| Shared test fixtures | `tests/conftest.py` |
| Unit tests | `tests/unit/test_<module>.py` |
| Integration tests | `tests/integration/test_<module>.py` |

## Anti-patterns

- Do NOT place application code outside `src/<package_name>/`
- Do NOT create `utils/` or `helpers/` catch-all directories — put logic in the appropriate domain module or service
- Do NOT create a flat file structure — always use the `api/`, `models/`, `services/` separation
- Do NOT mix Pydantic models with route handlers in the same file
