# Node.js Build Example

Shows how a consumer repo uses Forge's Node.js semantic build workflow.

## Files

- `build-node.yml` — place in `.github/workflows/`

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `environment` | yes | — | GitHub environment for protection rules and publish credentials |
| `node-version` | no | `22` | Node.js version |
| `container-registry` | no | `ecr` | `ecr`, `ghcr`, or `none` |
| `ecr-repository` | no | — | ECR repo name; required to publish with `ecr` |
| `ghcr-repository` | no | — | Lowercase `owner/image` path; required to publish with `ghcr` |
| `dockerfile` | no | `Dockerfile` | Dockerfile path relative to working-directory |
| `platforms` | no | `linux/arm64` | Docker target platforms |
| `tag-prefix` | no | — | Monorepo tag prefix (e.g., `mypackage/`) |
| `working-directory` | no | `.` | Path to Node.js project root |
| `codeartifact-domain` | no | — | CodeArtifact domain (omit to skip npm publish) |
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
├── package.json            # Must have version field
├── package-lock.json
├── Dockerfile              # Required when an image registry is configured
├── src/
└── tests/
```

## npm Scripts

The workflow runs these scripts via `npm run <script> --if-present`:

- `build` — compile/transpile
- `lint` — linter
- `typecheck` — type checker
- `test` — test suite

## Container Registries

ECR remains the default for existing callers: set `ecr-repository` and grant
`id-token: write` for the environment’s AWS role. To publish to GHCR instead,
set `container-registry: ghcr`, provide `ghcr-repository: owner/image`, and
grant the caller `packages: write`. GHCR uses the ephemeral `GITHUB_TOKEN`; do
not provide a personal access token. `container-registry: none` disables image
publication.
