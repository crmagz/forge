---
name: python-add-service
description: Interactive workflow for adding a new service module with typed interface, implementation, and tests to a Python FastAPI project.
version: 1.1.0
---

# Add Python Service

Step-by-step interactive workflow for adding a new service module to a Python FastAPI project.
Before starting, apply `engineering-python-core:python-core-standards`, then
read `../sre-python-service-standards/SKILL.md` and the related references.

## Workflow

### Step 1: Gather Requirements

Ask the developer:

1. **What does the service do?** (e.g., "clones GitHub repos", "fetches specs", "sends notifications")
2. **What is the service name?** (e.g., `repo_cloner`, `spec_fetcher`, `notification_sender`)
3. **Is it async?** (Most services in FastAPI projects are async)
4. **What external dependencies does it need?** (e.g., `httpx`, `boto3`, AWS SDK clients)
5. **Will it be a single module or a sub-package?** (sub-package if complex with multiple files)

### Step 2: Identify the Project Package

Detect the package name from the `src/` directory:

```bash
ls src/
```

### Step 3: Create the Service Module

#### Simple Service (single file)

Create `src/<pkg>/services/<service_name>.py`:

```python
"""<Service description>."""

import logging
from pathlib import Path

logger = logging.getLogger(__name__)


async def <primary_function>(arg: str) -> <ReturnType>:
    """<Brief description>.

    Args:
        arg: <Description>.

    Returns:
        <Description of return value>.

    Raises:
        <ExceptionType>: <When this happens>.
    """
    logger.info(f"<Descriptive log message>: {arg}")
    # Implementation here
    ...
```

#### Complex Service (sub-package)

When a service has multiple collaborating modules, create a sub-package:

```
services/
└── <service_name>/
    ├── __init__.py          # Public API exports
    ├── <primary>.py         # Core logic
    ├── <secondary>.py       # Supporting logic
    └── <types>.py           # Service-specific types (if needed)
```

`__init__.py` re-exports the public interface:

```python
from <pkg>.services.<service_name>.<primary> import <PrimaryClass>
from <pkg>.services.<service_name>.<types> import <ServiceState>

__all__: list[str] = ["<PrimaryClass>", "<ServiceState>"]
```

### Step 4: Define Types (if needed)

If the service needs data containers that are not Pydantic API models, use `dataclass`:

```python
"""<Service> state and types."""

from dataclasses import dataclass, field
from enum import Enum


class <Status>(Enum):
    """Status of a <process>."""

    PENDING = "pending"
    RUNNING = "running"
    COMPLETE = "complete"
    FAILED = "failed"


@dataclass
class <State>:
    """Per-<entity> execution state."""

    name: str
    status: <Status> = <Status>.PENDING
    results: list[str] = field(default_factory=list)
    error: str | None = None
```

**When to use `dataclass` vs Pydantic `BaseModel`:**

| Use Case | Type |
| --- | --- |
| API request/response schemas | Pydantic `BaseModel` |
| Settings from environment | Pydantic `BaseSettings` |
| Internal state, data containers | `dataclass` |
| Simple value objects | `dataclass` or `NamedTuple` |

### Step 5: Update Service Exports

Update `src/<pkg>/services/__init__.py` to export the new service:

```python
from <pkg>.services.<service_name> import <primary_function>

__all__: list[str] = [
    # ... existing exports ...
    "<primary_function>",
]
```

### Step 6: Wire Into the Application

If the service needs initialization at startup, add it to the lifespan in `main.py`:

```python
@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """Application lifespan — setup on startup, cleanup on shutdown."""
    result = await <service_function>(settings)
    app.state.<service_data> = result
    yield
```

If called from route handlers, inject via `Depends()` or import directly in the relevant `api/<domain>.py`.

### Step 7: Add Tests

Create `tests/unit/test_<service_name>.py`:

```python
"""Tests for <service_name> service."""

from unittest.mock import AsyncMock, patch

import pytest

from <pkg>.services.<service_name> import <primary_function>


async def test_<primary_function>_success() -> None:
    """Test <function> with valid input."""
    result = await <primary_function>("test-input")
    assert result is not None


async def test_<primary_function>_handles_error() -> None:
    """Test <function> handles errors gracefully."""
    with patch("<pkg>.services.<service_name>.<dependency>", new=AsyncMock(side_effect=Exception("fail"))):
        with pytest.raises(Exception, match="fail"):
            await <primary_function>("bad-input")
```

No `@pytest.mark.asyncio` decorator — `asyncio_mode = "auto"` handles it.

### Step 8: Add Dependencies (if needed)

If the service requires new third-party packages:

```bash
uv add <package>==<version>            # Production dependency
uv add --group dev types-<package>     # Type stubs (if available)
```

NEVER use `pip install`. Always pin exact versions.

### Step 9: Validate

Run the full check suite:

```bash
make check    # lint + typecheck + test
```

All checks must pass.

## Service Design Principles

- **No FastAPI dependency**: Services MUST NOT import from `fastapi`. They are framework-agnostic business logic.
- **Async by default**: Use `async def` for functions that do I/O (network, file system, database).
- **Logging**: Use `logging.getLogger(__name__)` — never `print()`.
- **Error handling**: Raise descriptive exceptions. Let the route handler translate to HTTP responses.
- **Type safety**: All parameters and return types annotated. Must pass `mypy --strict`.

## Related Rules

- `python-directory-structure` — where services belong
- `python-code-style` — naming and import conventions
- `python-type-checking` — mypy strict compliance
- `python-testing` — test patterns
- `python-dependency-management` — adding dependencies with uv
