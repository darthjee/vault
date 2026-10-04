#!/usr/bin/env bats
# Skeleton tests for the vault CLI: each case runs against the source tree
# (cli/bin/vault) and the bundle (build/vault, built by scripts/test.sh).
# shellcheck disable=SC2154 # output/stderr/status are set by bats' run

bats_require_minimum_version 1.5.0

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  ROOT="$BATS_TEST_DIRNAME/../.."
  SOURCE_VAULT="$ROOT/cli/bin/vault"
  BUNDLE_VAULT="$ROOT/build/vault"
  EXPECTED_VERSION="$(cat "$ROOT/VERSION")"
}

# Fails with a clear message when the executable under test is missing.
require_executable() {
  if [ ! -x "$1" ]; then
    fail "executable not found: $1 (run make bundle-cli)"
  fi
}

check_version() {
  require_executable "$1"
  run --separate-stderr "$1" version

  assert_success
  assert_output "vault $EXPECTED_VERSION"
  assert_equal "$stderr" ""
}

check_help() {
  local vault="$1"
  local arg="$2"
  local command

  require_executable "$vault"
  run --separate-stderr "$vault" "$arg"

  assert_success
  assert_line --index 0 "Usage: vault <command> [options] [dir] [args]"
  for command in up down logs status compose run version help; do
    assert_line --regexp "^  $command +[A-Z]"
  done
  assert_line --partial "-h, --help"
  assert_equal "$stderr" ""
}

check_no_command() {
  local vault="$1"
  local usage

  require_executable "$vault"
  usage="$("$vault" help)"
  run --separate-stderr "$vault"

  assert_failure 2
  assert_output ""
  assert_equal "$stderr" "$usage"
}

check_unknown_command() {
  require_executable "$1"
  run --separate-stderr "$1" foo

  assert_failure 2
  assert_output ""
  assert_equal "$stderr" "vault: error: unknown command 'foo'
vault: hint: run \"vault help\""
}

@test "source: version prints vault <VERSION>" {
  check_version "$SOURCE_VAULT"
}

@test "bundle: version prints vault <VERSION>" {
  check_version "$BUNDLE_VAULT"
}

@test "source: help prints the usage to stdout" {
  check_help "$SOURCE_VAULT" help
}

@test "bundle: help prints the usage to stdout" {
  check_help "$BUNDLE_VAULT" help
}

@test "source: -h prints the usage to stdout" {
  check_help "$SOURCE_VAULT" -h
}

@test "bundle: -h prints the usage to stdout" {
  check_help "$BUNDLE_VAULT" -h
}

@test "source: --help prints the usage to stdout" {
  check_help "$SOURCE_VAULT" --help
}

@test "bundle: --help prints the usage to stdout" {
  check_help "$BUNDLE_VAULT" --help
}

@test "source: no command prints the usage to stderr and exits 2" {
  check_no_command "$SOURCE_VAULT"
}

@test "bundle: no command prints the usage to stderr and exits 2" {
  check_no_command "$BUNDLE_VAULT"
}

@test "source: an unknown command prints the error and the hint, exits 2" {
  check_unknown_command "$SOURCE_VAULT"
}

@test "bundle: an unknown command prints the error and the hint, exits 2" {
  check_unknown_command "$BUNDLE_VAULT"
}

@test "bundle: runs away from cli/lib (sources nothing at run time)" {
  require_executable "$BUNDLE_VAULT"
  local copy="$BATS_TEST_TMPDIR/bin/vault"
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  cp "$BUNDLE_VAULT" "$copy"
  chmod 0755 "$copy"

  run ! grep -E '^[[:space:]]*(source|\.)[[:space:]]' "$copy"

  check_version "$copy"
  check_help "$copy" help
  check_unknown_command "$copy"
}
