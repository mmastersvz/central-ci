#!/usr/bin/env bash
set -euo pipefail

# Usage: generate-changelog.sh <previous-tag> <new-tag>
#   Generates a Conventional Commits grouped changelog between two tags.
#   Writes markdown to stdout.

PREVIOUS_TAG="${1:-}"
NEW_TAG="${2:-HEAD}"

if [[ -z "$PREVIOUS_TAG" ]]; then
  commits=$(git log --pretty=format:"%H %s" HEAD)
else
  commits=$(git log --pretty=format:"%H %s" "${PREVIOUS_TAG}..HEAD")
fi

breaking=()
features=()
fixes=()
other=()

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  sha="${line%% *}"
  subject="${line#* }"
  short_sha="${sha:0:7}"
  entry="- ${subject} (\`${short_sha}\`)"

  if echo "$subject" | grep -qE '^feat(\(.+\))?!:|^fix(\(.+\))?!:|BREAKING CHANGE'; then
    breaking+=("$entry")
  elif echo "$subject" | grep -qE '^feat(\(.+\))?:'; then
    features+=("$entry")
  elif echo "$subject" | grep -qE '^fix(\(.+\))?:'; then
    fixes+=("$entry")
  else
    other+=("$entry")
  fi
done <<< "$commits"

{
  if [[ ${#breaking[@]} -gt 0 ]]; then
    echo "## Breaking Changes"
    echo ""
    printf '%s\n' "${breaking[@]}"
    echo ""
  fi

  if [[ ${#features[@]} -gt 0 ]]; then
    echo "## Features"
    echo ""
    printf '%s\n' "${features[@]}"
    echo ""
  fi

  if [[ ${#fixes[@]} -gt 0 ]]; then
    echo "## Bug Fixes"
    echo ""
    printf '%s\n' "${fixes[@]}"
    echo ""
  fi

  if [[ ${#other[@]} -gt 0 ]]; then
    echo "## Other Changes"
    echo ""
    printf '%s\n' "${other[@]}"
    echo ""
  fi

  if [[ -n "$PREVIOUS_TAG" ]]; then
    echo "**Full Changelog**: ${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/compare/${PREVIOUS_TAG}...${NEW_TAG}"
  fi
}
