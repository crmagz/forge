---
description: uv as sole Python package manager, pyproject.toml as single config source, no pip or poetry
alwaysApply: true
version: 1.1.0
globs: "*.py,pyproject.toml,Makefile,Dockerfile"
---

# Python Dependency Management

## uv Is the Only Package Manager

All Python projects MUST use [uv](https://docs.astral.sh/uv/) (by Astral) for package management, virtual environment creation, and Python version management.

**NEVER use:**

- `pip install` or `pip freeze`
- `poetry` or `pyproject.toml [tool.poetry]`
- `pipenv` or `Pipfile`
- `conda` or `mamba`
- `pip-tools` or `pip-compile`
- Manual `python -m venv`

### Common Commands

```bash
uv sync                    # Install all dependencies (like npm ci)
uv add <package>           # Add a production dependency
uv add --group dev <pkg>   # Add a dev dependency
uv remove <package>        # Remove a dependency
uv run <command>           # Run a command in the virtualenv
uv run pytest              # Run tests
uv run ruff check .        # Run linter
uv run mypy src/           # Run type checker
uv python pin 3.14         # Pin Python version
uv lock                    # Regenerate lockfile without installing
```

`uv sync` and `uv add` automatically update `uv.lock`. Use `uv lock` explicitly when you need to regenerate the lockfile without installing (e.g., in CI validation steps).

## Python Version

Python 3.14 is the target version. Every repository MUST have:

- `.python-version` file at the repo root containing `3.14`
- `requires-python = ">=3.14"` in `pyproject.toml`

```bash
uv python pin 3.14
```

### Dependency Compatibility

Python 3.14 is forward-looking. If a dependency does not yet support 3.14, handle it as follows:

1. Check the package's changelog or PyPI classifiers for 3.14 support
2. If unsupported, check for a pre-release or nightly that adds support
3. If no option exists, pin to the latest compatible version and add a `# TODO: upgrade when 3.14 support lands` comment in `pyproject.toml`
4. As a last resort, temporarily downgrade via `uv python pin 3.13` — but open a ticket to track upgrading back to 3.14

Do NOT silently downgrade the Python version without documenting why.

## pyproject.toml Is the Single Source of Truth

All tool configuration lives in `pyproject.toml`. Do NOT create separate config files:

| Tool | Configure In | NOT In |
| --- | --- | --- |
| Project metadata | `[project]` | `setup.py`, `setup.cfg` |
| Dependencies | `[project] dependencies` | `requirements.txt` |
| Dev dependencies | `[dependency-groups] dev` | `requirements-dev.txt` |
| Build system | `[build-system]` | — |
| Ruff | `[tool.ruff]` | `.flake8`, `setup.cfg`, `pyproject.toml [tool.black]` |
| Mypy | `[tool.mypy]` | `mypy.ini`, `.mypy.ini` |
| Pytest | `[tool.pytest.ini_options]` | `pytest.ini`, `setup.cfg` |

### Required pyproject.toml Sections

The versions below are examples at the time of writing. Pin to the latest stable release when creating a new project — do not copy these values verbatim.

```toml
[project]
name = "project-name"
version = "0.1.0"
description = ""
readme = "README.md"
requires-python = ">=3.14"
dependencies = [
    "fastapi==0.135.1",
    "uvicorn[standard]==0.42.0",
    "pydantic==2.12.5",
    "pydantic-settings==2.13.1",
]

[dependency-groups]
dev = [
    "pytest==9.0.2",
    "pytest-asyncio==1.3.0",
    "httpx==0.28.1",
    "ruff==0.15.7",
    "mypy==1.19.1",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["src/<package_name>"]
```

## Dependency Pinning

All dependencies MUST be pinned to exact versions using `==`:

```toml
# correct
dependencies = [
    "fastapi==0.135.1",
    "pydantic==2.12.5",
]

# incorrect — non-deterministic builds
dependencies = [
    "fastapi>=0.100",
    "pydantic~=2.0",
    "httpx",
]
```

The `uv.lock` lockfile MUST be committed to the repository for fully deterministic builds.

## Makefile Targets

Every Python project MUST include a Makefile with these targets:

```makefile
.DEFAULT_GOAL := help

.PHONY: help install dev clean format lint typecheck test check run

help:            ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*##"}; {printf "  %-18s %s\n", $$1, $$2}'

install:         ## Install all dependencies
	uv sync

dev: install run ## Install and start dev server

clean:           ## Remove caches and reinstall
	rm -rf .venv __pycache__ .mypy_cache .pytest_cache .ruff_cache
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	uv sync

format:          ## Auto-format with ruff
	uv run ruff format .
	uv run ruff check --fix .

lint:            ## Run ruff linter and format check
	uv run ruff check .
	uv run ruff format --check .

typecheck:       ## Run mypy strict type checking
	uv run mypy src/

test:            ## Run pytest suite
	uv run pytest

check: lint typecheck test  ## Run all checks (lint + types + tests)

run:             ## Start uvicorn dev server with hot-reload
	uv run uvicorn <package_name>.main:app --reload
```

The `check` target is the CI entrypoint — GHA workflows should run `make check` as the primary validation step.

## Build Backend

Use `hatchling` as the build backend with `src/` layout:

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["src/<package_name>"]
```

## Docker / Container Builds

All project services deploy on EKS. Use a multi-stage Dockerfile with uv for dependency installation:

```dockerfile
# CI/EKS builds use the ECR pull-through cache by default.
# Local builds can override:
#   docker build --build-arg REGISTRY=docker.io/library/ \
#                --build-arg UV_REGISTRY=docker.io/ .
ARG REGISTRY=113353499501.dkr.ecr.us-east-1.amazonaws.com/docker-hub/library/
ARG UV_REGISTRY=113353499501.dkr.ecr.us-east-1.amazonaws.com/docker-hub/

# --------------- build stage ---------------
FROM ${REGISTRY}python:3.14-slim AS builder

COPY --from=${UV_REGISTRY}astral/uv:0.11.3 /uv /uvx /bin/

WORKDIR /build

# Copy dependency files first for layer caching
COPY pyproject.toml uv.lock ./

# Install production dependencies only (no dev, no editable)
RUN uv sync --no-dev --no-install-project --frozen

# Copy source code and install the project
COPY src/ src/
COPY README.md ./
RUN uv sync --no-dev --no-editable --frozen

# --------------- runtime stage ---------------
FROM ${REGISTRY}python:3.14-slim AS runtime

RUN groupadd --gid 1000 app \
    && useradd --uid 1000 --gid app --shell /bin/false --no-create-home app

WORKDIR /app

# Copy only the virtualenv from builder
COPY --from=builder /build/.venv /app/.venv

ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

EXPOSE 8000
USER app

ENTRYPOINT ["python", "-m", "uvicorn"]
CMD ["<package_name>.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Key rules:

- `--frozen`: uses `uv.lock` exactly as committed — fails if lockfile is out of date
- `--no-dev`: excludes dev dependencies from the production image
- `--no-editable`: installs the package non-editable for runtime portability
- Copy `pyproject.toml` and `uv.lock` before `src/` for Docker layer caching
- Run as non-root user (`app:1000`)
- NEVER install `pip` or `uv` in the runtime stage — only the virtualenv is needed
- NEVER use `uv:latest` — always pin to a specific version (e.g. `0.11.2`) for reproducible builds
- Use the ECR pull-through cache (`UV_REGISTRY` / `REGISTRY` args) in CI/EKS; override to upstream registries for local builds
