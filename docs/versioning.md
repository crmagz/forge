# Versioning

## Release Strategy

Forge uses [Semantic Versioning](https://semver.org/):

- **Major** (`v2.0.0`): Breaking changes to workflow inputs, outputs, or behavior
- **Minor** (`v1.1.0`): New workflows or backward-compatible input additions
- **Patch** (`v1.0.1`): Bug fixes and internal improvements with no interface change

## Version Tags

Tags are scoped by toolchain:

1. **Major version**: `terraform/v1` — mutable, updated to point to the latest release in that major
2. **Exact version**: `terraform/v1.2.3` — immutable, points to a specific commit

Consumers reference the major version tag for automatic minor/patch updates:

```yaml
uses: <org>/forge/.github/workflows/terraform.yml@terraform/v1
```

For maximum determinism, consumers can pin to an exact version:

```yaml
uses: <org>/forge/.github/workflows/terraform.yml@terraform/v1.0.0
```

## Version Pinning Philosophy

### Why Pin Everything

Non-deterministic builds are a liability:
- A workflow that passes today but fails tomorrow (with no code changes) wastes engineering time
- A dependency that silently upgrades can introduce breaking changes or security vulnerabilities
- Debugging is harder when you can't reproduce the exact environment

### What Gets Pinned

| Artifact | How | Example |
|----------|-----|---------|
| GitHub Actions | Full commit SHA | `actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11` |
| Terraform | Exact version string | `terraform-version: "1.9.8"` |
| Terraform providers | Lock file + exact constraint | `version = "= 5.82.2"` |
| Terraform modules | Exact version | `version = "5.16.0"` |

### Updating Pinned Versions

Version updates are intentional, not automatic:

1. Create a branch for the version bump
2. Update the pinned version
3. Test with a consumer repo
4. Document the change in the PR
5. Release a new Forge version

## Release Process

1. Ensure all changes are merged to `main`
2. Determine the version bump (major/minor/patch) based on changes since last release
3. Create and push the version tag:
   ```bash
   git tag terraform/v1.0.0
   git push origin terraform/v1.0.0
   ```
4. Update the major version tag:
   ```bash
   git tag -f terraform/v1
   git push -f origin terraform/v1
   ```
5. Create a GitHub Release with release notes
