#!/usr/bin/env bats
# Stubs (compose_down, dockerd_stop) are invoked indirectly by the code under
# test.
# shellcheck disable=SC1091,SC2329,SC2034

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  source "$BATS_TEST_DIRNAME/../../source/lib/compose.sh"
  source "$BATS_TEST_DIRNAME/../../source/lib/dockerd.sh"
  source "$BATS_TEST_DIRNAME/../../source/lib/signals.sh"

  CALLS_FILE="$BATS_TEST_TMPDIR/calls"
  : > "$CALLS_FILE"

  unset COMPOSE_PID DOCKERD_PID
  SIGNALS_HANDLED=0

  docker() { echo "docker $*" >> "$CALLS_FILE"; }
  compose_down() { echo "compose_down" >> "$CALLS_FILE"; }
  dockerd_stop() { echo "dockerd_stop $*" >> "$CALLS_FILE"; }
}

# `run` installs its own INT trap, so traps are read with `$(trap -p ...)`
# (a command substitution still reports the parent shell's traps).

teardown() {
  trap - TERM INT
}

@test "signals_shutdown with compose running downs compose, then stops dockerd and returns" {
  COMPOSE_PID=111
  DOCKERD_PID=222

  signals_shutdown 15
  # Reaching this line means the function returned instead of exiting.

  run cat "$CALLS_FILE"
  assert_line --index 0 "compose_down"
  assert_line --index 1 "dockerd_stop 222"
  assert_equal "${#lines[@]}" 2
}

@test "signals_shutdown warns when compose down fails and still stops dockerd" {
  COMPOSE_PID=111
  DOCKERD_PID=222
  compose_down() { echo "compose_down" >> "$CALLS_FILE"; return 1; }

  run signals_shutdown 15
  assert_success
  assert_output "vault: docker compose down failed"

  run cat "$CALLS_FILE"
  assert_line --index 0 "compose_down"
  assert_line --index 1 "dockerd_stop 222"
}

@test "signals_shutdown before compose stops dockerd and exits 143 on TERM" {
  DOCKERD_PID=222

  run signals_shutdown 15
  assert_failure 143

  run cat "$CALLS_FILE"
  assert_output "dockerd_stop 222"
}

@test "signals_shutdown before compose stops dockerd and exits 130 on INT" {
  DOCKERD_PID=222

  run signals_shutdown 2
  assert_failure 130

  run cat "$CALLS_FILE"
  assert_output "dockerd_stop 222"
}

@test "signals_shutdown before dockerd started stops nothing and exits 143" {
  run signals_shutdown 15
  assert_failure 143

  run cat "$CALLS_FILE"
  assert_output ""
}

@test "signals_shutdown ignores further signals and counts the signal" {
  COMPOSE_PID=111
  DOCKERD_PID=222

  signals_shutdown 15

  assert_equal "$SIGNALS_HANDLED" 1
  assert_equal "$(trap -p TERM)" "trap -- '' SIGTERM"
  assert_equal "$(trap -p INT)" "trap -- '' SIGINT"
}

@test "signals_ignore ignores TERM and INT" {
  signals_ignore

  assert_equal "$(trap -p TERM)" "trap -- '' SIGTERM"
  assert_equal "$(trap -p INT)" "trap -- '' SIGINT"
}

@test "signals_install registers handlers for TERM and INT" {
  signals_install

  assert_equal "$(trap -p TERM)" "trap -- 'signals_shutdown 15' SIGTERM"
  assert_equal "$(trap -p INT)" "trap -- 'signals_shutdown 2' SIGINT"
}
