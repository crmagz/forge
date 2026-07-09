#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset

# calculate-semantic-version.sh
# Derives the next semantic version from git tags and conventional commit history.
# Outputs: SEMVER_VERSION, SEMVER_BUMP, SEMVER_PREVIOUS_TAG, SEMVER_RELEASE_STATE
#
# SEMVER_RELEASE_STATE values:
#   existing — current commit already has a matching tag (rerun-safe)
#   new      — a version bump was detected, new release needed
#   none     — no release-worthy commits since last tag

calculate_semantic_version() {
  local tag_prefix="${1:-}"
  local latest_tag
  local current_tag
  local major minor patch
  local bump="none"
  local release_state="none"
  local tag_pattern

  # Escape regex metacharacters in tag_prefix to prevent pattern injection
  local escaped_prefix
  escaped_prefix=$(printf '%s' "$tag_prefix" | sed 's/[.+*?^${}()|[\]\\]/\\&/g')

  if [ -n "$escaped_prefix" ]; then
    tag_pattern="^${escaped_prefix}v?[0-9]+\.[0-9]+\.[0-9]+$"
  else
    tag_pattern="^v?[0-9]+\.[0-9]+\.[0-9]+$"
  fi

  # Check if the current commit already has a release tag (rerun recovery)
  current_tag=$(git tag --points-at HEAD --sort=-v:refname | grep -E "$tag_pattern" | head -1 || true)
  if [ -n "$current_tag" ]; then
    local current_version="${current_tag#${tag_prefix}}"
    current_version="${current_version#v}"

    if ! echo "$current_version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
      echo "ERROR: tag '${current_tag}' is not valid semver (expected X.Y.Z or vX.Y.Z)" >&2
      return 1
    fi

    local previous_tag
    previous_tag=$(git tag --merged HEAD --sort=-v:refname | grep -E "$tag_pattern" | grep -v -x "$current_tag" | head -1 || true)

    echo "SEMVER_VERSION=${current_version}"
    echo "SEMVER_BUMP=none"
    echo "SEMVER_PREVIOUS_TAG=${previous_tag}"
    echo "SEMVER_RELEASE_STATE=existing"
    return 0
  fi

  # Use --merged HEAD to only find tags that are ancestors of the current commit
  latest_tag=$(git tag --merged HEAD --sort=-v:refname | grep -E "$tag_pattern" | head -1 || true)

  if [ -z "$latest_tag" ]; then
    echo "SEMVER_VERSION=0.1.0"
    echo "SEMVER_BUMP=minor"
    echo "SEMVER_PREVIOUS_TAG="
    echo "SEMVER_RELEASE_STATE=new"
    return 0
  fi

  local version="${latest_tag#${tag_prefix}}"
  version="${version#v}"

  if ! echo "$version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "ERROR: tag '${latest_tag}' is not valid semver (expected X.Y.Z or vX.Y.Z)" >&2
    return 1
  fi

  major=$(echo "$version" | cut -d. -f1)
  minor=$(echo "$version" | cut -d. -f2)
  patch=$(echo "$version" | cut -d. -f3)

  local subjects bodies
  subjects=$(git log "${latest_tag}..HEAD" --pretty=format:"%s" 2>/dev/null || true)
  bodies=$(git log "${latest_tag}..HEAD" --pretty=format:"%b" 2>/dev/null || true)

  if [ -z "$subjects" ]; then
    echo "SEMVER_VERSION=${major}.${minor}.${patch}"
    echo "SEMVER_BUMP=none"
    echo "SEMVER_PREVIOUS_TAG=${latest_tag}"
    echo "SEMVER_RELEASE_STATE=none"
    return 0
  fi

  if echo "$bodies" | grep -qE "^BREAKING CHANGE:"; then
    bump="major"
  fi

  while IFS= read -r line; do
    if [ "$bump" != "major" ] && echo "$line" | grep -qE "^[a-z]+(\(.*\))?!:|^[a-z]+!\("; then
      bump="major"
      break
    fi

    if [ "$bump" != "major" ] && echo "$line" | grep -qE "^feat(\(.*\))?:"; then
      bump="minor"
    fi

    if [ "$bump" = "none" ] && echo "$line" | grep -qE "^(fix|perf|refactor|build|revert)(\(.*\))?:"; then
      bump="patch"
    fi
  done <<< "$subjects"

  case "$bump" in
    major)
      major=$((major + 1))
      minor=0
      patch=0
      ;;
    minor)
      minor=$((minor + 1))
      patch=0
      ;;
    patch)
      patch=$((patch + 1))
      ;;
    none) ;;
  esac

  if [ "$bump" != "none" ]; then
    release_state="new"
  fi

  echo "SEMVER_VERSION=${major}.${minor}.${patch}"
  echo "SEMVER_BUMP=${bump}"
  echo "SEMVER_PREVIOUS_TAG=${latest_tag}"
  echo "SEMVER_RELEASE_STATE=${release_state}"
}

if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]]; then
  calculate_semantic_version "$@"
fi
