#!/usr/bin/env bats
# Stubs (mount/umount) are invoked indirectly by the code under test.
# shellcheck disable=SC1091,SC2329

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  source "$BATS_TEST_DIRNAME/../../source/lib/dockerd.sh"
  source "$BATS_TEST_DIRNAME/../../source/lib/preflight.sh"

  export TMPDIR="$BATS_TEST_TMPDIR"
  CALLS_FILE="$BATS_TEST_TMPDIR/calls"
  : > "$CALLS_FILE"
}

@test "preflight_check_timeout accepts a positive integer" {
  run preflight_check_timeout 30
  assert_success
  assert_output ""
}

@test "preflight_check_timeout accepts 1" {
  run preflight_check_timeout 1
  assert_success
}

@test "preflight_check_timeout rejects 0" {
  run preflight_check_timeout 0
  assert_failure 1
  assert_output "VAULT_DOCKERD_TIMEOUT must be a positive integer, got: '0'"
}

@test "preflight_check_timeout rejects a negative number" {
  run preflight_check_timeout -1
  assert_failure 1
  assert_output "VAULT_DOCKERD_TIMEOUT must be a positive integer, got: '-1'"
}

@test "preflight_check_timeout rejects a non-number" {
  run preflight_check_timeout abc
  assert_failure 1
  assert_output "VAULT_DOCKERD_TIMEOUT must be a positive integer, got: 'abc'"
}

@test "preflight_check_timeout rejects a decimal" {
  run preflight_check_timeout 1.5
  assert_failure 1
  assert_output "VAULT_DOCKERD_TIMEOUT must be a positive integer, got: '1.5'"
}

@test "preflight_check_timeout rejects an empty value" {
  run preflight_check_timeout ""
  assert_failure 1
  assert_output "VAULT_DOCKERD_TIMEOUT must be a positive integer, got: ''"
}

@test "preflight_check_privileges succeeds and unmounts when mount works" {
  mount() { echo "mount $*" >> "$CALLS_FILE"; }
  umount() { echo "umount $*" >> "$CALLS_FILE"; }

  run preflight_check_privileges
  assert_success
  assert_output ""

  run cat "$CALLS_FILE"
  assert_line --index 0 --partial "mount -t tmpfs none $BATS_TEST_TMPDIR/"
  assert_line --index 1 --partial "umount $BATS_TEST_TMPDIR/"
}

@test "preflight_check_privileges removes the probe dir on success" {
  mount() { :; }
  umount() { :; }

  run preflight_check_privileges
  assert_success
  run find "$BATS_TEST_TMPDIR" -mindepth 1 -type d
  assert_output ""
}

@test "preflight_check_privileges fails with the hint when mount fails" {
  mount() { echo "mount $*" >> "$CALLS_FILE"; return 32; }
  umount() { echo "umount $*" >> "$CALLS_FILE"; }

  run preflight_check_privileges
  assert_failure 1
  assert_output "dockerd failed to start; are you running with --privileged (or the sysbox runtime)?"

  run grep -c umount "$CALLS_FILE"
  assert_output "0"
}

@test "preflight_check_privileges removes the probe dir on failure" {
  mount() { return 32; }

  run preflight_check_privileges
  assert_failure 1
  run find "$BATS_TEST_TMPDIR" -mindepth 1 -type d
  assert_output ""
}
