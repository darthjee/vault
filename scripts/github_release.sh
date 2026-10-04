#!/usr/bin/env bash
# Usage: GITHUB_TOKEN=... [GITHUB_REPOSITORY=darthjee/vault] \
#          scripts/github_release.sh X.Y.Z
# Publishes the CLI for tag X.Y.Z as a GitHub release, using the gh CLI:
#   1. builds the CLI bundle build/vault (scripts/bundle_cli.sh);
#   2. stages the assets in build/github-release/: vault (build/vault),
#      install.sh, vault.bash, _vault and SHA256SUMS (sha256sum of the four,
#      file names only);
#   3. creates the release (published, Latest, generated notes, title = tag)
#      on the existing tag, unless it already exists, in which case the
#      release (and its notes) is kept as is;
#   4. uploads every asset with --clobber, replacing existing ones, so the
#      script can be re-run safely.
# GITHUB_TOKEN is required and is passed to gh as GH_TOKEN.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

STAGE_DIR="build/github-release"

fail() {
  echo "github-release: $*" >&2
  exit 1
}

tag="${1:-}"

if [ -z "$tag" ]; then
  echo "usage: $0 X.Y.Z" >&2
  exit 1
fi

if [ -z "${GITHUB_TOKEN:-}" ]; then
  fail "GITHUB_TOKEN must be set"
fi
export GH_TOKEN="$GITHUB_TOKEN"

repo="${GITHUB_REPOSITORY:-darthjee/vault}"

if ! command -v gh >/dev/null 2>&1; then
  fail "gh not found in PATH"
fi

scripts/bundle_cli.sh

# Copies a source file into the staging dir under the given asset name.
stage() {
  local source="$1"
  local name="$2"
  if [ ! -f "$source" ]; then
    fail "missing asset source: $source"
  fi
  cp "$source" "$STAGE_DIR/$name"
}

rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"

stage build/vault vault
stage install.sh install.sh
stage cli/completion/vault.bash vault.bash
stage cli/completion/_vault _vault

(cd "$STAGE_DIR" && sha256sum vault install.sh vault.bash _vault > SHA256SUMS)

if gh release view "$tag" --repo "$repo" >/dev/null 2>&1; then
  echo "github-release: release $tag already exists in $repo; replacing its assets"
else
  echo "github-release: creating release $tag in $repo"
  gh release create "$tag" --repo "$repo" --title "$tag" \
    --generate-notes --latest --verify-tag
fi

gh release upload "$tag" --repo "$repo" --clobber \
  "$STAGE_DIR/vault" \
  "$STAGE_DIR/install.sh" \
  "$STAGE_DIR/vault.bash" \
  "$STAGE_DIR/_vault" \
  "$STAGE_DIR/SHA256SUMS"

echo "github-release: released $tag to $repo"
