#!/usr/bin/env bash
# Usage: [BATS_IMAGE=bats/bats:1.14.0] [BASH32_TEST_IMAGE=vault-bash32-test:local] \
#          scripts/test.sh
# Runs the bats unit tests (in Docker):
#   1. builds the CLI bundle build/vault (scripts/bundle_cli.sh) when cli/ exists;
#   2. runs test/lib/, test/cli/ and test/install/ on $BATS_IMAGE;
#   3. builds $BASH32_TEST_IMAGE from test/bash32/ and runs test/cli/ and
#      test/install/ on it (bash 3.2).
# Only directories holding *.bats files are run. Exits non-zero if any run fails.
set -euo pipefail

BATS_IMAGE="${BATS_IMAGE:-bats/bats:1.14.0}"
BASH32_TEST_IMAGE="${BASH32_TEST_IMAGE:-vault-bash32-test:local}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Prints the given directories that contain at least one *.bats file.
suites_in() {
  local dir
  for dir in "$@"; do
    if [ -d "$dir" ] && [ -n "$(find "$dir" -type f -name '*.bats' -print -quit)" ]; then
      echo "$dir"
    fi
  done
}

run_bats() {
  local image="$1"
  shift
  echo "bats ($image): $*"
  docker run --rm -v "$PWD:/code:ro" -w /code "$image" --recursive "$@"
}

main() {
  local status=0
  local suites=()
  local bash32_suites=()
  local dir

  while IFS= read -r dir; do
    suites+=("$dir")
  done < <(suites_in test/lib test/cli test/install)

  while IFS= read -r dir; do
    bash32_suites+=("$dir")
  done < <(suites_in test/cli test/install)

  if [ "${#suites[@]}" -eq 0 ]; then
    echo "no tests found in test/lib/, test/cli/ or test/install/"
    exit 0
  fi

  if [ -d cli ]; then
    scripts/bundle_cli.sh
  fi

  run_bats "$BATS_IMAGE" "${suites[@]}" || status=1

  if [ "${#bash32_suites[@]}" -gt 0 ]; then
    echo "building $BASH32_TEST_IMAGE from test/bash32/"
    if docker build -q -t "$BASH32_TEST_IMAGE" test/bash32 >/dev/null; then
      run_bats "$BASH32_TEST_IMAGE" "${bash32_suites[@]}" || status=1
    else
      echo "failed to build $BASH32_TEST_IMAGE" >&2
      status=1
    fi
  fi

  exit "$status"
}

main "$@"
