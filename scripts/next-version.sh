#!/usr/bin/env bash
set -euo pipefail

SERVICE="${1:-}"
PREFIX="${SERVICE:+$SERVICE/v}"
PREFIX="${PREFIX:-v}"

git fetch --tags --force

prev_tag=$(git tag -l "${PREFIX}*" | sort -V | tail -1 || echo "")

if [[ -z "$prev_tag" ]]; then
  major=0; minor=0; patch=0
else
  ver="${prev_tag#"${PREFIX}"}"
  major=$(echo "$ver" | cut -d. -f1)
  minor=$(echo "$ver" | cut -d. -f2)
  patch=$(echo "$ver" | cut -d. -f3)
fi

if [[ -z "$prev_tag" ]]; then
  commits=$(git log --pretty=format:"%s" "${GITHUB_SHA}")
else
  commits=$(git log --pretty=format:"%s" "${prev_tag}..${GITHUB_SHA}")
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

echo "new_tag=${new_tag}"             >> "$GITHUB_OUTPUT"
echo "previous_tag=${prev_tag}"       >> "$GITHUB_OUTPUT"
echo "release_type=${bump}"           >> "$GITHUB_OUTPUT"
echo "build_version=${build_version}" >> "$GITHUB_OUTPUT"

{
  echo "### Versioning Summary"
  echo ""
  echo "| Attribute | Value |"
  echo "| :--- | :--- |"
  echo "| **Action** | Bump ${bump^^} |"
  echo "| **New Tag** | \`${new_tag}\` |"
  echo "| **App Version** | \`${build_version}\` |"
  echo "| **Previous Tag** | \`${prev_tag:-none}\` |"
} >> "$GITHUB_STEP_SUMMARY"
