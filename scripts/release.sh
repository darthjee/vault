#!/usr/bin/env bash
# Usage: [RELEASE_IMAGE=darthjee/vault] [PUSH=true|false] [DOCKER_VERSION=...] \
#          [SOURCE_DATE_EPOCH=0] [APK_REFRESH=YYYY-MM] \
#          scripts/release.sh X.Y.Z
# Builds the image for linux/amd64 and linux/arm64 with docker buildx and
# tags it as $RELEASE_IMAGE:X.Y.Z and $RELEASE_IMAGE:latest. Pushes when
# PUSH=true (default). With PUSH=false the multi-platform result stays in
# the buildx cache and is not loaded into the local image store.
# The build is reproducible: SOURCE_DATE_EPOCH (default 0) is exported for
# docker buildx and every layer timestamp is rewritten to it
# (rewrite-timestamp=true), so layer digests depend only on content.
# APK_REFRESH (default: current UTC month, `date -u +%Y-%m`) is passed as a
# build arg so the `apk add` layer is rebuilt once a month.
# Requires a buildx builder able to target both platforms
# (see scripts/ci/setup_buildx.sh).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

RELEASE_IMAGE="${RELEASE_IMAGE:-darthjee/vault}"
PUSH="${PUSH:-true}"
PLATFORMS="linux/amd64,linux/arm64"
SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-0}"
export SOURCE_DATE_EPOCH
APK_REFRESH="${APK_REFRESH:-$(date -u +%Y-%m)}"

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
  --build-arg "APK_REFRESH=$APK_REFRESH"
  --output "type=image,push=$PUSH,rewrite-timestamp=true"
)

if [ -n "${DOCKER_VERSION:-}" ]; then
  args+=(--build-arg "DOCKER_VERSION=$DOCKER_VERSION")
fi

echo "release: building $RELEASE_IMAGE:$tag and :latest for $PLATFORMS (push=$PUSH, SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH, APK_REFRESH=$APK_REFRESH)"
docker buildx build "${args[@]}" .
