#!/usr/bin/env bash
# Usage: scripts/ci/setup_buildx.sh
# CI-only. Registers QEMU binfmt handlers for arm64 (pinned
# tonistiigi/binfmt image) and creates/selects a docker-container buildx
# builder named vault-builder, so `docker buildx build` can target
# linux/amd64 and linux/arm64. Reuses the builder when it already exists.
set -euo pipefail

BINFMT_IMAGE="${BINFMT_IMAGE:-tonistiigi/binfmt:qemu-v10.2.3}"
BUILDER="${BUILDER:-vault-builder}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

echo "setup-buildx: registering QEMU binfmt handlers ($BINFMT_IMAGE)"
docker run --privileged --rm "$BINFMT_IMAGE" --install arm64

if docker buildx inspect "$BUILDER" >/dev/null 2>&1; then
  echo "setup-buildx: reusing builder $BUILDER"
  docker buildx use "$BUILDER"
else
  echo "setup-buildx: creating builder $BUILDER"
  docker buildx create --name "$BUILDER" --driver docker-container --use
fi

docker buildx inspect --bootstrap "$BUILDER"
