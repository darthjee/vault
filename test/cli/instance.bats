#!/usr/bin/env bats
# Tests for cli/lib/instance.sh (instance state and TTY flags).
# shellcheck disable=SC2154 # output/stderr/status are set by bats' run

bats_require_minimum_version 1.5.0

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  load helpers/docker_stub

  ROOT="$BATS_TEST_DIRNAME/../.."
  # shellcheck source=SCRIPTDIR/../../cli/lib/output.sh
  source "$ROOT/cli/lib/output.sh"
  # shellcheck source=SCRIPTDIR/../../cli/lib/docker.sh
  source "$ROOT/cli/lib/docker.sh"
  # shellcheck source=SCRIPTDIR/../../cli/lib/naming.sh
  source "$ROOT/cli/lib/naming.sh"
  # shellcheck source=SCRIPTDIR/../../cli/lib/instance.sh
  source "$ROOT/cli/lib/instance.sh"
  docker_stub_setup

  NO_SUCH='Error response from daemon: No such object: vault-app'
  DAEMON_DOWN='Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?'
}

@test "instance_state calls docker inspect once with the running format" {
  docker_stub_set inspect true

  instance_state app

  assert_equal "$(docker_stub_count inspect)" 1
  assert_docker_called inspect --format '{{.State.Running}}' vault-app
}

@test "instance_state reports running" {
  docker_stub_set inspect true

  instance_state app

  assert_equal "$INSTANCE_STATE" running
}

@test "instance_state reports stopped" {
  docker_stub_set inspect false

  run --separate-stderr instance_state app
  assert_success
  assert_equal "$stderr" ""

  instance_state app
  assert_equal "$INSTANCE_STATE" stopped
}

@test "instance_state reports missing on No such object, without docker's error" {
  docker_stub_set inspect "" 1 "$NO_SUCH"

  run --separate-stderr instance_state app
  assert_success
  assert_output ""
  assert_equal "$stderr" ""

  instance_state app 2>/dev/null
  assert_equal "$INSTANCE_STATE" missing
}

@test "instance_state fails when the daemon is unreachable" {
  docker_stub_set inspect "" 1 "$DAEMON_DOWN"

  run --separate-stderr instance_state app

  assert_failure 1
  assert_output ""
  assert_equal "$stderr" "$DAEMON_DOWN
vault: error: cannot reach the Docker daemon
vault: hint: is Docker running, and can this user access it?"
  assert_docker_not_called info
}

@test "instance_require_running passes when running" {
  docker_stub_set inspect true

  run --separate-stderr instance_require_running app

  assert_success
  assert_equal "$stderr" ""
}

@test "instance_require_running fails when stopped" {
  docker_stub_set inspect false

  run --separate-stderr instance_require_running app

  assert_failure 1
  assert_equal "$stderr" "vault: error: instance vault-app is not running"
}

@test "instance_require_running fails when missing" {
  docker_stub_set inspect "" 1 "$NO_SUCH"

  run --separate-stderr instance_require_running app

  assert_failure 1
  assert_equal "$stderr" "vault: error: instance vault-app is not running"
}

@test "instance_require_running fails when the daemon is unreachable" {
  docker_stub_set inspect "" 1 "$DAEMON_DOWN"

  run --separate-stderr instance_require_running app

  assert_failure 1
  assert_equal "$stderr" "$DAEMON_DOWN
vault: error: cannot reach the Docker daemon
vault: hint: is Docker running, and can this user access it?"
}

@test "instance_tty_flags is empty without a TTY" {
  instance_tty_flags </dev/null >/dev/null

  assert_equal "${#INSTANCE_TTY_ARGS[@]}" 0
}
