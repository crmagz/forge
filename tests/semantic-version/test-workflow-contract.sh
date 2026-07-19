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

for workflow in build-python.yml build-node.yml build-java.yml; do
  file="$ROOT_DIR/.github/workflows/$workflow"
  assert_contains "$workflow exposes pathspec input" "$file" "      pathspecs:"
  assert_occurrences "$workflow forwards pathspecs to semantic version and release" "$file" "          pathspecs: \${{ inputs.pathspecs }}" 2
  assert_contains "$workflow concurrency is component scoped" "$file" "\${{ inputs.tag-prefix }}"
done

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

if (( failures > 0 )); then
  printf '%d of %d workflow-contract assertions failed\n' "$failures" "$assertions" >&2
  exit 1
fi

printf 'PASS: %d workflow-contract assertions\n' "$assertions"
