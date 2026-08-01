# Python Build Example

Shows how a consumer repo uses Forge's Python semantic build workflow.

## Files

- `build-python.yml` — place in `.github/workflows/`

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `environment` | yes | — | GitHub environment for protection rules and publish credentials |
| `python-version` | no | `3.12` | Python version |
| `container-registry` | no | `ecr` | `ecr`, `ghcr`, or `none` |
| `ecr-repository` | no | — | ECR repo name; required to publish with `ecr` |
| `ghcr-repository` | no | — | Lowercase `owner/image` path; required to publish with `ghcr` |
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
├── Dockerfile              # Required when an image registry is configured
├── src/
│   └── mypackage/
└── tests/
```

## Container Registries

ECR remains the default for existing callers: set `ecr-repository` and grant
`id-token: write` for the environment’s AWS role. To publish to GHCR instead,
set `container-registry: ghcr`, provide `ghcr-repository: owner/image`, and
grant the caller `packages: write`. GHCR uses the ephemeral `GITHUB_TOKEN`; do
not provide a personal access token. `container-registry: none` disables image
publication.
