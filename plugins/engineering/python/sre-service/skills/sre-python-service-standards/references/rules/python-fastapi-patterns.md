---
description: FastAPI conventions for routers, endpoints, dependency injection, middleware, SSE, and application structure
alwaysApply: true
version: 1.2.0
globs: "*.py"
---

# Python FastAPI Patterns

FastAPI is the default web framework for all Python services.

## Application Entry Point

`main.py` initializes the FastAPI app, registers routers, middleware, exception handlers, and defines the lifespan:

```python
"""my_service application entry point."""

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from my_service.api import health_router
from my_service.config import settings
from my_service.errors import register_exception_handlers


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """Application lifespan — setup on startup, cleanup on shutdown."""
    # startup logic here
    yield
    # shutdown logic here


app: FastAPI = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    debug=settings.debug,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)

register_exception_handlers(app)
app.include_router(health_router)
```

Key rules:

- Use `lifespan` context manager, NOT deprecated `@app.on_event("startup")`
- Type-annotate the `app` variable: `app: FastAPI = FastAPI(...)`
- Wire settings from `config.py` (see `python-pydantic-models`), never hardcode values
- For internal services that should not expose OpenAPI docs, set `openapi_url=None`
- Always use explicit HTTP methods in `allow_methods` — never `["*"]`. List only the methods your API actually serves (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`)
- Always use explicit headers in `allow_headers` — never `["*"]`. Start with `Authorization` and `Content-Type`; add only what clients require

## Router Organization

Each domain gets its own router file in `api/`. Export routers via `api/__init__.py`:

```python
# src/<package_name>/api/__init__.py
from my_service.api.health import router as health_router

__all__: list[str] = ["health_router"]
```

## Required Endpoints

Every service MUST include `/health` and `/readyz` out of the box:

```python
"""Health and readiness probe endpoints."""

from fastapi import APIRouter

from my_service.config import settings
from my_service.models.health import HealthResponse, ReadyResponse

router: APIRouter = APIRouter()


@router.get("/health")
async def health() -> HealthResponse:
    """Return application health status, name, and version."""
    return HealthResponse(app_name=settings.app_name, version=settings.app_version)


@router.get("/readyz")
async def readyz() -> ReadyResponse:
    """Return readiness status for orchestrator probes."""
    return ReadyResponse()
```

Health and readiness models:

```python
from pydantic import BaseModel, Field

class HealthResponse(BaseModel):
    """Response model for the ``/health`` endpoint."""
    status: str = Field(default="healthy", examples=["healthy", "degraded"])
    app_name: str = Field(description="The application name")
    version: str = Field(pattern=r"^\d+\.\d+\.\d+$", examples=["0.1.0"])

class ReadyResponse(BaseModel):
    """Response model for the ``/readyz`` endpoint."""
    status: str = Field(default="ready", examples=["ready"])
```

## Endpoint Conventions

- ALL handlers MUST be `async def`
- ALL handlers MUST have a typed return annotation matching a Pydantic model
- ALL handlers MUST have a Google-style docstring
- Request bodies MUST be Pydantic models, never raw `dict`
- Use `Path()` / `Query()` from FastAPI for parameter validation

```python
from fastapi import APIRouter, Path, Query

@router.get("/items/{item_id}")
async def get_item(
    item_id: str = Path(description="The item identifier"),
    include_details: bool = Query(default=False, description="Include full details"),
) -> ItemResponse: ...
```

### Response Model Configuration

Use `responses` for multi-status OpenAPI docs. Use `response_model_exclude_unset=True` when clients should only receive explicitly set fields:

```python
@router.get(
    "/migrations/{xtid}",
    responses={404: {"model": ErrorResponse, "description": "Not found"}},
    response_model_exclude_unset=True,
)
async def get_migration(xtid: str) -> MigrationResponse: ...
```

### Strict Content-Type Validation

FastAPI 0.135.1+ validates JSON `Content-Type` headers by default. Disable per-endpoint for non-standard clients:

```python
@router.post("/webhooks", strict_content_type=False)
async def receive_webhook(request: WebhookPayload) -> WebhookAck: ...
```

## Error Handling

Use `HTTPException` for simple errors. For consistent structured error payloads, define a base exception and register a handler:

```python
# src/<package_name>/models/error.py
from pydantic import BaseModel, Field

class ErrorResponse(BaseModel):
    """Standard error response returned by all endpoints."""
    error: str = Field(description="Machine-readable error code", examples=["not_found"])
    detail: str = Field(description="Human-readable error message")
    status_code: int = Field(description="HTTP status code", examples=[404])
```

```python
# src/<package_name>/errors.py
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from my_service.models.error import ErrorResponse


class ServiceError(Exception):
    """Base exception for application-level errors."""
    def __init__(self, error: str, detail: str, status_code: int = 500) -> None:
        self.error = error
        self.detail = detail
        self.status_code = status_code


def register_exception_handlers(app: FastAPI) -> None:
    """Register custom exception handlers on the FastAPI app."""
    @app.exception_handler(ServiceError)
    async def service_error_handler(request: Request, exc: ServiceError) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content=ErrorResponse(
                error=exc.error, detail=exc.detail, status_code=exc.status_code,
            ).model_dump(),
        )
```

## Dependency Injection

Use `Depends()` to inject services, auth, and shared resources into route handlers:

```python
import hmac

from fastapi import APIRouter, Depends, Header, HTTPException

from my_service.services.migration import MigrationService


def get_migration_service() -> MigrationService:
    """Provide a MigrationService instance."""
    return MigrationService()


async def verify_api_key(x_api_key: str = Header()) -> str:
    """Validate the API key from request headers."""
    if not hmac.compare_digest(x_api_key, settings.api_key):
        raise HTTPException(status_code=401, detail="Invalid API key")
    return x_api_key


@router.post("/migrations", status_code=202)
async def create_migration(
    request: MigrationRequest,
    service: MigrationService = Depends(get_migration_service),
) -> MigrationAccepted:
    """Accept a migration request."""
    return await service.create(request)
```

Apply dependencies to all endpoints in a router with `dependencies=`:

```python
router: APIRouter = APIRouter(prefix="/admin", dependencies=[Depends(verify_api_key)])
```

Route handlers MUST delegate business logic to services — do NOT put business logic in handlers.

## Middleware

CORS middleware is shown in the entry point example above. For request logging:

```python
import logging
import time

from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import Response

logger = logging.getLogger(__name__)


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """Log method, path, status, and duration for every request."""
    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> Response:
        start = time.monotonic()
        response = await call_next(request)
        duration_ms = (time.monotonic() - start) * 1000
        logger.info(f"{request.method} {request.url.path} {response.status_code} {duration_ms:.1f}ms")
        return response
```

## Background Tasks

Use `BackgroundTasks` for fire-and-forget work after returning a response (e.g., 202 Accepted patterns):

```python
from fastapi import BackgroundTasks

@router.post("/migrations", status_code=202)
async def create_migration(
    request: MigrationRequest,
    background_tasks: BackgroundTasks,
) -> MigrationAccepted:
    """Accept a migration request and start processing."""
    xtid = generate_xtid()
    background_tasks.add_task(_run_migration, xtid, request)
    return MigrationAccepted(xtid=xtid, app_name=request.app_name)
```

For long-running tasks that need cancellation or progress tracking, use `asyncio.create_task()` with state management instead.

## Server-Sent Events (SSE)

FastAPI 0.135.0+ includes native SSE via `fastapi.sse.EventSourceResponse`. Use for streaming responses:

```python
from collections.abc import AsyncIterable

from fastapi.sse import EventSourceResponse


async def _stream_events(xtid: str) -> AsyncIterable[dict[str, str]]:
    """Yield SSE events as the migration progresses."""
    async for event in watch_migration(xtid):
        yield {"event": event.type, "data": event.payload}


@router.get("/migrations/{xtid}/stream")
async def stream_migration(xtid: str) -> EventSourceResponse:
    """Stream migration progress as server-sent events."""
    return EventSourceResponse(_stream_events(xtid))
```

- Use `fastapi.sse.EventSourceResponse`, not third-party `sse-starlette`
- Generator MUST yield `dict` with `data` (required) and optionally `event`, `id`, `retry`
