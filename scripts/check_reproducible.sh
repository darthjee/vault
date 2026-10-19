#!/usr/bin/env bash
# Usage: [SOURCE_DATE_EPOCH=0] [APK_REFRESH=YYYY-MM] [DOCKER_VERSION=...] \
#          [BUILDER=vault-builder] [BUILDKIT_IMAGE=moby/buildkit:v0.33.1] \
#          scripts/check_reproducible.sh
# Manual check only: it is NOT run in CI (two full no-cache builds).
# Builds with the docker-container buildx builder $BUILDER (same defaults as
# the Makefile), creating it from $BUILDKIT_IMAGE when it does not exist: the
# default `docker` driver on the classic image store ignores
# rewrite-timestamp, so the check would always report differences there.
# Builds the image twice with --no-cache, the same SOURCE_DATE_EPOCH (default
# 0), the same APK_REFRESH (default: current UTC month, `date -u +%Y-%m`) and
# rewrite-timestamp=true, loading the results as vault-repro-check:a and
# vault-repro-check:b. Runs scripts/bundle_cli.sh first when build/vault is
# missing. Compares `docker image inspect --format '{{json .RootFS.Layers}}'`
# of both images and prints "reproducible: N layers identical" (exit 0) or
# the indexes of the layers that differ (exit 1). Both tags are always
# removed.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-0}"
export SOURCE_DATE_EPOCH
APK_REFRESH="${APK_REFRESH:-$(date -u +%Y-%m)}"
BUILDER="${BUILDER:-vault-builder}"
BUILDKIT_IMAGE="${BUILDKIT_IMAGE:-moby/buildkit:v0.33.1}"
CHECK_IMAGE="vault-repro-check"
TAG_A="$CHECK_IMAGE:a"
TAG_B="$CHECK_IMAGE:b"

main() {
  local layers_a layers_b

  if [ ! -e build/vault ]; then
    scripts/bundle_cli.sh
  fi

  ensure_builder

  trap _cleanup EXIT
  build_image "$TAG_A"
  build_image "$TAG_B"

  layers_a="$(image_layers "$TAG_A")"
  layers_b="$(image_layers "$TAG_B")"
  compare_layers "$layers_a" "$layers_b"
}

# Creates the $BUILDER docker-container builder when it does not exist yet.
ensure_builder() {
  if docker buildx inspect "$BUILDER" >/dev/null 2>&1; then
    return 0
  fi

  echo "check-reproducible: creating builder $BUILDER ($BUILDKIT_IMAGE)"
  docker buildx create --name "$BUILDER" --driver docker-container \
    --driver-opt "image=$BUILDKIT_IMAGE"
}

# Builds the image with no cache and loads it under the given tag.
build_image() {
  local tag="$1"
  local args=(
    --builder "$BUILDER"
    --no-cache
    --build-arg "APK_REFRESH=$APK_REFRESH"
    --output "type=docker,rewrite-timestamp=true"
    -t "$tag"
  )

  if [ -n "${DOCKER_VERSION:-}" ]; then
    args+=(--build-arg "DOCKER_VERSION=$DOCKER_VERSION")
  fi

  echo "check-reproducible: building $tag (SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH, APK_REFRESH=$APK_REFRESH)"
  docker buildx build "${args[@]}" .
}

# Prints the layer digests of the given image, one per line.
image_layers() {
  local json
  json="$(docker image inspect --format '{{json .RootFS.Layers}}' "$1")"
  printf '%s\n' "$json" | tr -d '[]" ' | tr ',' '\n' | sed '/^$/d'
}

# Compares two newline-separated digest lists by index. Exits 1 on mismatch.
compare_layers() {
  local -a a b
  local count i diffs=()

  mapfile -t a <<<"$1"
  mapfile -t b <<<"$2"
  [ -n "$1" ] || a=()
  [ -n "$2" ] || b=()

  count="${#a[@]}"
  if [ "${#b[@]}" -gt "$count" ]; then
    count="${#b[@]}"
  fi

  for ((i = 0; i < count; i++)); do
    if [ "${a[i]:-}" != "${b[i]:-}" ]; then
      diffs+=("$i")
    fi
  done

  if [ "${#diffs[@]}" -eq 0 ]; then
    echo "reproducible: $count layers identical"
    return 0
  fi

  echo "check-reproducible: layers differ at index(es): ${diffs[*]} (${#a[@]} vs ${#b[@]} layers)" >&2
  return 1
}

_cleanup() {
  docker image rm -f "$TAG_A" "$TAG_B" >/dev/null 2>&1 || true
}

main "$@"
