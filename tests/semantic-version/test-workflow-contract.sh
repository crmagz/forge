#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
failures=0
assertions=0

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  failures=$((failures + 1))
}

assert_contains() {
  local description="$1"
  local file="$2"
  local expected="$3"
  assertions=$((assertions + 1))
  if ! grep -Fq -- "$expected" "$file"; then
    fail "$description: expected '$expected' in $file"
  fi
}

assert_not_contains() {
  local description="$1"
  local file="$2"
  local unexpected="$3"
  assertions=$((assertions + 1))
  if grep -Fq -- "$unexpected" "$file"; then
    fail "$description: did not expect '$unexpected' in $file"
  fi
}

assert_occurrences() {
  local description="$1"
  local file="$2"
  local expected="$3"
  local count="$4"
  local actual
  assertions=$((assertions + 1))
  actual="$(grep -Fc -- "$expected" "$file" || true)"
  if [[ "$actual" != "$count" ]]; then
    fail "$description: expected $count occurrence(s) of '$expected' in $file, got $actual"
  fi
}

extract_registry_validator() {
  awk '
    /^          case "\$CONTAINER_REGISTRY" in$/ { capture=1 }
    capture {
      line = $0
      sub(/^          /, "", line)
      print line
    }
    capture && /^          esac$/ { exit }
  ' "$1"
}

assert_registry_validation() {
  local description="$1"
  local expected_status="$2"
  local provider="$3"
  local ecr_repository="$4"
  local ghcr_repository="$5"
  local validator="$6"
  local actual_status

  assertions=$((assertions + 1))
  set +o errexit
  CONTAINER_REGISTRY="$provider" \
    ECR_REPOSITORY="$ecr_repository" \
    GHCR_REPOSITORY="$ghcr_repository" \
    bash -c "$validator" >/dev/null 2>&1
  actual_status=$?
  set -o errexit

  if [[ "$actual_status" != "$expected_status" ]]; then
    fail "$description: expected exit $expected_status, got $actual_status"
  fi
}

node_workflow="$ROOT_DIR/.github/workflows/build-node.yml"
node_registry_validator="$(extract_registry_validator "$node_workflow")"
if [[ -z "$node_registry_validator" ]]; then
  fail "build-node.yml registry validator could not be extracted"
fi

for workflow in build-python.yml build-node.yml build-java.yml; do
  file="$ROOT_DIR/.github/workflows/$workflow"
  assert_contains "$workflow exposes pathspec input" "$file" "      pathspecs:"
  assert_occurrences "$workflow forwards pathspecs to semantic version and release" "$file" "          pathspecs: \${{ inputs.pathspecs }}" 2
  assert_contains "$workflow concurrency is component scoped" "$file" "\${{ inputs.tag-prefix }}"
  assert_contains "$workflow exposes container registry provider" "$file" "      container-registry:"
  assert_contains "$workflow defaults container registry to ECR" "$file" "        default: \"ecr\""
  assert_contains "$workflow exposes GHCR repository input" "$file" "      ghcr-repository:"
  assert_contains "$workflow validates registry input before login" "$file" "      - name: Validate container publishing configuration"
  assert_contains "$workflow rejects unknown registry providers" "$file" "container-registry must be one of: ecr, ghcr, none"
  assert_contains "$workflow validates GHCR repository format" "$file" "ghcr-repository must be a lowercase owner/image path without ghcr.io"
  assert_contains "$workflow scopes package publishing permission to the publish job" "$file" "    permissions:"
  assert_contains "$workflow grants package publishing permission" "$file" "      packages: write"
  assert_contains "$workflow scopes build jobs to read-only contents" "$file" "  contents: read"
  assert_contains "$workflow scopes release jobs to write contents" "$file" "      contents: write"
  assert_contains "$workflow scopes pull request write to release jobs" "$file" "      pull-requests: write"
  assert_contains "$workflow configures AWS only for ECR or CodeArtifact" "$file" "if: (inputs.container-registry == 'ecr' && inputs.ecr-repository != '') || inputs.codeartifact-domain != ''"
  assert_contains "$workflow logs into GHCR with the GitHub token" "$file" "uses: docker/login-action@c94ce9fb468520275223c153574b00df6fe4bcc9"
  assert_contains "$workflow builds GHCR images with registry cache" "$file" "cache-registry: ghcr.io/\${{ inputs.ghcr-repository }}:buildcache"
  assert_contains "$workflow pins semantic version action" "$file" "semantic-version@d9687aa7da986d3431f10e67b22a14f92bb95b5d"
  assert_contains "$workflow pins Docker build action" "$file" "docker-build@082ea3a719a03854e5c2f29f89df76587489ba1f"
  assert_contains "$workflow pins release action" "$file" "actions/release@d9687aa7da986d3431f10e67b22a14f92bb95b5d"

  workflow_registry_validator="$(extract_registry_validator "$file")"
  assertions=$((assertions + 1))
  if [[ "$workflow_registry_validator" != "$node_registry_validator" ]]; then
    fail "$workflow must share the Node registry validator"
  fi
done

assert_registry_validation "default ECR without an image remains valid" 0 "ecr" "" "" "$node_registry_validator"
assert_registry_validation "ECR rejects a GHCR repository" 1 "ecr" "app" "owner/app" "$node_registry_validator"
assert_registry_validation "GHCR accepts a lowercase owner/image path" 0 "ghcr" "" "owner/app" "$node_registry_validator"
assert_registry_validation "GHCR rejects a missing repository" 1 "ghcr" "" "" "$node_registry_validator"
assert_registry_validation "GHCR rejects an ECR repository" 1 "ghcr" "app" "owner/app" "$node_registry_validator"
assert_registry_validation "GHCR rejects an uppercase repository" 1 "ghcr" "" "Owner/app" "$node_registry_validator"
assert_registry_validation "none accepts no image repository" 0 "none" "" "" "$node_registry_validator"
assert_registry_validation "none rejects an image repository" 1 "none" "app" "" "$node_registry_validator"
assert_registry_validation "unknown provider is rejected" 1 "other" "" "" "$node_registry_validator"

semantic_action="$ROOT_DIR/.github/actions/semantic-version/action.yml"
assert_contains "semantic action exposes pathspec input" "$semantic_action" "  pathspecs:"
assert_contains "semantic action receives pathspec input through env" "$semantic_action" "SEMVER_PATHS: \${{ inputs.pathspecs }}"
assert_contains "semantic action invokes the tested parser" "$semantic_action" "parse-pathspecs.sh"

release_action="$ROOT_DIR/.github/actions/release/action.yml"
assert_contains "release action exposes pathspec input" "$release_action" "  pathspecs:"
assert_contains "release action receives pathspec input through env" "$release_action" "RELEASE_PATHS: \${{ inputs.pathspecs }}"

taskfile="$ROOT_DIR/tasks/release/Taskfile.yml"
assert_not_contains "task commands do not interpolate PATHS as shell text" "$taskfile" "{{.PATHS}}"
assert_contains "task commands read pathspecs from environment" "$taskfile" "\${SEMVER_PATHS:-}"

docker_action="$ROOT_DIR/.github/actions/docker-build/action.yml"
assert_contains "docker action pins QEMU setup" "$docker_action" "docker/setup-qemu-action@c7c53464625b32c7a7e944ae62b3e17d2b600130"
assert_contains "docker action pins Buildx setup" "$docker_action" "docker/setup-buildx-action@8d2750c68a42422c14e847fe6c8ac0403b4cbd6f"
assert_contains "docker action pins Task setup" "$docker_action" "arduino/setup-task@b91d5d2c96a56797b48ac1e0e89220bf64044611"
assert_contains "docker action passes inputs through environment" "$docker_action" "        IMAGE_REGISTRY: \${{ inputs.registry }}"
assert_contains "docker action delegates to its bundled Taskfile" "$docker_action" "task --dir \"\$GITHUB_WORKSPACE\" --taskfile \"\$GITHUB_ACTION_PATH/Taskfile.yml\" build-push"

docker_taskfile="$ROOT_DIR/.github/actions/docker-build/Taskfile.yml"
assert_contains "docker task uses argument arrays" "$docker_taskfile" "        build_args=()"
assert_contains "docker task creates a latest tag when requested" "$docker_taskfile" "image_tags+=(--tag \"\${image_ref}:latest\")"

if (( failures > 0 )); then
  printf '%d of %d workflow-contract assertions failed\n' "$failures" "$assertions" >&2
  exit 1
fi

printf 'PASS: %d workflow-contract assertions\n' "$assertions"
