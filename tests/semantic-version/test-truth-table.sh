#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CALCULATOR="$ROOT_DIR/.github/actions/semantic-version/calculate-version.sh"

failures=0
assertions=0

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  failures=$((failures + 1))
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

new_repo() {
  TEST_REPO="$(mktemp -d)"
  git init -q "$TEST_REPO"
  git -C "$TEST_REPO" config user.name "Forge semantic test"
  git -C "$TEST_REPO" config user.email "forge-semantic-test@example.invalid"
  mkdir -p "$TEST_REPO/services/api" "$TEST_REPO/services/worker" "$TEST_REPO/charts"
  printf 'api baseline\n' > "$TEST_REPO/services/api/component.txt"
  printf 'worker baseline\n' > "$TEST_REPO/services/worker/component.txt"
  printf 'chart baseline\n' > "$TEST_REPO/charts/Chart.yaml"
  printf '3.14\n' > "$TEST_REPO/.python-version"
  git -C "$TEST_REPO" add .
  git -C "$TEST_REPO" commit -qm "chore: baseline"
}

seed_component_tags() {
  git -C "$TEST_REPO" tag "api/v1.2.3"
  git -C "$TEST_REPO" tag "worker/v1.2.3"
  git -C "$TEST_REPO" tag "chart/v1.2.3"
}

cleanup_repo() {
  rm -rf "$TEST_REPO"
}

commit_mask() {
  local mask="$1"
  local subject="$2"
  local body="$3"

  if (( mask & 1 )); then
    printf 'api change %s\n' "$subject" >> "$TEST_REPO/services/api/component.txt"
  fi
  if (( mask & 2 )); then
    printf 'worker change %s\n' "$subject" >> "$TEST_REPO/services/worker/component.txt"
  fi
  if (( mask & 4 )); then
    printf 'chart change %s\n' "$subject" >> "$TEST_REPO/charts/Chart.yaml"
  fi

  git -C "$TEST_REPO" add .
  if [[ -n "$body" ]]; then
    git -C "$TEST_REPO" commit -qm "$subject" -m "$body"
  else
    git -C "$TEST_REPO" commit -qm "$subject"
  fi
}

run_calculator() {
  local prefix="$1"
  shift
  (cd "$TEST_REPO" && bash "$CALCULATOR" "$prefix" "$@")
}

field() {
  local output="$1"
  local name="$2"
  awk -F= -v key="$name" '$1 == key { print $2 }' <<< "$output"
}

assert_component() {
  local case_name="$1"
  local component="$2"
  local expected_version="$3"
  local expected_required="$4"
  local output
  local -a paths

  case "$component" in
    api)
      paths=(services/api .python-version)
      ;;
    worker)
      paths=(services/worker .python-version)
      ;;
    chart)
      paths=(charts)
      ;;
    *)
      fail "$case_name: unknown component $component"
      return
      ;;
  esac

  output="$(run_calculator "$component/" "${paths[@]}")"
  assert_equals "$case_name [$component] version" "$expected_version" "$(field "$output" SEMVER_VERSION)"
  assert_equals "$case_name [$component] release-required" "$expected_required" "$(field "$output" SEMVER_RELEASE_STATE | sed 's/^new$/true/; s/^existing$/true/; s/^none$/false/')"
}

bump_version() {
  local bump="$1"
  case "$bump" in
    none) printf '1.2.3' ;;
    patch) printf '1.2.4' ;;
    minor) printf '1.3.0' ;;
    major) printf '2.0.0' ;;
  esac
}

mask_contains() {
  local mask="$1"
  local component="$2"
  case "$component" in
    api) (( mask & 1 )) ;;
    worker) (( mask & 2 )) ;;
    chart) (( mask & 4 )) ;;
  esac
}

test_all_component_path_masks() {
  local -a names=(docs chore style test ci fix perf refactor build revert feat breaking-bang breaking-footer)
  local -a bumps=(none none none none none patch patch patch patch patch minor major major)
  local -a subjects=(
    "docs: change component"
    "chore: change component"
    "style: change component"
    "test: change component"
    "ci: change component"
    "fix: change component"
    "perf: change component"
    "refactor: change component"
    "build: change component"
    "revert: change component"
    "feat: change component"
    "feat!: change component"
    "feat: change component"
  )
  local -a bodies=("" "" "" "" "" "" "" "" "" "" "" "" "BREAKING CHANGE: intentional")
  local mask index component expected_bump expected_version case_name

  for mask in {1..7}; do
    for index in "${!names[@]}"; do
      new_repo
      seed_component_tags
      commit_mask "$mask" "${subjects[$index]}" "${bodies[$index]}"
      case_name="mask=$mask type=${names[$index]}"
      for component in api worker chart; do
        if mask_contains "$mask" "$component"; then
          expected_bump="${bumps[$index]}"
        else
          expected_bump=none
        fi
        expected_version="$(bump_version "$expected_bump")"
        if [[ "$expected_bump" == none ]]; then
          assert_component "$case_name" "$component" "$expected_version" false
        else
          assert_component "$case_name" "$component" "$expected_version" true
        fi
      done
      cleanup_repo
    done
  done
}

test_shared_path_ownership() {
  new_repo
  seed_component_tags
  printf '3.14.1\n' > "$TEST_REPO/.python-version"
  git -C "$TEST_REPO" add .python-version
  git -C "$TEST_REPO" commit -qm "fix: upgrade shared Python runtime"
  assert_component "shared-path" api 1.2.4 true
  assert_component "shared-path" worker 1.2.4 true
  assert_component "shared-path" chart 1.2.3 false
  cleanup_repo
}

test_mixed_history_precedence() {
  new_repo
  seed_component_tags
  commit_mask 1 "fix: patch API" ""
  commit_mask 6 "feat: expand worker and chart" ""
  commit_mask 5 "feat!: break API and chart" ""
  assert_component "mixed-history" api 2.0.0 true
  assert_component "mixed-history" worker 1.3.0 true
  assert_component "mixed-history" chart 2.0.0 true
  cleanup_repo
}

test_legacy_and_rerun_behavior() {
  new_repo
  commit_mask 2 "feat: worker-only feature" ""
  local output
  output="$(run_calculator api/)"
  assert_equals "legacy no-tag version" 0.1.0 "$(field "$output" SEMVER_VERSION)"
  assert_equals "legacy no-tag release state" new "$(field "$output" SEMVER_RELEASE_STATE)"

  seed_component_tags
  output="$(run_calculator api/ services/api .python-version)"
  assert_equals "tag-at-head version" 1.2.3 "$(field "$output" SEMVER_VERSION)"
  assert_equals "tag-at-head release state" existing "$(field "$output" SEMVER_RELEASE_STATE)"
  cleanup_repo
}

test_pathspec_is_literal() {
  new_repo
  seed_component_tags
  local indicator="$TEST_REPO/should-not-exist"
  local malicious='$(touch should-not-exist)'
  run_calculator api/ "$malicious" > /dev/null
  if [[ -e "$indicator" ]]; then
    fail "pathspec literal safety: command substitution was evaluated"
  else
    assertions=$((assertions + 1))
  fi
  cleanup_repo
}

test_all_component_path_masks
test_shared_path_ownership
test_mixed_history_precedence
test_legacy_and_rerun_behavior
test_pathspec_is_literal

if (( failures > 0 )); then
  printf '%d of %d semantic-version assertions failed\n' "$failures" "$assertions" >&2
  exit 1
fi

printf 'PASS: %d semantic-version truth-table assertions\n' "$assertions"
