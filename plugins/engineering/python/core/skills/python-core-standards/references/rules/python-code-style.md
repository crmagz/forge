---
description: Python naming conventions, import rules, docstrings, and code formatting standards
alwaysApply: true
version: 1.1.0
globs: "*.py"
---

# Python Code Style

## Formatting

All code MUST pass `ruff check` and `ruff format --check` with zero errors. Ruff replaces black, flake8, and isort as a single tool.

Configuration lives exclusively in `pyproject.toml` — never in standalone config files (`.flake8`, `setup.cfg`, `pyproject.toml [tool.black]`, etc.).

## Naming Conventions

### snake_case: Functions, Variables, Modules, Packages

```python
def create_migration() -> None: ...
def fetch_user_profile(user_id: str) -> UserProfile: ...
app_version: str = "1.0.0"
```

### PascalCase: Classes, Pydantic Models, Enums, Type Aliases

```python
class MigrationService: ...
class HealthResponse(BaseModel): ...
class Owner(StrEnum): ...
type ConnectionPool = Pool[AsyncConnection]
```

### UPPER_SNAKE_CASE: Constants

```python
MAX_RETRIES: int = 3
DEFAULT_TIMEOUT: float = 30.0
```

### Abbreviations

Capitalize only the first letter in PascalCase names:

```python
class HttpClient: ...       # correct
class AwsConfig: ...        # correct
class HTTPClient: ...       # incorrect
class AWSConfig: ...        # incorrect
```

## Import Conventions

NEVER use wildcard imports (`from module import *`). Always use explicit, named imports.

```python
# incorrect
from fastapi import *

# correct
from fastapi import APIRouter, FastAPI, HTTPException
from pydantic import BaseModel, Field
```

### Import Order (enforced by ruff `I` rules)

1. Standard library (`pathlib`, `logging`, `typing`)
2. Third-party packages (`fastapi`, `pydantic`, `httpx`)
3. Local project modules (`from package_name.models import ...`)

```python
import logging
from pathlib import Path

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from my_service.config import settings
from my_service.models.health import HealthResponse
```

## Docstring Standard

Google-style docstrings enforced via ruff `D` rules with `convention = "google"`.

Required on all public modules, functions, methods, and classes. Not required on `__init__.py`, test files, private helpers, or functions where the name and type signature make the purpose obvious.

```python
def fetch_specs(settings: Settings, *, force: bool = False) -> Path:
    """Fetch migration specs from the GitHub repository.

    Downloads spec files to the local cache directory. Skips download
    if the cache is fresh unless ``force`` is True.

    Args:
        settings: Application settings with GitHub configuration.
        force: Re-download even if cache exists.

    Returns:
        Path to the local specs cache directory.

    Raises:
        httpx.HTTPStatusError: If the GitHub API returns a non-2xx response.
    """
```

Only include `Args`, `Returns`, and `Raises` sections when non-obvious. Omit empty sections.

## Line Length

120 characters maximum, configured in `pyproject.toml`:

```toml
[tool.ruff]
line-length = 120
```

## String Formatting

Use f-strings for interpolation. Use double quotes for strings (enforced by ruff).

```python
name: str = f"migration-{app_name}-{environment}"
```

## Ruff Configuration

```toml
[tool.ruff]
target-version = "py314"
line-length = 120
src = ["src", "tests"]

[tool.ruff.lint]
select = [
    "E",   # pycodestyle errors
    "W",   # pycodestyle warnings
    "F",   # pyflakes
    "I",   # isort
    "N",   # pep8-naming
    "UP",  # pyupgrade
    "B",   # flake8-bugbear
    "SIM", # flake8-simplify
    "TCH", # flake8-type-checking
    "RUF", # ruff-specific rules
    "D",   # pydocstyle (Google convention)
]

[tool.ruff.lint.pydocstyle]
convention = "google"

[tool.ruff.lint.per-file-ignores]
"tests/**/*.py" = ["D"]
"**/__init__.py" = ["D"]
```
