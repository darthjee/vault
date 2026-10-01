#!/usr/bin/env bash
# Usage: scripts/lint.sh
# Runs shellcheck (in Docker) over every *.sh and *.bats file under
# source/, scripts/ and test/ (whichever exist).
set -euo pipefail

SHELLCHECK_IMAGE="${SHELLCHECK_IMAGE:-koalaman/shellcheck:v0.11.0}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

dirs=()
for dir in source scripts test; do
  if [ -d "$dir" ]; then
    dirs+=("$dir")
  fi
done

files=()
if [ "${#dirs[@]}" -gt 0 ]; then
  while IFS= read -r -d '' file; do
    files+=("$file")
  done < <(find "${dirs[@]}" -type f \( -name '*.sh' -o -name '*.bats' \) -print0 | sort -z)
fi

if [ "${#files[@]}" -eq 0 ]; then
  echo "no shell files found to lint"
  exit 0
fi

echo "shellcheck ($SHELLCHECK_IMAGE): ${#files[@]} file(s)"
docker run --rm -v "$PWD:/mnt:ro" -w /mnt "$SHELLCHECK_IMAGE" "${files[@]}"
