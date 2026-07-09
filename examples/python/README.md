# Python Build Example

Shows how a consumer repo uses Forge's Python semantic build workflow.

## Files

- `build-python.yml` — place in `.github/workflows/`

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `environment` | yes | — | GitHub environment with AWS OIDC |
| `python-version` | no | `3.12` | Python version |
| `ecr-repository` | no | — | ECR repo name (omit to skip Docker) |
| `dockerfile` | no | `Dockerfile` | Dockerfile path relative to working-directory |
| `platforms` | no | `linux/arm64` | Docker target platforms |
| `tag-prefix` | no | — | Monorepo tag prefix (e.g., `mypackage/`) |
| `working-directory` | no | `.` | Path to Python project root |
| `codeartifact-domain` | no | — | CodeArtifact domain (omit to skip publish) |
| `codeartifact-owner` | no | — | CodeArtifact domain owner (AWS account ID) |
| `codeartifact-repository` | no | — | CodeArtifact repository name |

## Build Types

| Type | Trigger | Publishes | Tags |
|------|---------|-----------|------|
| `pr` | Pull request | No | No |
| `dev` | Push to main (no version bump) | Docker with `dev-<sha>` tag | No |
| `release` | Push to main (version bump detected) | Docker with `X.Y.Z` + `latest` tags | Yes |

## Expected Project Structure

```
├── pyproject.toml          # Must have version field
├── uv.lock
├── Dockerfile              # Required if ecr-repository is set
├── src/
│   └── mypackage/
└── tests/
```
