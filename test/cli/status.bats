#!/usr/bin/env bats
# Tests for `vault status` (source tree and bundle, stub docker).
# shellcheck disable=SC2154 # output/stderr/status are set by bats' run

bats_require_minimum_version 1.5.0

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  load helpers/docker_stub
  load helpers/vault_cli

  vault_cli_setup
  # shellcheck disable=SC2016 # a Go template, not shell
  IMAGE_ENV_FORMAT='{{range .Config.Env}}{{index (split . "=") 0}} {{end}}'
  docker_stub_set image "PATH VAULT_DOCKERD_TIMEOUT "
}

@test "status of a running Sysbox instance prints every field" {
  local vault
  vault_stub_instance true "$IMAGE
sha256:abc
sysbox-runc false
3000->80/tcp 
PATH RAILS_ENV VAULT_DOCKERD_TIMEOUT SECRET_KEY_BASE "
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" status

    assert_success
    assert_output "name:     vault-proj
state:    running
image:    $IMAGE
runtime:  sysbox-runc
ports:    3000->80/tcp
volume:   vault-proj-data
env:      RAILS_ENV, SECRET_KEY_BASE"
    assert_equal "$stderr" ""
    assert_docker_called inspect --format '{{.State.Running}}' vault-proj
    assert_docker_called inspect --format "$STATUS_FORMAT" vault-proj
    assert_docker_called image inspect --format "$IMAGE_ENV_FORMAT" sha256:abc
    assert_docker_not_called info
  done
}

@test "status of a stopped privileged instance with several ports" {
  local vault
  vault_stub_instance false "$IMAGE
sha256:abc
runc true
3000->80/tcp 8443->443/tcp 
PATH "
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" status

    assert_success
    assert_output "name:     vault-proj
state:    stopped
image:    $IMAGE
runtime:  privileged
ports:    3000->80/tcp, 8443->443/tcp
volume:   vault-proj-data
env:"
  done
}

@test "status never prints an env value" {
  local vault
  # The CLI only ever asks docker for keys; a value must not leak even if
  # the key list contained one.
  vault_stub_instance true "$IMAGE
sha256:abc
sysbox-runc false
3000->80/tcp 
SECRET "
  printf 'SECRET=abc\n' >"$PROJ/.vault.env"
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" status

    assert_success
    assert_line "env:      SECRET"
    refute_output --partial abc
    refute_output --partial '='
  done
}

@test "status keeps every key when the image cannot be inspected" {
  local vault
  docker_stub_set image "" 1 "Error: No such image: sha256:abc"
  vault_stub_instance true "$IMAGE
sha256:abc
sysbox-runc false
3000->80/tcp 
PATH A "
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" status

    assert_success
    assert_line "env:      PATH, A"
    assert_equal "$stderr" ""
  done
}

@test "status of a missing instance: name and not found, exit 0" {
  local vault
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" status

    assert_success
    assert_output "name:     vault-proj
state:    not found"
    assert_equal "$stderr" ""
    assert_equal "$(docker_stub_count inspect)" 1
    assert_docker_not_called image
  done
}

@test "status with an unreachable daemon fails with exit 1" {
  local vault
  docker_stub_set inspect "" 1 "$DAEMON_DOWN"
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" status

    assert_failure 1
    assert_output ""
    assert_equal "$stderr" "$DAEMON_ERROR"
  done
}

@test "status --image without [dir] names the instance after the image" {
  local vault
  docker_stub_set inspect "" 1 "Error response from daemon: No such object: vault-my-app"
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" status --image team/my-app:1.0

    assert_success
    assert_output "name:     vault-my-app
state:    not found"
  done
}
