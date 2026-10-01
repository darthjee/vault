#!/usr/bin/env bats
# Stubs (docker, sleep, dockerd-entrypoint.sh) are invoked indirectly by the
# code under test.
# shellcheck disable=SC1091,SC2329

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  source "$BATS_TEST_DIRNAME/../../source/lib/dockerd.sh"

  CALLS_FILE="$BATS_TEST_TMPDIR/calls"
  : > "$CALLS_FILE"

  sleep() { echo "sleep $*" >> "$CALLS_FILE"; }
}

# Stubs `docker info` to fail <n> times, then succeed.
stub_docker_ready_after() {
  FAILURES="$1"
  docker() {
    echo "docker $*" >> "$CALLS_FILE"
    local count
    count="$(grep -c '^docker ' "$CALLS_FILE")"
    [ "$count" -gt "$FAILURES" ]
  }
}

@test "dockerd_start runs the dind entrypoint on the unix socket only" {
  dockerd-entrypoint.sh() { echo "dockerd-entrypoint.sh $*" >> "$CALLS_FILE"; }

  dockerd_start
  [ -n "$DOCKERD_PID" ]
  wait "$DOCKERD_PID"

  run cat "$CALLS_FILE"
  assert_output "dockerd-entrypoint.sh dockerd --host=unix:///var/run/docker.sock"
}

@test "dockerd_wait succeeds immediately when docker is ready" {
  stub_docker_ready_after 0

  run dockerd_wait 30
  assert_success
  assert_output ""

  run cat "$CALLS_FILE"
  assert_output "docker info"
}

@test "dockerd_wait succeeds after a few failed polls" {
  stub_docker_ready_after 3

  run dockerd_wait 30
  assert_success

  run grep -c '^docker info$' "$CALLS_FILE"
  assert_output "4"
  run grep -c '^sleep 1$' "$CALLS_FILE"
  assert_output "3"
}

@test "dockerd_wait times out with the hint after <timeout> polls" {
  stub_docker_ready_after 1000

  run dockerd_wait 5
  assert_failure 1
  assert_output "dockerd failed to start; are you running with --privileged (or the sysbox runtime)?"

  run grep -c '^docker info$' "$CALLS_FILE"
  assert_output "5"
}

@test "dockerd_stop terminates the process and waits for it" {
  unset -f sleep
  command sleep 60 &
  local pid="$!"

  dockerd_stop "$pid"

  run kill -0 "$pid"
  assert_failure
}

@test "dockerd_stop ignores an already-dead process" {
  unset -f sleep
  command true &
  local pid="$!"
  wait "$pid"

  run dockerd_stop "$pid"
  assert_success
}

@test "dockerd_privileges_hint prints the hint" {
  run dockerd_privileges_hint
  assert_output "dockerd failed to start; are you running with --privileged (or the sysbox runtime)?"
}
