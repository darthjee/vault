#!/usr/bin/env bats
# Tests for scripts/check_tag_version.sh. The script runs on a temp work tree
# holding the version files; docs/guides/vault.md is a minimal fixture.
# shellcheck disable=SC2154 # output/stderr/status are set by bats' run

bats_require_minimum_version 1.5.0

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  REPO_ROOT="$BATS_TEST_DIRNAME/../.."
  WORK="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$WORK/cli/bin" "$WORK/docs/guides"
  cp -R "$REPO_ROOT/scripts" "$WORK/"

  printf '1.2.3\n' > "$WORK/VERSION"
  printf '# Vault\n\n**Current Version:** 1.2.3\n' > "$WORK/README.md"
  printf '#!/usr/bin/env bash\nVAULT_VERSION="1.2.3"\n' > "$WORK/cli/bin/vault"
  printf '#!/bin/sh\nVAULT_VERSION="1.2.3"\n' > "$WORK/install.sh"
  GUIDES="$WORK/docs/guides/vault.md"
  printf '# Vault guides\n\n**Vault version:** 1.2.3\n' > "$GUIDES"

  SCRIPT="$WORK/scripts/check_tag_version.sh"
}

run_check() {
  run --separate-stderr bash "$SCRIPT" "$@"
}

@test "a matching tag passes" {
  run_check 1.2.3
  assert_success
  assert_equal "$output" "Tag 1.2.3 matches VERSION, README.md, docs/guides/vault.md, cli/bin/vault and install.sh"
}

@test "without a tag it prints usage and exits 1" {
  run_check
  assert_failure 1
  assert_equal "$stderr" "usage: $SCRIPT X.Y.Z"
}

@test "a guides version mismatch fails" {
  printf '# Vault guides\n\n**Vault version:** 1.2.2\n' > "$GUIDES"
  run_check 1.2.3
  assert_failure 1
  assert_equal "$stderr" "error: tag '1.2.3' does not match docs/guides/vault.md Vault version ('1.2.2')"
}

@test "a missing guides file fails" {
  rm "$GUIDES"
  run_check 1.2.3
  assert_failure 1
  assert_equal "$stderr" "error: docs/guides/vault.md not found"
}

@test "a guides file without the version line fails" {
  printf '# Vault guides\n' > "$GUIDES"
  run_check 1.2.3
  assert_failure 1
  assert_equal "$stderr" "error: no '**Vault version:**' line found in docs/guides/vault.md"
}

@test "a guides file with two version lines fails" {
  printf '**Vault version:** 1.2.3\n' >> "$GUIDES"
  run_check 1.2.3
  assert_failure 1
  assert_equal "$stderr" "error: 2 '**Vault version:**' lines found in docs/guides/vault.md (expected 1)"
}

@test "a VERSION mismatch fails" {
  printf '1.2.2\n' > "$WORK/VERSION"
  run_check 1.2.3
  assert_failure 1
  assert_equal "$stderr" "error: tag '1.2.3' does not match VERSION file ('1.2.2')"
}

@test "a README mismatch fails" {
  printf '**Current Version:** 1.2.2\n' > "$WORK/README.md"
  run_check 1.2.3
  assert_failure 1
  assert_equal "$stderr" "error: tag '1.2.3' does not match README.md Current Version ('1.2.2')"
}

@test "a VAULT_VERSION mismatch fails" {
  printf '#!/bin/sh\nVAULT_VERSION="1.2.2"\n' > "$WORK/install.sh"
  run_check 1.2.3
  assert_failure 1
  assert_equal "$stderr" "error: tag '1.2.3' does not match VAULT_VERSION in install.sh ('1.2.2')"
}

@test "a missing VAULT_VERSION file fails" {
  rm "$WORK/cli/bin/vault"
  run_check 1.2.3
  assert_failure 1
  assert_equal "$stderr" "error: cli/bin/vault not found"
}

@test "duplicated VAULT_VERSION lines fail" {
  printf 'VAULT_VERSION="1.2.3"\n' >> "$WORK/cli/bin/vault"
  run_check 1.2.3
  assert_failure 1
  assert_equal "$stderr" "error: 2 'VAULT_VERSION=\"X.Y.Z\"' lines found in cli/bin/vault (expected 1)"
}

@test "every mismatch is reported in one run" {
  printf '1.2.2\n' > "$WORK/VERSION"
  printf '**Vault version:** 1.2.2\n' > "$GUIDES"
  run_check 1.2.3
  assert_failure 1
  assert_equal "$stderr" "error: tag '1.2.3' does not match VERSION file ('1.2.2')
error: tag '1.2.3' does not match docs/guides/vault.md Vault version ('1.2.2')"
}
