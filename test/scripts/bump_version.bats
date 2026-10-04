#!/usr/bin/env bats
# Tests for scripts/bump_version.sh. The script runs on a temp work tree
# (scripts/test.sh mounts the repo read-only) holding the files it rewrites;
# docs/guides/vault.md is a minimal fixture.
# shellcheck disable=SC2154 # output/stderr/status are set by bats' run

bats_require_minimum_version 1.5.0

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  REPO_ROOT="$BATS_TEST_DIRNAME/../.."
  WORK="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$WORK/cli/bin" "$WORK/docs/guides"
  cp -R "$REPO_ROOT/scripts" "$WORK/"

  printf '0.0.1\n' > "$WORK/VERSION"
  printf '# Vault\n\n**Current Version:** 0.0.1\n' > "$WORK/README.md"
  printf '#!/usr/bin/env bash\nVAULT_VERSION="0.0.1"\n' > "$WORK/cli/bin/vault"
  printf '#!/bin/sh\nVAULT_VERSION="0.0.1"\n' > "$WORK/install.sh"
  GUIDES="$WORK/docs/guides/vault.md"
  printf '# Vault guides\n\n**Vault version:** 0.0.1\n\nText.\n' > "$GUIDES"

  SCRIPT="$WORK/scripts/bump_version.sh"
}

run_bump() {
  run --separate-stderr bash "$SCRIPT" "$@"
}

# Prints a checksum of every file the script may write.
snapshot() {
  (cd "$WORK" && cat VERSION README.md cli/bin/vault install.sh docs/guides/vault.md 2>/dev/null | cksum)
}

@test "bumps VERSION, README, guides and VAULT_VERSION lines" {
  run_bump 1.2.3
  assert_success
  assert_equal "$output" "Version bumped to 1.2.3"
  assert_equal "$(cat "$WORK/VERSION")" "1.2.3"
  run grep -x '\*\*Current Version:\*\* 1.2.3' "$WORK/README.md"
  assert_success
  run grep -x '\*\*Vault version:\*\* 1.2.3' "$GUIDES"
  assert_success
  run grep -c 'Vault version' "$GUIDES"
  assert_output "1"
  run grep -x 'VAULT_VERSION="1.2.3"' "$WORK/cli/bin/vault"
  assert_success
  run grep -x 'VAULT_VERSION="1.2.3"' "$WORK/install.sh"
  assert_success
}

@test "without a version it prints usage and exits 1" {
  run_bump
  assert_failure 1
  assert_equal "$stderr" "usage: $SCRIPT X.Y.Z"
}

@test "an invalid version fails" {
  before="$(snapshot)"
  run_bump 1.2
  assert_failure 1
  assert_equal "$stderr" "error: invalid version '1.2' (expected X.Y.Z)"
  assert_equal "$(snapshot)" "$before"
}

@test "a missing guides file fails without writing anything" {
  rm "$GUIDES"
  before="$(snapshot)"
  run_bump 1.2.3
  assert_failure 1
  assert_equal "$stderr" "error: docs/guides/vault.md not found"
  assert_equal "$(snapshot)" "$before"
}

@test "a guides file without the version line fails without writing anything" {
  printf '# Vault guides\n' > "$GUIDES"
  before="$(snapshot)"
  run_bump 1.2.3
  assert_failure 1
  assert_equal "$stderr" "error: no '**Vault version:**' line found in docs/guides/vault.md"
  assert_equal "$(snapshot)" "$before"
}

@test "a guides file with two version lines fails without writing anything" {
  printf '**Vault version:** 0.0.1\n' >> "$GUIDES"
  before="$(snapshot)"
  run_bump 1.2.3
  assert_failure 1
  assert_equal "$stderr" "error: 2 '**Vault version:**' lines found in docs/guides/vault.md (expected 1)"
  assert_equal "$(snapshot)" "$before"
}

@test "a README without the Current Version line fails without writing anything" {
  printf '# Vault\n' > "$WORK/README.md"
  before="$(snapshot)"
  run_bump 1.2.3
  assert_failure 1
  assert_equal "$stderr" "error: no '**Current Version:**' line found in $(cd "$WORK" && pwd)/README.md"
  assert_equal "$(snapshot)" "$before"
}

@test "a missing VAULT_VERSION line fails without writing anything" {
  printf '#!/bin/sh\n' > "$WORK/install.sh"
  before="$(snapshot)"
  run_bump 1.2.3
  assert_failure 1
  assert_equal "$stderr" "error: no 'VAULT_VERSION=\"X.Y.Z\"' line found in install.sh"
  assert_equal "$(snapshot)" "$before"
}

@test "duplicated VAULT_VERSION lines fail without writing anything" {
  printf 'VAULT_VERSION="0.0.1"\n' >> "$WORK/cli/bin/vault"
  before="$(snapshot)"
  run_bump 1.2.3
  assert_failure 1
  assert_equal "$stderr" "error: 2 'VAULT_VERSION=\"X.Y.Z\"' lines found in cli/bin/vault (expected 1)"
  assert_equal "$(snapshot)" "$before"
}
