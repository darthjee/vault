#!/usr/bin/env bash
# Usage: [RELEASE_IMAGE=darthjee/vault] [PUSH=true|false] [DOCKER_VERSION=...] \
#          scripts/release.sh X.Y.Z
# Builds the image for linux/amd64 and linux/arm64 with docker buildx and
# tags it as $RELEASE_IMAGE:X.Y.Z and $RELEASE_IMAGE:latest. Pushes when
# PUSH=true (default). With PUSH=false the multi-platform result stays in
# the buildx cache and is not loaded into the local image store.
# Requires a buildx builder able to target both platforms
# (see scripts/ci/setup_buildx.sh).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

RELEASE_IMAGE="${RELEASE_IMAGE:-darthjee/vault}"
PUSH="${PUSH:-true}"
PLATFORMS="linux/amd64,linux/arm64"

tag="${1:-}"

if [ -z "$tag" ]; then
  echo "usage: $0 X.Y.Z" >&2
  exit 1
fi

case "$PUSH" in
  true | false) ;;
  *)
    echo "release: PUSH must be 'true' or 'false' (got '$PUSH')" >&2
    exit 1
    ;;
esac

args=(
  --platform "$PLATFORMS"
  -t "$RELEASE_IMAGE:$tag"
  -t "$RELEASE_IMAGE:latest"
)

if [ -n "${DOCKER_VERSION:-}" ]; then
  args+=(--build-arg "DOCKER_VERSION=$DOCKER_VERSION")
fi

if [ "$PUSH" = "true" ]; then
  args+=(--push)
fi

echo "release: building $RELEASE_IMAGE:$tag and :latest for $PLATFORMS (push=$PUSH)"
docker buildx build "${args[@]}" .
