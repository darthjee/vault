#!/usr/bin/env bash
# Usage: scripts/check_tag_version.sh X.Y.Z
# Fails when the tag does not match the VERSION file or the README
# "**Current Version:**" line.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="$ROOT/VERSION"
README_FILE="$ROOT/README.md"

tag="${1:-}"

if [ -z "$tag" ]; then
  echo "usage: $0 X.Y.Z" >&2
  exit 1
fi

file_version="$(tr -d '[:space:]' < "$VERSION_FILE")"
readme_version="$(sed -n 's/^\*\*Current Version:\*\* *\([^[:space:]]*\).*/\1/p' "$README_FILE" | head -n 1)"

status=0

if [ "$tag" != "$file_version" ]; then
  echo "error: tag '$tag' does not match VERSION file ('$file_version')" >&2
  status=1
fi

if [ "$tag" != "$readme_version" ]; then
  echo "error: tag '$tag' does not match README.md Current Version ('$readme_version')" >&2
  status=1
fi

if [ "$status" -eq 0 ]; then
  echo "Tag $tag matches VERSION and README.md"
fi

exit "$status"
