#!/usr/bin/env bash
# Usage: DOCKER_HUB_USERNAME=... DOCKER_HUB_PASSWORD=... scripts/ci/update_description.sh
# CI-only. Pushes DOCKERHUB_DESCRIPTION.md as the Docker Hub full
# description of darthjee/vault, using docker_hub.sh from darthjee/docker
# fetched at a pinned commit and verified against a pinned sha256.
#
# Note: docker_hub.sh calls curl without --fail, so a rejected login or
# PATCH does not make this script exit non-zero.
set -euo pipefail

DOCKER_HUB_SH_URL="https://raw.githubusercontent.com/darthjee/docker/91b11fb949bb0f71670e390fdc97df831c46af70/scripts/0.9.0/home/sbin/docker_hub.sh"
DOCKER_HUB_SH_SHA256="cd0cb716f77443a2a806a85599adf270e4ab3e60a74411bafe023f6b3fd1c66a"
REPOSITORY="darthjee/vault"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DESCRIPTION_FILE="$ROOT/DOCKERHUB_DESCRIPTION.md"

if [ -z "${DOCKER_HUB_USERNAME:-}" ] || [ -z "${DOCKER_HUB_PASSWORD:-}" ]; then
  echo "update-description: DOCKER_HUB_USERNAME and DOCKER_HUB_PASSWORD must be set" >&2
  exit 1
fi
export DOCKER_HUB_USERNAME DOCKER_HUB_PASSWORD

if [ ! -f "$DESCRIPTION_FILE" ]; then
  echo "update-description: $DESCRIPTION_FILE not found" >&2
  exit 1
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

echo "update-description: fetching $DOCKER_HUB_SH_URL"
curl -fsSL -o "$tmp" "$DOCKER_HUB_SH_URL"

if ! echo "$DOCKER_HUB_SH_SHA256  $tmp" | sha256sum -c - >/dev/null; then
  echo "update-description: sha256 mismatch for docker_hub.sh (expected $DOCKER_HUB_SH_SHA256)" >&2
  exit 1
fi

echo "update-description: pushing $DESCRIPTION_FILE to $REPOSITORY"
bash "$tmp" login_and_push_description "$REPOSITORY" "$DESCRIPTION_FILE"
