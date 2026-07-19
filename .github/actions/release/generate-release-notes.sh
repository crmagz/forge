#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset

generate_release_notes() {
  local previous_tag="${1:-}"
  local current_ref="${2:-HEAD}"
  local -a pathspecs=()
  if [ "$#" -gt 2 ]; then
    pathspecs=("${@:3}")
  fi
  local range

  if [ -z "$previous_tag" ]; then
    range="$current_ref"
  else
    range="${previous_tag}..${current_ref}"
  fi

  local commits
  if [ "${#pathspecs[@]}" -gt 0 ]; then
    commits=$(git log "$range" --pretty=format:"%s|%h|%an" -- "${pathspecs[@]}" 2>/dev/null || true)
  else
    commits=$(git log "$range" --pretty=format:"%s|%h|%an" 2>/dev/null || true)
  fi

  if [ -z "$commits" ]; then
    echo "No changes."
    return 0
  fi

  # Collect commit hashes that have BREAKING CHANGE footer in their body
  local breaking_hashes=""
  while IFS= read -r hash; do
    body=$(git log -1 --pretty=format:"%b" "$hash" 2>/dev/null || true)
    if echo "$body" | grep -qE "^BREAKING CHANGE:"; then
      breaking_hashes="${breaking_hashes} ${hash}"
    fi
  done < <(
    if [ "${#pathspecs[@]}" -gt 0 ]; then
      git log "$range" --pretty=format:"%h" -- "${pathspecs[@]}"
    else
      git log "$range" --pretty=format:"%h"
    fi
  )

  local breaking="" features="" fixes="" performance="" refactors="" builds="" reverts=""
  local docs="" chores="" ci="" styles="" tests="" other=""

  while IFS= read -r entry; do
    local subject hash author
    subject=$(echo "$entry" | cut -d'|' -f1)
    hash=$(echo "$entry" | cut -d'|' -f2)
    author=$(echo "$entry" | cut -d'|' -f3)

    local description
    description=$(echo "$subject" | sed -E 's/^[a-z]+(\([^)]*\))?!?:[[:space:]]*//')

    local scope=""
    if echo "$subject" | grep -qE "^[a-z]+\([^)]+\)"; then
      scope=$(echo "$subject" | sed -E 's/^[a-z]+\(([^)]+)\).*/\1/')
    fi

    local line="* ${description} (${hash}) — ${author}"
    if [ -n "$scope" ]; then
      line="* **${scope}:** ${description} (${hash}) — ${author}"
    fi

    # Check for breaking: subject indicator OR body footer
    local is_breaking="false"
    if echo "$subject" | grep -qE "^[a-z]+(\(.*\))?!:"; then
      is_breaking="true"
    elif echo "$breaking_hashes" | grep -qw "$hash"; then
      is_breaking="true"
    fi

    if [ "$is_breaking" = "true" ]; then
      breaking="${breaking}${line}"$'\n'
    elif echo "$subject" | grep -qE "^feat(\(.*\))?:"; then
      features="${features}${line}"$'\n'
    elif echo "$subject" | grep -qE "^fix(\(.*\))?:"; then
      fixes="${fixes}${line}"$'\n'
    elif echo "$subject" | grep -qE "^perf(\(.*\))?:"; then
      performance="${performance}${line}"$'\n'
    elif echo "$subject" | grep -qE "^refactor(\(.*\))?:"; then
      refactors="${refactors}${line}"$'\n'
    elif echo "$subject" | grep -qE "^build(\(.*\))?:"; then
      builds="${builds}${line}"$'\n'
    elif echo "$subject" | grep -qE "^revert(\(.*\))?:"; then
      reverts="${reverts}${line}"$'\n'
    elif echo "$subject" | grep -qE "^docs(\(.*\))?:"; then
      docs="${docs}${line}"$'\n'
    elif echo "$subject" | grep -qE "^chore(\(.*\))?:"; then
      chores="${chores}${line}"$'\n'
    elif echo "$subject" | grep -qE "^ci(\(.*\))?:"; then
      ci="${ci}${line}"$'\n'
    elif echo "$subject" | grep -qE "^style(\(.*\))?:"; then
      styles="${styles}${line}"$'\n'
    elif echo "$subject" | grep -qE "^test(\(.*\))?:"; then
      tests="${tests}${line}"$'\n'
    else
      other="${other}${line}"$'\n'
    fi
  done <<< "$commits"

  local contributors
  if [ "${#pathspecs[@]}" -gt 0 ]; then
    contributors=$(git log "$range" --pretty=format:"%an" -- "${pathspecs[@]}" 2>/dev/null | sort -u | paste -sd ", " -)
  else
    contributors=$(git log "$range" --pretty=format:"%an" 2>/dev/null | sort -u | paste -sd ", " -)
  fi

  [ -n "$breaking" ]    && printf "### Breaking Changes\n%s\n" "$breaking"
  [ -n "$features" ]    && printf "### Features\n%s\n" "$features"
  [ -n "$fixes" ]       && printf "### Bug Fixes\n%s\n" "$fixes"
  [ -n "$performance" ] && printf "### Performance\n%s\n" "$performance"
  [ -n "$refactors" ]   && printf "### Refactors\n%s\n" "$refactors"
  [ -n "$builds" ]      && printf "### Build\n%s\n" "$builds"
  [ -n "$reverts" ]     && printf "### Reverts\n%s\n" "$reverts"
  [ -n "$docs" ]        && printf "### Documentation\n%s\n" "$docs"
  [ -n "$chores" ]      && printf "### Chores\n%s\n" "$chores"
  [ -n "$ci" ]          && printf "### CI\n%s\n" "$ci"
  [ -n "$styles" ]      && printf "### Styles\n%s\n" "$styles"
  [ -n "$tests" ]       && printf "### Tests\n%s\n" "$tests"
  [ -n "$other" ]       && printf "### Other\n%s\n" "$other"
  [ -n "$contributors" ] && printf "### Contributors\n%s\n" "$contributors"
}

if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  generate_release_notes "$@"
fi
