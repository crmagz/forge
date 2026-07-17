---
description: Mypy strict mode configuration, type annotation requirements, generics, Protocol, and advanced typing patterns
alwaysApply: true
version: 1.1.0
globs: "*.py"
---

# Python Type Checking

Mypy in strict mode is required for all Python projects. All code MUST pass `mypy --strict` with zero errors.

## Configuration

All mypy configuration lives in `pyproject.toml`:

```toml
[tool.mypy]
strict = true
python_version = "3.14"
mypy_path = "src"
packages = ["<package_name>"]
plugins = ["pydantic.mypy"]

[tool.pydantic-mypy]
init_forbid_extra = true
init_typed = true
warn_required_dynamic_aliases = true

[[tool.mypy.overrides]]
module = ["tests.*"]
disallow_untyped_decorators = false
```

Key settings:

- `strict = true`: Enables all strict checks (no `Any`, no untyped defs, etc.)
- `mypy_path = "src"`: Resolves imports from the `src/` layout
- `plugins = ["pydantic.mypy"]`: Enables Pydantic model type checking

Pydantic-mypy settings:

- `init_forbid_extra = true`: Error on unknown keyword arguments in model constructors
- `init_typed = true`: Use field types for `__init__` signature instead of `Any`
- `warn_required_dynamic_aliases = true`: Warn when `alias` is used on a required field without a `Field(alias=...)` default — catches alias misconfigurations

Test override:

- `disallow_untyped_decorators = false` for `tests.*`: Allows third-party pytest decorators and fixtures that lack type stubs without requiring `# type: ignore` on every decorated test

## Type Annotation Requirements

### All Functions Must Be Typed

Every function and method MUST have type annotations for all parameters and the return type:

```python
# correct
async def fetch_specs(settings: Settings, *, force: bool = False) -> Path: ...
def create_client(token: str, timeout: float = 30.0) -> AsyncClient: ...

# incorrect — missing return type
async def fetch_specs(settings: Settings, force: bool = False): ...

# incorrect — missing parameter type
def create_client(token, timeout=30.0) -> AsyncClient: ...
```

### Variables With Non-obvious Types

Annotate variables when the type is not obvious from the assignment:

```python
# annotation helpful — type not obvious
_migrations: dict[str, MigrationResponse] = {}
_tasks: set[asyncio.Task[None]] = set()
router: APIRouter = APIRouter()
app: FastAPI = FastAPI(...)

# annotation not needed — type is obvious
name = "migration-agent"
count = 0
items = [1, 2, 3]
```

### Use Native Python 3.14 Types

Use built-in generic types — never import from `typing` for generics:

```python
# correct
def get_items(ids: list[str]) -> dict[str, Item | None]: ...
def process(data: tuple[str, int, float]) -> set[str]: ...

# incorrect
from typing import Dict, List, Optional, Set, Tuple
def get_items(ids: List[str]) -> Dict[str, Optional[Item]]: ...
```

### Union Types

Use `X | Y` syntax, not `Union[X, Y]`:

```python
# correct
error: str | None = None
result: Item | ErrorDetail = ...

# incorrect
from typing import Optional, Union
error: Optional[str] = None
result: Union[Item, ErrorDetail] = ...
```

### TYPE_CHECKING Guard

Imports used only in type annotations go behind `TYPE_CHECKING`:

```python
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from collections.abc import AsyncIterator
    from httpx import AsyncClient
```

This avoids runtime import overhead and circular dependency issues.

## Generics — Use Python 3.12+ Syntax

Use the `[T]` type parameter syntax introduced in Python 3.12. Do NOT use `TypeVar`:

```python
# correct — Python 3.12+ syntax
def first[T](items: list[T]) -> T | None:
    return items[0] if items else None


async def fetch_all[T](ids: list[str], loader: Callable[[str], Awaitable[T]]) -> list[T]:
    return [await loader(id) for id in ids]


class Registry[K, V]:
    def __init__(self) -> None:
        self._store: dict[K, V] = {}

    def get(self, key: K) -> V | None:
        return self._store.get(key)


# incorrect — legacy TypeVar pattern
from typing import TypeVar
T = TypeVar("T")
def first(items: list[T]) -> T | None: ...
```

Use `type` statement for type aliases:

```python
# correct — Python 3.12+ type alias
type JsonDict = dict[str, object]
type Handler[T] = Callable[[Request], Awaitable[T]]

# incorrect — legacy alias
from typing import TypeAlias
JsonDict: TypeAlias = dict[str, object]
```

## Protocol for Structural Typing

Use `Protocol` instead of ABC for service interfaces. Protocol provides structural subtyping (duck typing with type safety) and plays better with mypy strict:

```python
from typing import Protocol


class RepoCloner(Protocol):
    """Interface for cloning repositories."""

    async def clone(self, repo: str, dest: Path) -> Path: ...


class SpecFetcher(Protocol):
    """Interface for fetching migration specs."""

    async def fetch(self, settings: Settings) -> Path: ...
```

Any class that implements the matching method signatures satisfies the Protocol without explicit inheritance:

```python
class GitHubRepoCloner:
    """Clones repos via GitHub API — satisfies RepoCloner protocol."""

    async def clone(self, repo: str, dest: Path) -> Path:
        # implementation
        ...
```

Use Protocol when:
- Defining service interfaces for dependency injection
- Typing callback parameters that accept multiple implementations
- Replacing ABC-based abstract classes in typed code

Use ABC only when you need shared implementation (concrete methods on the base class).

## TypedDict for Structured Dicts

Use `TypedDict` when working with JSON-like data that doesn't warrant a Pydantic model (e.g., internal config, API client responses before parsing):

```python
from typing import TypedDict


class PhaseConfig(TypedDict):
    """Configuration for a migration phase."""

    model_tier: str
    max_turns: int
    budget_usd: float


class PartialPhaseConfig(TypedDict, total=False):
    """Optional overrides for phase configuration."""

    max_turns: int
    budget_usd: float
```

Do NOT use `dict[str, Any]` when the shape is known — use `TypedDict` instead.

## Annotated Types

Use `Annotated` to combine type info with metadata. This is the standard pattern for FastAPI dependency injection and Pydantic field constraints:

```python
from typing import Annotated

from fastapi import Depends
from pydantic import Field

from my_service.models.migration import Owner

# FastAPI dependency injection
CurrentUser = Annotated[User, Depends(get_current_user)]

# Pydantic field with constraints
OwnerField = Annotated[Owner, Field(description="Team owner")]


@router.get("/profile")
async def get_profile(user: CurrentUser) -> ProfileResponse: ...
```

## Function Overloads

Use `@overload` when a function returns different types based on input:

```python
from typing import overload


@overload
async def get_migration(xtid: str, *, raw: Literal[True]) -> dict[str, object]: ...
@overload
async def get_migration(xtid: str, *, raw: Literal[False] = ...) -> MigrationResponse: ...


async def get_migration(xtid: str, *, raw: bool = False) -> dict[str, object] | MigrationResponse:
    data = await _fetch(xtid)
    if raw:
        return data
    return MigrationResponse.model_validate(data)
```

Use `@overload` when:
- Return type depends on a flag parameter (`raw`, `as_dict`, etc.)
- Return type depends on the number or type of arguments
- A `Union` return type would force callers to narrow unnecessarily

## Debugging with reveal_type

Use `reveal_type()` during development to inspect mypy's inferred types:

```python
result = await fetch_specs(settings)
reveal_type(result)  # mypy output: Revealed type is "pathlib.Path"
```

Remove `reveal_type()` calls before committing — they are for local debugging only.

## Handling Third-party Libraries Without Type Stubs

If a third-party library has no type stubs, install the stubs package or add a per-module override:

```toml
# pyproject.toml — only as a last resort
[[tool.mypy.overrides]]
module = ["some_untyped_lib.*"]
ignore_missing_imports = true
```

Prefer installing stubs (e.g., `types-pyyaml`, `types-requests`) over ignoring.

## Running Type Checks

```bash
uv run mypy src/        # Check application code
```

Type checking is included in the `make check` target and runs in CI.

## Anti-patterns

- Do NOT use `# type: ignore` without a specific error code: use `# type: ignore[assignment]`
- Do NOT use `Any` as a return type or parameter type — use specific types or generics
- Do NOT disable strict mode for convenience — fix the type errors instead
- Do NOT use `cast()` to silence errors unless the runtime type is genuinely known and unprovable by mypy
- Do NOT use `TypeVar` — use Python 3.12+ `[T]` syntax on functions and classes
- Do NOT use `ABC` with `@abstractmethod` for interfaces — use `Protocol` for structural typing
- Do NOT use `dict[str, Any]` when the dict shape is known — use `TypedDict`
- Do NOT use `TypeAlias` from `typing` — use the `type` statement
