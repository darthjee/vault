#!/usr/bin/env bats
# Tests for `vault compose` (source tree and bundle, stub docker).
# shellcheck disable=SC2154 # output/stderr/status are set by bats' run

bats_require_minimum_version 1.5.0

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  load helpers/docker_stub
  load helpers/vault_cli

  vault_cli_setup
}

@test "compose without a TTY: docker exec vault-<name> docker compose <args>" {
  local vault
  docker_stub_set inspect true
  docker_stub_set exec "NAME STATUS"
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" compose ps -a

    assert_success
    assert_output "NAME STATUS"
    assert_equal "$stderr" ""
    assert_docker_called exec vault-proj docker compose ps -a
    assert_docker_not_called info
  done
}

@test "compose passes options after the first argument verbatim" {
  local vault
  docker_stub_set inspect true
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" compose --name other logs -f --name x

    assert_success
    assert_docker_called exec vault-other docker compose logs -f --name x
  done
}

@test "compose with a TTY adds -i -t before the container" {
  local vault
  docker_stub_set inspect true
  for vault in "${VAULTS[@]}"; do
    : >"$DOCKER_STUB_LOG"
    # shellcheck disable=SC2016 # expanded by the inner bash
    run --separate-stderr bash -c '
      source "$1"
      instance_tty_flags() { INSTANCE_TTY_ARGS=(-i -t); }
      vault_main compose exec web sh
    ' tty "$vault"

    assert_success
    assert_docker_called exec -i -t vault-proj docker compose exec web sh
  done
}

@test "compose passes the inner exit code through" {
  local vault
  docker_stub_set inspect true
  docker_stub_set exec "" 3 "service failed"
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" compose up

    assert_failure 3
    assert_equal "$stderr" "service failed"
  done
}

@test "compose on a stopped instance: not running, exit 1, no exec" {
  local vault
  docker_stub_set inspect false
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" compose ps

    assert_failure 1
    assert_output ""
    assert_equal "$stderr" "$NOT_RUNNING"
    assert_docker_not_called exec
  done
}

@test "compose on a missing instance: not running, exit 1, no exec" {
  local vault
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" compose ps

    assert_failure 1
    assert_equal "$stderr" "$NOT_RUNNING"
    assert_docker_not_called exec
  done
}

@test "compose with an unreachable daemon fails with exit 1" {
  local vault
  docker_stub_set inspect "" 1 "$DAEMON_DOWN"
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" compose ps

    assert_failure 1
    assert_equal "$stderr" "$DAEMON_ERROR"
    assert_docker_not_called exec
  done
}
