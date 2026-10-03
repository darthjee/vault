#!/usr/bin/env bash
# Usage: scripts/bundle_cli.sh
# Builds the self-contained CLI executable build/vault from cli/bin/vault:
# the "# BEGIN LIBS" ... "# END LIBS" block (markers included) is replaced
# by the content of the cli/lib/*.sh libraries, concatenated in the fixed
# order listed in LIBS below (not glob order). Output mode is 0755.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SOURCE="cli/bin/vault"
LIB_DIR="cli/lib"
BUILD_DIR="build"
OUTPUT="$BUILD_DIR/vault"
BEGIN_MARKER="# BEGIN LIBS"
END_MARKER="# END LIBS"

# Fixed bundle order. Every cli/lib/*.sh file must be listed here.
LIBS=(
  output.sh
  usage.sh
)

fail() {
  echo "bundle-cli: $1" >&2
  exit 1
}

check_source() {
  [ -f "$SOURCE" ] || fail "source not found: $SOURCE"
}

check_markers() {
  local begin_count end_count begin_line end_line

  begin_count="$(grep -cxF "$BEGIN_MARKER" "$SOURCE" || true)"
  end_count="$(grep -cxF "$END_MARKER" "$SOURCE" || true)"

  [ "$begin_count" -ne 0 ] || fail "marker '$BEGIN_MARKER' not found in $SOURCE"
  [ "$end_count" -ne 0 ] || fail "marker '$END_MARKER' not found in $SOURCE"
  [ "$begin_count" -eq 1 ] || fail "marker '$BEGIN_MARKER' appears $begin_count times in $SOURCE"
  [ "$end_count" -eq 1 ] || fail "marker '$END_MARKER' appears $end_count times in $SOURCE"

  begin_line="$(grep -nxF "$BEGIN_MARKER" "$SOURCE" | cut -d: -f1)"
  end_line="$(grep -nxF "$END_MARKER" "$SOURCE" | cut -d: -f1)"

  [ "$begin_line" -lt "$end_line" ] || fail "marker '$END_MARKER' comes before '$BEGIN_MARKER' in $SOURCE"
}

check_libs() {
  local lib file name listed

  for lib in "${LIBS[@]}"; do
    [ -f "$LIB_DIR/$lib" ] || fail "library listed but missing: $LIB_DIR/$lib"
  done

  for file in "$LIB_DIR"/*.sh; do
    [ -e "$file" ] || continue
    name="$(basename "$file")"
    listed=false
    for lib in "${LIBS[@]}"; do
      if [ "$lib" = "$name" ]; then
        listed=true
        break
      fi
    done
    [ "$listed" = true ] || fail "library not in the bundle list: $LIB_DIR/$name (add it to LIBS in scripts/bundle_cli.sh)"
  done
}

write_bundle() {
  local tmp_file lib

  mkdir -p "$BUILD_DIR"
  tmp_file="$(mktemp "$BUILD_DIR/vault.XXXXXX")"
  # shellcheck disable=SC2064
  trap "rm -f '$tmp_file'" EXIT

  {
    sed "/^${BEGIN_MARKER}\$/,\$d" "$SOURCE"
    for lib in "${LIBS[@]}"; do
      cat "$LIB_DIR/$lib"
    done
    sed "1,/^${END_MARKER}\$/d" "$SOURCE"
  } > "$tmp_file"

  chmod 0755 "$tmp_file"
  mv "$tmp_file" "$OUTPUT"
  trap - EXIT
}

check_source
check_markers
check_libs
write_bundle
echo "bundle-cli: wrote $OUTPUT"
