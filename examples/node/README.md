# Node.js Build Example

Shows how a consumer repo uses Forge's Node.js semantic build workflow.

## Files

- `build-node.yml` — place in `.github/workflows/`

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `environment` | yes | — | GitHub environment with AWS OIDC |
| `node-version` | no | `22` | Node.js version |
| `ecr-repository` | no | — | ECR repo name (omit to skip Docker) |
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
├── Dockerfile              # Required if ecr-repository is set
├── src/
└── tests/
```

## npm Scripts

The workflow runs these scripts via `npm run <script> --if-present`:

- `build` — compile/transpile
- `lint` — linter
- `typecheck` — type checker
- `test` — test suite
