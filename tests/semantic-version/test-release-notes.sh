#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GENERATOR="$ROOT_DIR/.github/actions/release/generate-release-notes.sh"

failures=0
assertions=0

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  failures=$((failures + 1))
}

assert_contains() {
  local description="$1"
  local output="$2"
  local expected="$3"
  assertions=$((assertions + 1))
  if ! grep -Fq -- "$expected" <<< "$output"; then
    fail "$description: expected to find '$expected'"
  fi
}

assert_not_contains() {
  local description="$1"
  local output="$2"
  local unexpected="$3"
  assertions=$((assertions + 1))
  if grep -Fq -- "$unexpected" <<< "$output"; then
    fail "$description: did not expect to find '$unexpected'"
  fi
}

assert_equals() {
  local description="$1"
  local expected="$2"
  local actual="$3"
  assertions=$((assertions + 1))
  if [[ "$expected" != "$actual" ]]; then
    fail "$description: expected '$expected', got '$actual'"
  fi
}

TEST_REPO="$(mktemp -d)"
cleanup() {
  rm -rf "$TEST_REPO"
}
trap cleanup EXIT

git init -q "$TEST_REPO"
git -C "$TEST_REPO" config user.name "Initial Author"
git -C "$TEST_REPO" config user.email "initial@example.invalid"
mkdir -p "$TEST_REPO/services/api" "$TEST_REPO/services/worker"
printf 'api baseline\n' > "$TEST_REPO/services/api/component.txt"
printf 'worker baseline\n' > "$TEST_REPO/services/worker/component.txt"
git -C "$TEST_REPO" add .
git -C "$TEST_REPO" commit -qm "chore: baseline"
git -C "$TEST_REPO" tag api/v1.2.3

printf 'api feature\n' >> "$TEST_REPO/services/api/component.txt"
git -C "$TEST_REPO" add services/api/component.txt
GIT_AUTHOR_NAME="API Author" GIT_AUTHOR_EMAIL="api@example.invalid" \
  git -C "$TEST_REPO" commit -qm "feat(api): add API feature"

printf 'worker feature\n' >> "$TEST_REPO/services/worker/component.txt"
git -C "$TEST_REPO" add services/worker/component.txt
GIT_AUTHOR_NAME="Worker Author" GIT_AUTHOR_EMAIL="worker@example.invalid" \
  git -C "$TEST_REPO" commit -qm "feat(worker): add worker feature"

printf 'api fix\n' >> "$TEST_REPO/services/api/component.txt"
git -C "$TEST_REPO" add services/api/component.txt
GIT_AUTHOR_NAME="API Author" GIT_AUTHOR_EMAIL="api@example.invalid" \
  git -C "$TEST_REPO" commit -qm "fix(api): correct API behavior"

scoped_output="$(cd "$TEST_REPO" && bash "$GENERATOR" api/v1.2.3 HEAD services/api)"
assert_contains "scoped notes include API feature" "$scoped_output" "add API feature"
assert_contains "scoped notes include API fix" "$scoped_output" "correct API behavior"
assert_contains "scoped notes include API contributor" "$scoped_output" "API Author"
assert_not_contains "scoped notes exclude worker feature" "$scoped_output" "add worker feature"
assert_not_contains "scoped notes exclude worker contributor" "$scoped_output" "Worker Author"

unscoped_output="$(cd "$TEST_REPO" && bash "$GENERATOR" api/v1.2.3)"
assert_contains "legacy notes include worker feature" "$unscoped_output" "add worker feature"
assert_contains "legacy notes include worker contributor" "$unscoped_output" "Worker Author"

empty_output="$(cd "$TEST_REPO" && bash "$GENERATOR" api/v1.2.3 HEAD charts)"
assert_equals "unmatched path emits no changes" "No changes." "$empty_output"

if (( failures > 0 )); then
  printf '%d of %d release-note assertions failed\n' "$failures" "$assertions" >&2
  exit 1
fi

printf 'PASS: %d release-note path-filter assertions\n' "$assertions"
