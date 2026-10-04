#!/usr/bin/env bats
# Tests for `vault down` (source tree and bundle, stub docker).
# shellcheck disable=SC2154 # output/stderr/status are set by bats' run

bats_require_minimum_version 1.5.0

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  load helpers/docker_stub
  load helpers/vault_cli

  vault_cli_setup
  REMOVED='vault-proj stopped and removed (volume vault-proj-data kept)'
}

@test "down on a running instance: stop -t 60, rm, removed message" {
  local vault
  docker_stub_set inspect true
  docker_stub_set stop vault-proj
  docker_stub_set rm vault-proj
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" down

    assert_success
    assert_output "$REMOVED"
    assert_equal "$stderr" ""
    assert_equal "$(docker_stub_calls | cut -f1 | tr '\n' ' ')" "inspect stop rm "
    assert_docker_called stop -t 60 vault-proj
    assert_docker_called rm vault-proj
    assert_docker_not_called volume
    assert_docker_not_called info
  done
}

@test "down uses --stop-timeout for stop -t" {
  local vault
  docker_stub_set inspect true
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" down --stop-timeout 5

    assert_success
    assert_docker_called stop -t 5 vault-proj
  done
}

@test "down uses stop-timeout from .vaultrc" {
  local vault
  docker_stub_set inspect true
  printf 'stop-timeout=7\n' >"$PROJ/.vaultrc"
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" down

    assert_success
    assert_docker_called stop -t 7 vault-proj
  done
}

@test "down on a stopped instance: rm only" {
  local vault
  docker_stub_set inspect false
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" down

    assert_success
    assert_output "$REMOVED"
    assert_docker_not_called stop
    assert_docker_called rm vault-proj
  done
}

@test "down on a missing instance: does not exist, exit 0" {
  local vault
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" down

    assert_success
    assert_output "vault-proj does not exist"
    assert_equal "$stderr" ""
    assert_docker_not_called stop
    assert_docker_not_called rm
  done
}

@test "down with an unreachable daemon fails with exit 1" {
  local vault
  docker_stub_set inspect "" 1 "$DAEMON_DOWN"
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" down

    assert_failure 1
    assert_output ""
    assert_equal "$stderr" "$DAEMON_ERROR"
    assert_docker_not_called stop
  done
}

@test "down passes a failing stop through, exit 1" {
  local vault
  docker_stub_set inspect true
  docker_stub_set stop "" 1 "Error response from daemon: cannot stop"
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" down

    assert_failure 1
    assert_output ""
    assert_equal "$stderr" "Error response from daemon: cannot stop"
    assert_docker_not_called rm
  done
}

@test "down passes a failing rm through, exit 1" {
  local vault
  docker_stub_set inspect false
  docker_stub_set rm "" 1 "Error response from daemon: cannot remove"
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" down

    assert_failure 1
    assert_output ""
    assert_equal "$stderr" "Error response from daemon: cannot remove"
  done
}

@test "down --name targets vault-<name>" {
  local vault
  docker_stub_set inspect true
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" down --name other

    assert_success
    assert_output "vault-other stopped and removed (volume vault-other-data kept)"
    assert_docker_called stop -t 60 vault-other
  done
}
