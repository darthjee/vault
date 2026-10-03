#!/usr/bin/env bash
# Usage: scripts/lint.sh
# Runs shellcheck (in Docker, with -x so sourced files are followed) over,
# whichever exist:
#   - every *.sh and *.bats file under source/, scripts/, cli/ and test/
#     (test/ includes test/lib/, test/cli/ and test/install/);
#   - cli/bin/vault, cli/completion/vault.bash and install.sh (by path).
set -euo pipefail

SHELLCHECK_IMAGE="${SHELLCHECK_IMAGE:-koalaman/shellcheck:v0.11.0}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

dirs=()
for dir in source scripts cli test; do
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

for file in cli/bin/vault cli/completion/vault.bash install.sh; do
  if [ -f "$file" ]; then
    files+=("$file")
  fi
done

if [ "${#files[@]}" -eq 0 ]; then
  echo "no shell files found to lint"
  exit 0
fi

echo "shellcheck ($SHELLCHECK_IMAGE): ${#files[@]} file(s)"
docker run --rm -v "$PWD:/mnt:ro" -w /mnt "$SHELLCHECK_IMAGE" -x "${files[@]}"
