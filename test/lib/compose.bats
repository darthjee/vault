#!/usr/bin/env bats
# The docker stub is invoked indirectly by the code under test.
# shellcheck disable=SC1091,SC2329,SC2034

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  source "$BATS_TEST_DIRNAME/../../source/lib/compose.sh"

  CALLS_FILE="$BATS_TEST_TMPDIR/calls"
  : > "$CALLS_FILE"

  docker() {
    local arg
    {
      printf 'docker'
      for arg in "$@"; do printf ' [%s]' "$arg"; done
      printf '\n'
    } >> "$CALLS_FILE"
  }
}

@test "compose_run with no args and an unset array runs compose up" {
  unset COMPOSE_UP_ARGS

  compose_run
  [ -n "$COMPOSE_PID" ]
  wait "$COMPOSE_PID"

  run cat "$CALLS_FILE"
  assert_output "docker [compose] [up]"
}

@test "compose_run with no args and an empty array runs compose up" {
  COMPOSE_UP_ARGS=()

  compose_run
  wait "$COMPOSE_PID"

  run cat "$CALLS_FILE"
  assert_output "docker [compose] [up]"
}

@test "compose_run passes COMPOSE_UP_ARGS as separate args" {
  COMPOSE_UP_ARGS=(--build --abort-on-container-exit)

  compose_run
  wait "$COMPOSE_PID"

  run cat "$CALLS_FILE"
  assert_output "docker [compose] [up] [--build] [--abort-on-container-exit]"
}

@test "compose_run passes through its args instead of up" {
  COMPOSE_UP_ARGS=(--build)

  compose_run config
  wait "$COMPOSE_PID"

  run cat "$CALLS_FILE"
  assert_output "docker [compose] [config]"
}

@test "compose_run keeps passthrough args with spaces as single args" {
  compose_run exec app sh -c "echo hello world"
  wait "$COMPOSE_PID"

  run cat "$CALLS_FILE"
  assert_output "docker [compose] [exec] [app] [sh] [-c] [echo hello world]"
}

@test "compose_down runs compose down" {
  run compose_down
  assert_success

  run cat "$CALLS_FILE"
  assert_output "docker [compose] [down]"
}

@test "compose_down propagates a failure" {
  docker() { return 4; }

  run compose_down
  assert_failure 4
}

@test "compose_wait returns the job's exit code" {
  docker() { return 3; }

  compose_run
  local status=0
  compose_wait "$COMPOSE_PID" || status=$?

  assert_equal "$status" 3
}

@test "compose_wait returns 0 for a successful job" {
  compose_run
  local status=0
  compose_wait "$COMPOSE_PID" || status=$?

  assert_equal "$status" 0
}

@test "compose_wait re-waits after a trapped signal interrupts it" {
  docker() { command sleep 1; return 5; }
  SIGNALS_HANDLED=0
  trap 'SIGNALS_HANDLED=$((SIGNALS_HANDLED + 1))' USR1

  local self="$BASHPID"
  compose_run
  ( command sleep 0.2; kill -USR1 "$self" ) &
  local status=0
  compose_wait "$COMPOSE_PID" || status=$?
  trap - USR1

  assert_equal "$SIGNALS_HANDLED" 1
  assert_equal "$status" 5
}
