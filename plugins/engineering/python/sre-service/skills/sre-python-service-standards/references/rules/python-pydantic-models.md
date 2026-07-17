---
description: Pydantic v2 model standards with Field validators, BaseSettings, enums, and schema conventions
alwaysApply: true
version: 1.1.0
globs: "*.py"
---

# Python Pydantic Models

Pydantic v2 is used for all data validation, serialization, and settings management.

## Field() Validators Are Required

Every field on a public-facing request or response model MUST use `Field()` with at least a `description`:

```python
from pydantic import BaseModel, Field


class MigrationRequest(BaseModel):
    """Request to trigger a migration run."""

    app_name: str = Field(description="Target application repository name", examples=["project-billing-api"])
    owner: Owner = Field(description="Team owner — determines config repo and namespace")
    ticket_id: str = Field(description="Work-tracking ticket ID for commits", examples=["PROJ-2423"])
    dry_run: bool = Field(default=True, description="If true, no API calls are made")
```

### Field() Usage Guidelines

| Parameter | When to Use |
| --- | --- |
| `description` | ALWAYS on public models |
| `default` | When a sensible default exists |
| `examples` | On string/numeric fields to show expected format |
| `pattern` | On strings with a known format (versions, IDs) |
| `ge`, `le`, `gt`, `lt` | On numeric fields with bounds |
| `min_length`, `max_length` | On strings with length constraints |
| `default_factory` | For mutable defaults (`list`, `dict`) |

```python
class Settings(BaseSettings):
    """Application settings."""

    app_version: str = Field(default="0.1.0", pattern=r"^\d+\.\d+\.\d+$")
    port: int = Field(default=8000, ge=1, le=65535, description="Server port")
    tags: list[str] = Field(default_factory=list, description="Resource tags")
```

## Model Organization

Models live in `src/<package_name>/models/`, one file per domain. Export all public models from `__init__.py`:

```python
from my_service.models.health import HealthResponse, ReadyResponse
from my_service.models.migration import MigrationRequest, MigrationResponse

__all__: list[str] = ["HealthResponse", "ReadyResponse", "MigrationRequest", "MigrationResponse"]
```

## Enums

Use `StrEnum` for string-valued enumerations. Use `Annotated` with `Field` when extra metadata is needed:

```python
from enum import StrEnum
from typing import Annotated

from pydantic import BaseModel, Field


class Owner(StrEnum):
    """Valid team owners from config."""

    PLATFORM = "platform"
    PLATFORM = "platform"
    APPLICATIONS = "applications"


class MigrationRequest(BaseModel):
    owner: Annotated[Owner, Field(description="Team owner")]
```

## BaseSettings for Configuration

Use `pydantic-settings` `BaseSettings` for all environment-based configuration:

```python
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application configuration loaded from environment variables."""

    model_config = SettingsConfigDict(env_prefix="APP_")

    app_name: str = Field(default="my-service", description="Application name")
    app_version: str = Field(default="0.1.0", pattern=r"^\d+\.\d+\.\d+$")
    debug: bool = Field(default=False, description="Enable debug mode")
    host: str = Field(default="0.0.0.0", description="Server bind address")
    port: int = Field(default=8000, ge=1, le=65535, description="Server port")
    cors_origins: list[str] = Field(default_factory=lambda: ["*"], description="Allowed CORS origins")


settings: Settings = Settings()
```

Key rules:

- ALWAYS use `SettingsConfigDict(env_prefix="APP_")` for namespace isolation
- ALWAYS use `Field()` with descriptions on settings
- Export a module-level singleton: `settings: Settings = Settings()`
- Never instantiate `Settings()` more than once at module scope

## Anti-patterns

- Do NOT use `dict` returns from endpoints — always use a Pydantic model
- Do NOT use `Any` in model fields — use specific types or unions
- Do NOT use `validator` (v1 API) — use `field_validator` or `model_validator` (v2 API)
- Do NOT mix request and response models — create separate models even if fields overlap
- Do NOT use `class Config:` — use `model_config = SettingsConfigDict(...)` (v2 API)

For type annotation standards (native types, `str | None`, `TYPE_CHECKING` guards), see `python-type-checking`.
