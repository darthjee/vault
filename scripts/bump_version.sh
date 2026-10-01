#!/usr/bin/env bash
# Usage: scripts/bump_version.sh X.Y.Z
# Updates the VERSION file and the README "**Current Version:**" line.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="$ROOT/VERSION"
README_FILE="$ROOT/README.md"

new_version="${1:-}"

if [ -z "$new_version" ]; then
  echo "usage: $0 X.Y.Z" >&2
  exit 1
fi

if ! [[ "$new_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "error: invalid version '$new_version' (expected X.Y.Z)" >&2
  exit 1
fi

if ! grep -q '^\*\*Current Version:\*\* ' "$README_FILE"; then
  echo "error: no '**Current Version:**' line found in $README_FILE" >&2
  exit 1
fi

printf '%s\n' "$new_version" > "$VERSION_FILE"

tmp_file="$(mktemp "${README_FILE}.XXXXXX")"
trap 'rm -f "$tmp_file"' EXIT
sed "s/^\*\*Current Version:\*\* .*/**Current Version:** ${new_version}/" "$README_FILE" > "$tmp_file"
# Copy contents back (instead of mv) so README.md keeps its permissions.
cat "$tmp_file" > "$README_FILE"

echo "Version bumped to $new_version"
