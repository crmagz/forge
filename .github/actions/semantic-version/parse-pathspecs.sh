#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

# Emit non-blank newline-delimited Git pathspecs without evaluating their
# contents. Composite-action inputs are data, not shell source.
while IFS= read -r pathspec; do
  if [[ "$pathspec" =~ [^[:space:]] ]]; then
    printf '%s\n' "$pathspec"
  fi
done
