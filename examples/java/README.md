# Java Build Example

Shows how a consumer repo uses Forge's Java semantic build workflow.

## Files

- `build-java.yml` — place in `.github/workflows/`

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `environment` | yes | — | GitHub environment with AWS OIDC |
| `java-version` | no | `21` | JDK version |
| `java-distribution` | no | `temurin` | JDK distribution |
| `ecr-repository` | no | — | ECR repo name (omit to skip Docker) |
| `dockerfile` | no | `Dockerfile` | Dockerfile path relative to working-directory |
| `platforms` | no | `linux/arm64` | Docker target platforms |
| `tag-prefix` | no | — | Monorepo tag prefix (e.g., `mypackage/`) |
| `working-directory` | no | `.` | Path to Java project root |
| `codeartifact-domain` | no | — | CodeArtifact domain (omit to skip JAR publish) |
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
├── build.gradle            # or build.gradle.kts
├── gradle.properties       # Must have version= field
├── gradlew                 # Gradle wrapper (committed)
├── gradlew.bat
├── gradle/
│   └── wrapper/
├── Dockerfile              # Required if ecr-repository is set
└── src/
    ├── main/
    └── test/
```

## CodeArtifact JAR Publishing

When `codeartifact-domain` is set, the workflow runs `./gradlew publish` with:

- `-PcodeartifactUrl` — repository endpoint
- `-PcodeartifactToken` — auth token

Configure your `build.gradle` to use these properties in the `publishing` block.
