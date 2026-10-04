#!/usr/bin/env bash
# Usage: scripts/check_tag_version.sh X.Y.Z
# Fails when the tag does not match the VERSION file, the README
# "**Current Version:**" line, the "**Vault version:** X.Y.Z" line of
# docs/guides/vault.md, or the VAULT_VERSION="X.Y.Z" line of cli/bin/vault and
# install.sh. A missing file or a missing or duplicated guides or
# VAULT_VERSION line fails.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="$ROOT/VERSION"
README_FILE="$ROOT/README.md"
CLI_FILE="$ROOT/cli/bin/vault"
INSTALL_FILE="$ROOT/install.sh"
GUIDES_FILE="$ROOT/docs/guides/vault.md"
VAULT_VERSION_REGEX='^VAULT_VERSION="[0-9]+\.[0-9]+\.[0-9]+"$'
GUIDES_VERSION_REGEX='^\*\*Vault version:\*\* [0-9]+\.[0-9]+\.[0-9]+$'

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

# Checks the single VAULT_VERSION line of a file against the tag.
# Usage: check_vault_version FILE
check_vault_version() {
  local file="$1"
  local name="${file#"$ROOT"/}"
  local lines count file_tag

  if [ ! -f "$file" ]; then
    echo "error: $name not found" >&2
    status=1
    return
  fi

  lines="$(grep -E "$VAULT_VERSION_REGEX" "$file" || true)"
  if [ -z "$lines" ]; then
    count=0
  else
    count="$(printf '%s\n' "$lines" | wc -l | tr -d '[:space:]')"
  fi

  if [ "$count" -eq 0 ]; then
    echo "error: no 'VAULT_VERSION=\"X.Y.Z\"' line found in $name" >&2
    status=1
    return
  fi
  if [ "$count" -gt 1 ]; then
    echo "error: $count 'VAULT_VERSION=\"X.Y.Z\"' lines found in $name (expected 1)" >&2
    status=1
    return
  fi

  file_tag="$(printf '%s\n' "$lines" | sed -E 's/^VAULT_VERSION="([^"]*)"$/\1/')"
  if [ "$tag" != "$file_tag" ]; then
    echo "error: tag '$tag' does not match VAULT_VERSION in $name ('$file_tag')" >&2
    status=1
  fi
}

# Checks the single "**Vault version:**" line of the guides against the tag.
check_guides_version() {
  local name="${GUIDES_FILE#"$ROOT"/}"
  local lines count guides_tag

  if [ ! -f "$GUIDES_FILE" ]; then
    echo "error: $name not found" >&2
    status=1
    return
  fi

  lines="$(grep -E "$GUIDES_VERSION_REGEX" "$GUIDES_FILE" || true)"
  if [ -z "$lines" ]; then
    count=0
  else
    count="$(printf '%s\n' "$lines" | wc -l | tr -d '[:space:]')"
  fi

  if [ "$count" -eq 0 ]; then
    echo "error: no '**Vault version:**' line found in $name" >&2
    status=1
    return
  fi
  if [ "$count" -gt 1 ]; then
    echo "error: $count '**Vault version:**' lines found in $name (expected 1)" >&2
    status=1
    return
  fi

  guides_tag="${lines#\*\*Vault version:\*\* }"
  if [ "$tag" != "$guides_tag" ]; then
    echo "error: tag '$tag' does not match $name Vault version ('$guides_tag')" >&2
    status=1
  fi
}

check_guides_version
check_vault_version "$CLI_FILE"
check_vault_version "$INSTALL_FILE"

if [ "$status" -eq 0 ]; then
  echo "Tag $tag matches VERSION, README.md, docs/guides/vault.md, cli/bin/vault and install.sh"
fi

exit "$status"
