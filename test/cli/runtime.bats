#!/usr/bin/env bats
# Tests for cli/lib/runtime.sh (pre-checks and runtime selection).
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
  # shellcheck source=SCRIPTDIR/../../cli/lib/runtime.sh
  source "$ROOT/cli/lib/runtime.sh"
  docker_stub_setup

  INFO_FORMAT='{{json .Runtimes}}{{"\n"}}{{json .SecurityOptions}}'
  FALLBACK='vault: warning: sysbox-runc not found; running with --privileged (see Security in the README)'
}

@test "runtime_check_docker passes when docker is on PATH" {
  run --separate-stderr runtime_check_docker

  assert_success
  assert_equal "$stderr" ""
}

@test "runtime_check_docker fails when docker is missing (edge case 1)" {
  docker_stub_hide

  run --separate-stderr runtime_check_docker

  assert_failure 1
  assert_output ""
  assert_equal "$stderr" "vault: error: docker not found in PATH"
}

@test "runtime_probe calls docker info once with the runtimes and security options" {
  runtime_probe

  assert_equal "$(docker_stub_count info)" 1
  assert_docker_called info --format "$INFO_FORMAT"
  assert_equal "$RUNTIME_SYSBOX" 0
  assert_equal "$RUNTIME_ROOTLESS" 0
}

@test "runtime_probe detects sysbox-runc" {
  docker_stub_info "$DOCKER_STUB_INFO_SYSBOX" "$DOCKER_STUB_SECURITY_DEFAULT"

  runtime_probe

  assert_equal "$RUNTIME_SYSBOX" 1
  assert_equal "$RUNTIME_ROOTLESS" 0
}

@test "runtime_probe detects rootless" {
  docker_stub_info "$DOCKER_STUB_INFO_RUNC" "$DOCKER_STUB_SECURITY_ROOTLESS"

  runtime_probe

  assert_equal "$RUNTIME_ROOTLESS" 1
}

@test "runtime_probe: a failing docker info is an unreachable daemon (edge case 1)" {
  docker_stub_info_fails

  run --separate-stderr runtime_probe

  assert_failure 1
  assert_output ""
  assert_equal "$stderr" "Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
vault: error: cannot reach the Docker daemon
vault: hint: is Docker running, and can this user access it?"
}

@test "rootless is refused for every runtime value" {
  local runtime
  docker_stub_info "$DOCKER_STUB_INFO_SYSBOX" "$DOCKER_STUB_SECURITY_ROOTLESS"
  for runtime in auto sysbox privileged; do
    run --separate-stderr runtime_resolve "$runtime"

    assert_failure 1
    assert_output ""
    assert_equal "$stderr" 'vault: error: rootless Docker is not supported
vault: hint: see "Supported runtimes" in the README'
  done
}

@test "auto with Sysbox: --runtime=sysbox-runc, no message" {
  docker_stub_info "$DOCKER_STUB_INFO_SYSBOX" "$DOCKER_STUB_SECURITY_DEFAULT"

  runtime_resolve auto 2>"$BATS_TEST_TMPDIR/err"

  assert_equal "$RUNTIME_ARG" --runtime=sysbox-runc
  assert_equal "$(cat "$BATS_TEST_TMPDIR/err")" ""
}

@test "auto without Sysbox: --privileged with the fallback warning" {
  runtime_resolve auto 2>"$BATS_TEST_TMPDIR/err"

  assert_equal "$RUNTIME_ARG" --privileged
  assert_equal "$(cat "$BATS_TEST_TMPDIR/err")" "$FALLBACK"
}

@test "sysbox with Sysbox: --runtime=sysbox-runc, no message" {
  docker_stub_info "$DOCKER_STUB_INFO_SYSBOX" "$DOCKER_STUB_SECURITY_DEFAULT"

  runtime_resolve sysbox 2>"$BATS_TEST_TMPDIR/err"

  assert_equal "$RUNTIME_ARG" --runtime=sysbox-runc
  assert_equal "$(cat "$BATS_TEST_TMPDIR/err")" ""
}

@test "sysbox without Sysbox fails, no fallback (edge case 3)" {
  run --separate-stderr runtime_resolve sysbox

  assert_failure 1
  assert_output ""
  assert_equal "$stderr" "vault: error: --runtime=sysbox requested but sysbox-runc is not available"
}

@test "privileged: --privileged, never a warning" {
  local runtimes
  for runtimes in "$DOCKER_STUB_INFO_RUNC" "$DOCKER_STUB_INFO_SYSBOX"; do
    docker_stub_info "$runtimes" "$DOCKER_STUB_SECURITY_DEFAULT"

    runtime_resolve privileged 2>"$BATS_TEST_TMPDIR/err"

    assert_equal "$RUNTIME_ARG" --privileged
    assert_equal "$(cat "$BATS_TEST_TMPDIR/err")" ""
  done
}

@test "runtime_resolve calls docker info exactly once" {
  runtime_resolve privileged

  assert_equal "$(docker_stub_count info)" 1
}

@test "an unreachable daemon stops before the runtime table" {
  docker_stub_info_fails

  run --separate-stderr runtime_resolve sysbox

  assert_failure 1
  assert_equal "$(printf '%s\n' "$stderr" | grep -c 'sysbox-runc is not available')" 0
}
