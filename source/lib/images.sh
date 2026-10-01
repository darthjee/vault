#!/usr/bin/env bash
# Library: preload image tarballs into the inner Docker daemon.
# Sourcing this file only defines functions.

# Loads every *.tar in <dir> with `docker load`, in glob order.
# A missing directory or one without tarballs is skipped silently.
# Stops at the first failure, naming the file, and returns 1.
# Usage: images_load_dir <dir>
images_load_dir() {
  local dir="$1"
  local tar

  for tar in "$dir"/*.tar; do
    [ -f "$tar" ] || continue

    if ! _images_load "$tar"; then
      echo "failed to load image tarball: $tar" >&2
      return 1
    fi
  done
}

_images_load() {
  local tar="$1"
  docker load -i "$tar"
}
