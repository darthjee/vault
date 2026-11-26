#!/usr/bin/env bash
# Usage: scripts/bump_version.sh [patch|minor|major|X.Y.Z]
# Computes the new version from the VERSION file (default: patch bump) or takes
# an explicit X.Y.Z, then updates the VERSION file, the README
# "**Current Version:** [X.Y.Z](release link)" and
# "**Next Release:** [X.Y.Z+1](compare link)" lines, the
# "**Vault version:** X.Y.Z" line of docs/guides/vault.md and the
# VAULT_VERSION="X.Y.Z" line of cli/bin/vault and install.sh.
# Fails before writing anything if a target file is missing, lacks its version
# line or has more than one.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="$ROOT/VERSION"
README_FILE="$ROOT/README.md"
CLI_FILE="$ROOT/cli/bin/vault"
INSTALL_FILE="$ROOT/install.sh"
GUIDES_FILE="$ROOT/docs/guides/vault.md"
REPO_URL="https://github.com/darthjee/vault"
SEMVER_REGEX='^[0-9]+\.[0-9]+\.[0-9]+$'
VAULT_VERSION_REGEX='^VAULT_VERSION="[0-9]+\.[0-9]+\.[0-9]+"$'
GUIDES_VERSION_REGEX='^\*\*Vault version:\*\* [0-9]+\.[0-9]+\.[0-9]+$'
README_CURRENT_REGEX='^\*\*Current Version:\*\* '
README_NEXT_REGEX='^\*\*Next Release:\*\* '

usage() {
  echo "usage: $0 [patch|minor|major|X.Y.Z]" >&2
  exit 1
}

# Fails unless FILE exists and has exactly one line matching REGEX.
# Usage: require_single_line FILE REGEX LABEL
require_single_line() {
  local file="$1" regex="$2" label="$3"
  local name="${file#"$ROOT"/}"
  local count
  if [ ! -f "$file" ]; then
    echo "error: $name not found" >&2
    exit 1
  fi
  count="$(grep -cE "$regex" "$file" || true)"
  if [ "$count" -eq 0 ]; then
    echo "error: no '$label' line found in $name" >&2
    exit 1
  fi
  if [ "$count" -gt 1 ]; then
    echo "error: $count '$label' lines found in $name (expected 1)" >&2
    exit 1
  fi
}

[ "$#" -le 1 ] || usage
bump="${1:-patch}"

if [ ! -f "$VERSION_FILE" ]; then
  echo "error: VERSION not found" >&2
  exit 1
fi
current_version="$(tr -d '[:space:]' < "$VERSION_FILE")"
if ! [[ "$current_version" =~ $SEMVER_REGEX ]]; then
  echo "error: invalid current version '$current_version' in VERSION (expected X.Y.Z)" >&2
  exit 1
fi

IFS=. read -r major minor patch <<< "$current_version"

case "$bump" in
  patch) new_version="${major}.${minor}.$((patch + 1))" ;;
  minor) new_version="${major}.$((minor + 1)).0" ;;
  major) new_version="$((major + 1)).0.0" ;;
  *)
    if ! [[ "$bump" =~ $SEMVER_REGEX ]]; then
      echo "error: invalid version '$bump' (expected patch, minor, major or X.Y.Z)" >&2
      exit 1
    fi
    new_version="$bump"
    ;;
esac

IFS=. read -r major minor patch <<< "$new_version"
next_version="${major}.${minor}.$((patch + 1))"

version_files=("$CLI_FILE" "$INSTALL_FILE")

require_single_line "$README_FILE" "$README_CURRENT_REGEX" '**Current Version:**'
require_single_line "$README_FILE" "$README_NEXT_REGEX" '**Next Release:**'
require_single_line "$GUIDES_FILE" "$GUIDES_VERSION_REGEX" '**Vault version:**'
for file in "${version_files[@]}"; do
  require_single_line "$file" "$VAULT_VERSION_REGEX" 'VAULT_VERSION="X.Y.Z"'
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

rewrite "$README_FILE" -E \
  -e "s|${README_CURRENT_REGEX}.*|**Current Version:** [${new_version}](${REPO_URL}/releases/tag/${new_version})|" \
  -e "s|${README_NEXT_REGEX}.*|**Next Release:** [${next_version}](${REPO_URL}/compare/${new_version}...main)|"

rewrite "$GUIDES_FILE" -E "s/${GUIDES_VERSION_REGEX}/**Vault version:** ${new_version}/"

for file in "${version_files[@]}"; do
  rewrite "$file" -E "s/${VAULT_VERSION_REGEX}/VAULT_VERSION=\"${new_version}\"/"
done

echo "Version bumped from $current_version to $new_version (next release: $next_version)"
