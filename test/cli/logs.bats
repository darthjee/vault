#!/usr/bin/env bats
# Tests for `vault logs` (source tree and bundle, stub docker).
# shellcheck disable=SC2154 # output/stderr/status are set by bats' run

bats_require_minimum_version 1.5.0

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  load helpers/docker_stub
  load helpers/vault_cli

  vault_cli_setup
}

@test "logs on a running instance runs docker logs" {
  local vault
  docker_stub_set inspect true
  docker_stub_set logs "line 1"
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" logs

    assert_success
    assert_output "line 1"
    assert_equal "$stderr" ""
    assert_docker_called logs vault-proj
    assert_docker_not_called info
  done
}

@test "logs -f and --follow follow the logs" {
  local vault flag
  docker_stub_set inspect true
  for flag in -f --follow; do
    for vault in "${VAULTS[@]}"; do
      vault_run "$vault" logs "$flag"

      assert_success
      assert_docker_called logs -f vault-proj
    done
  done
}

@test "logs passes docker's exit code through" {
  local vault
  docker_stub_set inspect true
  docker_stub_set logs "" 4 "logs failed"
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" logs

    assert_failure 4
    assert_equal "$stderr" "logs failed"
  done
}

@test "logs on a stopped instance: not running, exit 1" {
  local vault
  docker_stub_set inspect false
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" logs

    assert_failure 1
    assert_output ""
    assert_equal "$stderr" "$NOT_RUNNING"
    assert_docker_not_called logs
  done
}

@test "logs on a missing instance: not running, exit 1" {
  local vault
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" logs

    assert_failure 1
    assert_equal "$stderr" "$NOT_RUNNING"
    assert_docker_not_called logs
  done
}

@test "logs with an unreachable daemon fails with exit 1" {
  local vault
  docker_stub_set inspect "" 1 "$DAEMON_DOWN"
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" logs

    assert_failure 1
    assert_equal "$stderr" "$DAEMON_ERROR"
    assert_docker_not_called logs
  done
}
