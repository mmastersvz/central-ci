#!/usr/bin/env bash
set -euo pipefail

# Usage: next-version.sh [service]
#   service  Optional. When provided, tags are prefixed as "<service>/vX.Y.Z".
#            When omitted, tags are plain "vX.Y.Z".

SERVICE="${1:-}"

if [[ -n "$SERVICE" ]]; then
  PREFIX="${SERVICE}/v"
else
  PREFIX="v"
fi

git fetch --tags

# Find the latest semver tag matching our prefix
prev_tag=$(git tag -l "${PREFIX}*" | sort -V | tail -1)

if [[ -z "$prev_tag" ]]; then
  major=0; minor=0; patch=0
else
  ver="${prev_tag#"${PREFIX}"}"
  major=$(echo "$ver" | cut -d. -f1)
  minor=$(echo "$ver" | cut -d. -f2)
  patch=$(echo "$ver" | cut -d. -f3)
fi

# Collect commit subjects since last tag (or all commits if no prior tag)
if [[ -z "$prev_tag" ]]; then
  commits=$(git log --pretty=format:"%s" HEAD)
else
  commits=$(git log --pretty=format:"%s" "${prev_tag}..HEAD")
fi

bump=patch
if echo "$commits" | grep -qE '^feat(\(.+\))?!:|^fix(\(.+\))?!:|BREAKING CHANGE'; then
  bump=major
elif echo "$commits" | grep -qE '^feat(\(.+\))?:'; then
  bump=minor
fi

case $bump in
  major) major=$((major + 1)); minor=0; patch=0 ;;
  minor) minor=$((minor + 1)); patch=0 ;;
  patch) patch=$((patch + 1)) ;;
esac

new_tag="${PREFIX}${major}.${minor}.${patch}"
build_version="${major}.${minor}.${patch}"

echo "new_tag=${new_tag}"         >> "$GITHUB_OUTPUT"
echo "previous_tag=${prev_tag}"   >> "$GITHUB_OUTPUT"
echo "release_type=${bump}"       >> "$GITHUB_OUTPUT"
echo "build_version=${build_version}" >> "$GITHUB_OUTPUT"

{
  echo "### Version"
  echo ""
  echo "| | |"
  echo "| --- | --- |"
  echo "| **New tag** | \`${new_tag}\` |"
  echo "| **Marketing version** | \`${build_version}\` |"
  echo "| **Previous tag** | \`${prev_tag:-none}\` |"
  echo "| **Bump type** | ${bump} |"
  echo "| **Build number** | ${GITHUB_RUN_NUMBER} |"
} >> "$GITHUB_STEP_SUMMARY"
