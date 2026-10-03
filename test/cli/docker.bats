#!/usr/bin/env bats
# Tests for cli/lib/docker.sh and the docker stub harness.
# shellcheck disable=SC2154 # output/stderr/status are set by bats' run

bats_require_minimum_version 1.5.0

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  load helpers/docker_stub

  ROOT="$BATS_TEST_DIRNAME/../.."
  # shellcheck source=SCRIPTDIR/../../cli/lib/docker.sh
  source "$ROOT/cli/lib/docker.sh"
  docker_stub_setup
}

@test "docker_run_cmd forwards its arguments verbatim" {
  run docker_run_cmd run --name "my app" -e "A=b c" image

  assert_success
  assert_docker_called run --name "my app" -e "A=b c" image
  assert_equal "$(docker_stub_count run)" 1
}

@test "docker_run_cmd keeps empty arguments" {
  run docker_run_cmd exec "" x

  assert_success
  assert_docker_called exec "" x
}

@test "docker_run_cmd returns the stdout, stderr and status of docker" {
  docker_stub_set ps "out" 3 "err"

  run --separate-stderr docker_run_cmd ps

  assert_failure 3
  assert_output "out"
  assert_equal "$stderr" "err"
}

@test "the default docker info lists runc only and no rootless" {
  run docker_run_cmd info

  assert_success
  assert_line --index 0 "$DOCKER_STUB_INFO_RUNC"
  assert_line --index 1 "$DOCKER_STUB_SECURITY_DEFAULT"
}

@test "assert_docker_not_called fails once the subcommand was called" {
  assert_docker_not_called info
  docker_run_cmd info >/dev/null

  run assert_docker_not_called info

  assert_failure
}

@test "docker_available succeeds when docker is on PATH" {
  run docker_available

  assert_success
}

@test "docker_available fails when docker is not on PATH" {
  docker_stub_hide

  run docker_available

  assert_failure
}
