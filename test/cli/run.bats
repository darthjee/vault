#!/usr/bin/env bats
# Tests for `vault run` (source tree and bundle, stub docker).
# shellcheck disable=SC2154 # output/stderr/status are set by bats' run

bats_require_minimum_version 1.5.0

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  load helpers/docker_stub
  load helpers/vault_cli

  vault_cli_setup
  : >"$PROJ/compose.yaml"
  SYSBOX_ERROR='vault: error: sysbox-runc failed to start the container
vault: hint: fix sysbox or use --runtime=privileged'
  RUNNING='vault: error: instance vault-proj is running
vault: hint: stop it with "vault down", or use "vault compose"'
}

@test "run without a TTY: full argument list, foreground, output shown" {
  local vault
  docker_stub_set run "rendered config"
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" run --runtime privileged config --services

    assert_success
    assert_output "rendered config"
    assert_equal "$stderr" ""
    assert_docker_called inspect --format '{{.State.Running}}' vault-proj
    assert_docker_called run --privileged --stop-timeout 60 \
      -v "$PROJ:/vault" -v vault-proj-data:/var/lib/docker \
      -p 3000:80 --rm "$IMAGE" config --services
  done
}

@test "run with a TTY puts -i -t right before --rm" {
  local vault
  for vault in "${VAULTS[@]}"; do
    : >"$DOCKER_STUB_LOG"
    # shellcheck disable=SC2016 # expanded by the inner bash
    run --separate-stderr bash -c '
      source "$1"
      instance_tty_flags() { INSTANCE_TTY_ARGS=(-i -t); }
      vault_main run --runtime privileged -e A=1 config
    ' tty "$vault"

    assert_success
    assert_docker_called run --privileged --stop-timeout 60 \
      -v "$PROJ:/vault" -v vault-proj-data:/var/lib/docker \
      -p 3000:80 -e A=1 -i -t --rm "$IMAGE" config
  done
}

@test "run with only stdout a TTY adds -t only" {
  local vault
  for vault in "${VAULTS[@]}"; do
    : >"$DOCKER_STUB_LOG"
    # shellcheck disable=SC2016 # expanded by the inner bash
    run --separate-stderr bash -c '
      source "$1"
      instance_tty_flags() { INSTANCE_TTY_ARGS=(-t); }
      vault_main run --runtime privileged config
    ' tty "$vault"

    assert_success
    assert_docker_called run --privileged --stop-timeout 60 \
      -v "$PROJ:/vault" -v vault-proj-data:/var/lib/docker \
      -p 3000:80 -t --rm "$IMAGE" config
  done
}

@test "run is refused while the instance is running" {
  local vault
  docker_stub_set inspect true
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" run --runtime privileged config

    assert_failure 1
    assert_output ""
    assert_equal "$stderr" "$RUNNING"
    assert_docker_not_called run
  done
}

@test "run is allowed when the instance is stopped" {
  local vault
  docker_stub_set inspect false
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" run --runtime privileged config

    assert_success
    assert_equal "$(docker_stub_count run)" 1
    assert_docker_not_called rm
  done
}

@test "run config passes config when no such dir exists" {
  local vault
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" run --runtime privileged config

    assert_success
    assert_docker_called run --privileged --stop-timeout 60 \
      -v "$PROJ:/vault" -v vault-proj-data:/var/lib/docker \
      -p 3000:80 --rm "$IMAGE" config
  done
}

@test "run <existing dir> config mounts that dir and names the instance after it" {
  local vault
  mkdir -p "$WORK/config"
  : >"$WORK/config/compose.yaml"
  docker_stub_set inspect "" 1 "Error response from daemon: No such object: vault-config"
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" run --runtime privileged ../config config

    assert_success
    assert_equal "$stderr" ""
    assert_docker_called run --privileged --stop-timeout 60 \
      -v "$WORK/config:/vault" -v vault-config-data:/var/lib/docker \
      -p 3000:80 --rm "$IMAGE" config
  done
}

@test "run -- <existing dir> passes it to the entrypoint" {
  local vault
  mkdir -p "$PROJ/config"
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" run --runtime privileged -- config

    assert_success
    assert_docker_called run --privileged --stop-timeout 60 \
      -v "$PROJ:/vault" -v vault-proj-data:/var/lib/docker \
      -p 3000:80 --rm "$IMAGE" config
  done
}

@test "run without a compose file warns and still runs" {
  local vault
  rm "$PROJ/compose.yaml"
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" run --runtime privileged config

    assert_success
    assert_equal "$stderr" "vault: warning: no compose file found in $PROJ; relying on COMPOSE_FILE"
    assert_equal "$(docker_stub_count run)" 1
  done
}

@test "run passes the inner exit code through unchanged" {
  local vault
  docker_stub_set run "" 2 "config invalid"
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" run --runtime privileged config

    assert_failure 2
    assert_equal "$stderr" "config invalid"
  done
}

@test "run with a failing Sysbox start (125): Sysbox error, never retried" {
  local vault
  docker_stub_info "$DOCKER_STUB_INFO_SYSBOX" "$DOCKER_STUB_SECURITY_DEFAULT"
  docker_stub_set run "" 125 "docker: Error response from daemon: OCI runtime create failed."
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" run config

    assert_failure 1
    assert_equal "$stderr" "docker: Error response from daemon: OCI runtime create failed.
$SYSBOX_ERROR"
    assert_equal "$(docker_stub_count run)" 1
  done
}

@test "run with the host port in use: port hint" {
  local vault
  docker_stub_info "$DOCKER_STUB_INFO_SYSBOX" "$DOCKER_STUB_SECURITY_DEFAULT"
  docker_stub_set run "" 125 "docker: Error response from daemon: Bind for 0.0.0.0:3000 failed: port is already allocated."
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" run config

    assert_failure 1
    assert_equal "$stderr" "docker: Error response from daemon: Bind for 0.0.0.0:3000 failed: port is already allocated.
vault: hint: choose another host port with -p HOST:80"
  done
}

@test "run with a 126 under --privileged: docker's error only, exit 1" {
  local vault
  docker_stub_set run "" 126 "docker: permission denied."
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" run --runtime privileged config

    assert_failure 1
    assert_equal "$stderr" "docker: permission denied."
  done
}

@test "run with an unreachable daemon on inspect fails with exit 1" {
  local vault
  docker_stub_set inspect "" 1 "$DAEMON_DOWN"
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" run --runtime privileged config

    assert_failure 1
    assert_equal "$stderr" "$DAEMON_ERROR"
    assert_docker_not_called run
  done
}
