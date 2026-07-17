---
name: python-add-endpoint
description: Interactive workflow for adding a new FastAPI endpoint with Pydantic request/response models, route handler, and tests to a Python service.
version: 1.1.0
---

# Add FastAPI Endpoint

Step-by-step interactive workflow for adding a new endpoint to a Python FastAPI service.
Before starting, apply `engineering-python-core:python-core-standards`, then
read `../sre-python-service-standards/SKILL.md` and the related references.

## Workflow

### Step 1: Gather Requirements

Ask the developer:

1. **What is the endpoint?** (e.g., `POST /migrations`, `GET /items/{item_id}`)
   - HTTP method: GET, POST, PUT, PATCH, DELETE
   - Path with any path parameters
2. **What domain does it belong to?** (e.g., migrations, users, items)
   - Determines which router file and model file to use or create
3. **Does it accept a request body?** (POST/PUT/PATCH)
   - If yes, what fields?
4. **What does it return?**
   - Response fields and their types
5. **Status code?** (default: 200 for GET, 201 for POST create, 202 for async accept)

### Step 2: Identify the Project Package

Detect the package name from the `src/` directory:

```bash
ls src/
```

The package name is the directory under `src/` (e.g., `src/msp_migration_agent/` → `msp_migration_agent`).

### Step 3: Create or Update Pydantic Models

**If the domain model file exists** (`src/<pkg>/models/<domain>.py`), add new models to it.

**If not**, create a new model file following this pattern:

```python
"""<Domain> request and response models."""

from pydantic import BaseModel, Field


class <Name>Request(BaseModel):
    """Request model for the <endpoint> endpoint."""

    field_name: str = Field(description="Description of the field", examples=["example-value"])
    optional_field: int | None = Field(default=None, description="Optional field description")


class <Name>Response(BaseModel):
    """Response model for the <endpoint> endpoint."""

    status: str = Field(default="success", examples=["success"])
    field_name: str = Field(description="Description of the field")
```

**Model Rules (enforced — do not skip):**

- Every field MUST use `Field()` with a `description` parameter
- Use `examples` on string and numeric fields to show expected format
- Use `pattern` for strings with known formats (version strings, IDs, etc.)
- Use `ge`/`le` for bounded numeric fields
- Use `default_factory=list` for mutable defaults, never `default=[]`
- Use `str | None` syntax, not `Optional[str]`
- Use `StrEnum` for constrained string values
- Every model MUST have a class docstring

**Then update `models/__init__.py`** to export the new models:

```python
from <pkg>.models.<domain> import <Name>Request, <Name>Response

__all__: list[str] = [
    # ... existing exports ...
    "<Name>Request",
    "<Name>Response",
]
```

### Step 4: Create or Update the Route Handler

**If the domain router file exists** (`src/<pkg>/api/<domain>.py`), add the new endpoint.

**If not**, create a new router file:

```python
"""<Domain> endpoints."""

from fastapi import APIRouter

from <pkg>.models.<domain> import <Name>Request, <Name>Response

router: APIRouter = APIRouter()


@router.post("/<path>", status_code=201)
async def create_<resource>(request: <Name>Request) -> <Name>Response:
    """<Brief description of what this endpoint does>."""
    # Implementation here
    return <Name>Response(...)
```

**Route Handler Rules (enforced — do not skip):**

- ALL handlers MUST be `async def`
- ALL handlers MUST have a typed return annotation matching a Pydantic model
- ALL handlers MUST have a Google-style docstring
- Request bodies MUST be Pydantic models, never raw `dict`
- Path parameters use `Path()`, query parameters use `Query()` from FastAPI
- Business logic belongs in `services/`, not in the handler
- Use `HTTPException` for error responses

**Then update `api/__init__.py`** to export the new router:

```python
from <pkg>.api.<domain> import router as <domain>_router

__all__: list[str] = [
    # ... existing exports ...
    "<domain>_router",
]
```

### Step 5: Register the Router

If this is a new router, add it to `main.py`:

```python
from <pkg>.api import <domain>_router

app.include_router(<domain>_router)
```

### Step 6: Add Tests

Create or update the test file at `tests/unit/test_<domain>.py`:

```python
"""Tests for <domain> endpoints."""

from httpx import AsyncClient


async def test_<endpoint_name>_success(client: AsyncClient) -> None:
    """Test <endpoint> returns expected response."""
    response = await client.post(
        "/<path>",
        json={"field_name": "value"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["status"] == "success"
    assert "field_name" in data


async def test_<endpoint_name>_validation_error(client: AsyncClient) -> None:
    """Test <endpoint> rejects invalid input."""
    response = await client.post("/<path>", json={})
    assert response.status_code == 422
```

**Test Rules:**

- At minimum: one success test and one validation error test per endpoint
- All test functions return `-> None`
- Use the shared `client` fixture from `conftest.py`
- No `@pytest.mark.asyncio` decorator — `asyncio_mode = "auto"` handles it
- Test file names match: `test_<domain>.py`

### Step 7: Validate

Run the full check suite:

```bash
make check
```

All checks (lint + typecheck + test) must pass before the endpoint is considered complete.

## Related Rules

- `python-directory-structure` — where files belong
- `python-fastapi-patterns` — endpoint and router conventions
- `python-pydantic-models` — model field requirements
- `python-code-style` — naming and import conventions
- `python-type-checking` — mypy strict compliance
- `python-testing` — test organization and patterns
