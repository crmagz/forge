---
description: Pytest conventions, async testing patterns, fixtures, parametrize, coverage, and test directory organization
alwaysApply: true
version: 1.2.0
globs: "*.py"
---

# Python Testing

Pytest is the test runner. `pytest-asyncio` enables async test support. `httpx` provides the async test client.

## Configuration

All test configuration lives in `pyproject.toml`:

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"
markers = [
    "slow: marks tests as slow (deselect with '-m \"not slow\"')",
    "integration: marks integration tests requiring external services",
]

[tool.coverage.run]
source = ["src"]
branch = true

[tool.coverage.report]
show_missing = true
fail_under = 80
```

`asyncio_mode = "auto"` means all `async def` tests run automatically without needing `@pytest.mark.asyncio`. Do NOT add the decorator — the config handles it.

## Test Directory Structure

```
tests/
├── __init__.py
├── conftest.py              # Shared fixtures (async client, factories)
├── unit/
│   ├── __init__.py
│   ├── conftest.py          # Unit-specific fixtures (mocks, overrides)
│   └── test_<module>.py     # Unit tests
└── integration/
    ├── __init__.py
    ├── conftest.py          # Integration-specific fixtures (real clients, containers)
    └── test_<module>.py     # Integration tests
```

Every test directory MUST have an `__init__.py` file.

### What Goes Where

| Fixture | Location |
| --- | --- |
| Async HTTP client (`client`) | `tests/conftest.py` |
| Data factories (`make_migration_request`) | `tests/conftest.py` |
| Mocked service dependencies | `tests/unit/conftest.py` |
| Settings overrides for unit isolation | `tests/unit/conftest.py` |
| Real database connections, containers | `tests/integration/conftest.py` |
| External service stubs (e.g., httpx mock transport) | `tests/integration/conftest.py` |

## Shared Fixtures — conftest.py

The root `conftest.py` provides the async HTTP test client and shared factories:

```python
from collections.abc import AsyncIterator, Callable

import pytest_asyncio
from httpx import ASGITransport, AsyncClient

from my_service.main import app
from my_service.models.migration import MigrationRequest


@pytest_asyncio.fixture
async def client() -> AsyncIterator[AsyncClient]:
    """Async HTTP client for testing FastAPI endpoints."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.fixture
def make_migration_request() -> Callable[..., MigrationRequest]:
    """Factory fixture for building MigrationRequest with sensible defaults."""

    def _factory(**overrides: object) -> MigrationRequest:
        defaults: dict[str, object] = {
            "app_name": "project-test-api",
            "owner": "platform",
            "ticket_id": "PROJ-9999",
            "dry_run": True,
        }
        return MigrationRequest(**(defaults | overrides))

    return _factory
```

Key rules:

- Use `ASGITransport` + `AsyncClient` from `httpx` — never `TestClient` from `starlette`
- Fixtures that need cleanup use `yield`, not `return`
- Factory fixtures return a callable that builds objects with overridable defaults

## Writing Tests

### Endpoint Tests

```python
from httpx import AsyncClient


async def test_health(client: AsyncClient) -> None:
    response = await client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "app_name" in data
    assert "version" in data


async def test_readyz(client: AsyncClient) -> None:
    response = await client.get("/readyz")
    assert response.status_code == 200
    assert response.json()["status"] == "ready"
```

No `@pytest.mark.asyncio` decorator — `asyncio_mode = "auto"` handles it.

### Parametrized Tests

Use `@pytest.mark.parametrize` to test multiple inputs without duplicating test functions:

```python
import pytest
from httpx import AsyncClient


@pytest.mark.parametrize(
    ("field", "value", "expected_status"),
    [
        ("app_name", "", 422),
        ("owner", "invalid-team", 422),
        ("ticket_id", "", 422),
    ],
)
async def test_create_migration_rejects_invalid(
    client: AsyncClient,
    field: str,
    value: str,
    expected_status: int,
) -> None:
    payload = {"app_name": "test", "owner": "platform", "ticket_id": "X-1"}
    payload[field] = value
    response = await client.post("/migrations", json=payload)
    assert response.status_code == expected_status
```

Use parametrize when testing:
- Multiple invalid inputs on a validation endpoint
- Multiple status codes or response shapes
- Boundary values (min, max, edge cases)

### Exception Testing

Use `pytest.raises` for testing expected exceptions:

```python
import pytest

from my_service.services.validator import validate_config


async def test_validate_config_rejects_missing_field() -> None:
    with pytest.raises(ValueError, match="owner is required"):
        await validate_config({"app_name": "test"})
```

### Test Naming

- Test files: `test_<module>.py` matching the module under test
- Test functions: `test_<behavior>` describing expected behavior, not implementation
- Use descriptive names: `test_health_returns_200`, `test_create_migration_rejects_invalid_owner`

### Assertions

Use plain `assert` statements — never `self.assertEqual` or `unittest` patterns:

```python
# correct
assert response.status_code == 200
assert data["status"] == "healthy"
assert "error" not in data

# incorrect
self.assertEqual(response.status_code, 200)
```

## Mocking

Use `unittest.mock.patch` and `AsyncMock` for mocking.

### Patch Where It's Used, Not Where It's Defined

Always patch the name as it appears in the module under test, not where the original function is defined:

```python
from unittest.mock import AsyncMock, patch


# correct — patch in the module that imports it
async def test_create_migration(client: AsyncClient) -> None:
    mock_result = MigrationAccepted(xtid="abc-123", app_name="test", status="accepted")
    with patch("my_service.api.migrations.migration_service.create", new=AsyncMock(return_value=mock_result)):
        response = await client.post("/migrations", json={...})
        assert response.status_code == 202

# incorrect — patching the source module doesn't affect the import in api.migrations
with patch("my_service.services.migration.MigrationService.create", ...):
    ...
```

### Settings Overrides

Override `BaseSettings` values in tests using environment variable patching. Place reusable overrides in `tests/unit/conftest.py`:

```python
import os
from unittest.mock import patch

import pytest


@pytest.fixture
def test_env() -> None:
    """Override settings for unit test isolation."""
    with patch.dict(os.environ, {"APP_DEBUG": "false", "APP_PORT": "9999"}):
        yield
```

## Fixture Scoping

Control fixture lifetime with the `scope` parameter:

```python
import pytest_asyncio


@pytest_asyncio.fixture(scope="session")
async def db_connection() -> AsyncIterator[Connection]:
    """Shared database connection for the entire test session."""
    conn = await create_connection()
    yield conn
    await conn.close()


@pytest_asyncio.fixture(scope="module")
async def seeded_db(db_connection: Connection) -> AsyncIterator[None]:
    """Seed test data once per module."""
    await db_connection.execute("INSERT INTO ...")
    yield
    await db_connection.execute("DELETE FROM ...")
```

| Scope | Lifetime | Use For |
| --- | --- | --- |
| `function` (default) | Each test | HTTP client, per-test mocks |
| `module` | Per test file | Test data seeding, module-level setup |
| `session` | Entire test run | Database connections, container startup |

Use broader scopes only for expensive setup. Default to `function` scope.

## Custom Markers

Register markers in `pyproject.toml` and use them for selective test execution:

```python
import pytest


@pytest.mark.slow
async def test_full_migration_pipeline(client: AsyncClient) -> None:
    """End-to-end migration test — takes 30+ seconds."""
    ...


@pytest.mark.integration
async def test_clone_repo(tmp_path: Path) -> None:
    """Requires GitHub network access."""
    ...
```

```bash
uv run pytest -m "not slow"           # Skip slow tests (PR builds)
uv run pytest -m "not integration"    # Unit tests only
uv run pytest -m "slow or integration" # Full suite (merge builds)
```

## Type Annotations on Tests

All test functions MUST have return type `-> None`:

```python
async def test_health(client: AsyncClient) -> None: ...
def test_config_defaults() -> None: ...
```

## Running Tests

```bash
uv run pytest                         # Run all tests
uv run pytest tests/unit/             # Run unit tests only
uv run pytest tests/integration/      # Run integration tests only
uv run pytest -x                      # Stop on first failure
uv run pytest -v                      # Verbose output
uv run pytest --cov                   # Run with coverage
uv run pytest -m "not slow"           # Exclude slow tests
```

## Test Coverage

Add `pytest-cov` to dev dependencies:

```toml
[dependency-groups]
dev = [
    # ... existing deps ...
    "pytest-cov>=6.0",
]
```

Makefile target:

```makefile
coverage:        ## Run tests with coverage report
	uv run pytest --cov --cov-report=term-missing
```

Coverage thresholds are enforced via `[tool.coverage.report] fail_under` in `pyproject.toml`. CI runs `uv run pytest --cov` and fails if coverage drops below the threshold.

## Test Coverage Expectations

- New features: unit tests covering the happy path and key error cases
- Bug fixes: regression test that would have caught the bug
- Refactors: existing tests must pass, add edge case tests if missing
- Endpoint additions: at minimum, test status code and response shape
