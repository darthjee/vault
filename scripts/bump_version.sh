#!/usr/bin/env bash
# Usage: scripts/bump_version.sh X.Y.Z
# Updates the VERSION file, the README "**Current Version:**" line and the
# VAULT_VERSION="X.Y.Z" line of cli/bin/vault and install.sh (when it exists).
# Fails before writing anything if a target file lacks that line or has more
# than one.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="$ROOT/VERSION"
README_FILE="$ROOT/README.md"
CLI_FILE="$ROOT/cli/bin/vault"
INSTALL_FILE="$ROOT/install.sh"
VAULT_VERSION_REGEX='^VAULT_VERSION="[0-9]+\.[0-9]+\.[0-9]+"$'

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

version_files=("$CLI_FILE")
if [ -f "$INSTALL_FILE" ]; then
  version_files+=("$INSTALL_FILE")
fi

for file in "${version_files[@]}"; do
  name="${file#"$ROOT"/}"
  if [ ! -f "$file" ]; then
    echo "error: $name not found" >&2
    exit 1
  fi
  count="$(grep -cE "$VAULT_VERSION_REGEX" "$file" || true)"
  if [ "$count" -eq 0 ]; then
    echo "error: no 'VAULT_VERSION=\"X.Y.Z\"' line found in $name" >&2
    exit 1
  fi
  if [ "$count" -gt 1 ]; then
    echo "error: $count 'VAULT_VERSION=\"X.Y.Z\"' lines found in $name (expected 1)" >&2
    exit 1
  fi
done

tmp_file=""
trap 'rm -f "$tmp_file"' EXIT

# Rewrites a file through sed, copying the contents back (instead of mv) so
# the file keeps its permissions.
# Usage: rewrite FILE SED_ARGS...
rewrite() {
  local file="$1"
  shift
  tmp_file="$(mktemp "${file}.XXXXXX")"
  sed "$@" "$file" > "$tmp_file"
  cat "$tmp_file" > "$file"
  rm -f "$tmp_file"
  tmp_file=""
}

printf '%s\n' "$new_version" > "$VERSION_FILE"

rewrite "$README_FILE" "s/^\*\*Current Version:\*\* .*/**Current Version:** ${new_version}/"

for file in "${version_files[@]}"; do
  rewrite "$file" -E "s/${VAULT_VERSION_REGEX}/VAULT_VERSION=\"${new_version}\"/"
done

echo "Version bumped to $new_version"
