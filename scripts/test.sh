#!/usr/bin/env bash
# Usage: scripts/test.sh
# Runs the bats unit tests under test/lib/ (in Docker).
set -euo pipefail

BATS_IMAGE="${BATS_IMAGE:-bats/bats:1.14.0}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ ! -d test/lib ] || [ -z "$(find test/lib -type f -name '*.bats' -print -quit)" ]; then
  echo "no tests found in test/lib/"
  exit 0
fi

docker run --rm -v "$PWD:/code:ro" -w /code "$BATS_IMAGE" --recursive test/lib
