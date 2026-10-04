#!/usr/bin/env bats
# Tests for `vault up`, against the source tree (cli/bin/vault) and the
# bundle (build/vault), with the stub docker.
# shellcheck disable=SC2154 # output/stderr/status are set by bats' run

bats_require_minimum_version 1.5.0

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  load helpers/docker_stub
  load helpers/vault_cli

  vault_cli_setup
  : >"$PROJ/compose.yaml"

  PORT_HINT='vault: hint: choose another host port with -p HOST:80'
  SYSBOX_ERROR='vault: error: sysbox-runc failed to start the container
vault: hint: fix sysbox or use --runtime=privileged'
  FALLBACK='vault: warning: sysbox-runc not found; running with --privileged (see Security in the README)'
}

@test "up runs detached with the full argument list and prints started" {
  local vault
  docker_stub_set run "0123456789abcdef"
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" up --runtime privileged

    assert_success
    assert_output "vault-proj started"
    assert_equal "$stderr" ""
    assert_docker_called inspect --format '{{.State.Running}}' vault-proj
    assert_docker_called run --privileged --stop-timeout 60 \
      -v "$PROJ:/vault" -v vault-proj-data:/var/lib/docker \
      -p 3000:80 --name vault-proj -d "$IMAGE"
    assert_docker_not_called rm
    assert_equal "$(docker_stub_count run)" 1
  done
}

@test "up -f runs in the foreground, shows its output and no started line" {
  local vault
  docker_stub_set run "stack output"
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" up -f --runtime privileged

    assert_success
    assert_output "stack output"
    assert_docker_called run --privileged --stop-timeout 60 \
      -v "$PROJ:/vault" -v vault-proj-data:/var/lib/docker \
      -p 3000:80 --name vault-proj "$IMAGE"
  done
}

@test "up -f passes a non-start exit code through unchanged" {
  local vault
  docker_stub_set run "" 3 "inner failure"
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" up -f --runtime privileged

    assert_failure 3
    assert_equal "$stderr" "inner failure"
  done
}

@test "up when already running: message and status, no run (edge case 4)" {
  local vault
  docker_stub_set_nth inspect 1 true
  docker_stub_set_nth inspect 2 "$IMAGE
sha256:abc
sysbox-runc false
3000->80/tcp 
PATH RAILS_ENV SECRET_KEY_BASE "
  docker_stub_set image "PATH "
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" up --runtime privileged

    assert_success
    assert_output "vault-proj is already running
name:     vault-proj
state:    running
image:    $IMAGE
runtime:  sysbox-runc
ports:    3000->80/tcp
volume:   vault-proj-data
env:      RAILS_ENV, SECRET_KEY_BASE"
    assert_equal "$stderr" ""
    assert_docker_called inspect --format "$STATUS_FORMAT" vault-proj
    assert_docker_not_called run
    assert_docker_not_called rm
  done
}

@test "up when stopped: docker rm, then a fresh run, volume kept (edge case 5)" {
  local vault
  docker_stub_set inspect false
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" up --runtime privileged

    assert_success
    assert_output "vault-proj started"
    assert_equal "$(docker_stub_calls | cut -f1 | tr '\n' ' ')" "info inspect rm run "
    assert_docker_called rm vault-proj
    assert_docker_not_called volume
    assert_equal "$(docker_stub_count run)" 1
  done
}

@test "up with a failing Sysbox run: Sysbox error, never retried (edge case 2)" {
  local vault
  docker_stub_info "$DOCKER_STUB_INFO_SYSBOX" "$DOCKER_STUB_SECURITY_DEFAULT"
  docker_stub_set run "" 125 "docker: Error response from daemon: OCI runtime create failed."
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" up

    assert_failure 1
    assert_output ""
    assert_equal "$stderr" "docker: Error response from daemon: OCI runtime create failed.
$SYSBOX_ERROR"
    assert_equal "$(docker_stub_count run)" 1
    run grep -c -- --privileged "$DOCKER_STUB_LOG"
    assert_output 0
  done
}

@test "up -f with a failing Sysbox start (125): Sysbox error" {
  local vault
  docker_stub_info "$DOCKER_STUB_INFO_SYSBOX" "$DOCKER_STUB_SECURITY_DEFAULT"
  docker_stub_set run "" 125 "docker: boom."
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" up -f

    assert_failure 1
    assert_equal "$stderr" "docker: boom.
$SYSBOX_ERROR"
  done
}

@test "up with the host port in use: port hint (edge case 6)" {
  local vault err
  docker_stub_info "$DOCKER_STUB_INFO_SYSBOX" "$DOCKER_STUB_SECURITY_DEFAULT"
  for err in \
    "docker: Error response from daemon: Bind for 0.0.0.0:3000 failed: port is already allocated." \
    "docker: Error response from daemon: listen tcp 0.0.0.0:3000: bind: address already in use."; do
    docker_stub_set run "" 125 "$err"
    for vault in "${VAULTS[@]}"; do
      vault_run "$vault" up

      assert_failure 1
      assert_equal "$stderr" "$err
$PORT_HINT"
    done
  done
}

@test "up with a failing --privileged run: docker's error only" {
  local vault
  docker_stub_set run "" 125 "docker: some error."
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" up

    assert_failure 1
    assert_equal "$stderr" "$FALLBACK
docker: some error."
  done
}

@test "up with a missing dir fails before any docker call" {
  local vault
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" up nope

    assert_failure 1
    assert_output ""
    assert_equal "$stderr" "vault: error: directory not found: nope"
    assert_equal "$(docker_stub_calls)" ""
  done
}

@test "up without a compose file warns and still runs" {
  local vault
  rm "$PROJ/compose.yaml"
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" up --runtime privileged

    assert_success
    assert_output "vault-proj started"
    assert_equal "$stderr" "vault: warning: no compose file found in $PROJ; relying on COMPOSE_FILE"
    assert_equal "$(docker_stub_count run)" 1
  done
}

@test "up accepts every compose file name" {
  local vault file
  rm "$PROJ/compose.yaml"
  for file in compose.yml docker-compose.yaml docker-compose.yml; do
    : >"$PROJ/$file"
    for vault in "${VAULTS[@]}"; do
      vault_run "$vault" up --runtime privileged

      assert_success
      assert_equal "$stderr" ""
    done
    rm "$PROJ/$file"
  done
}

@test "up --image without [dir]: no /vault mount and no compose warning" {
  local vault
  rm "$PROJ/compose.yaml"
  docker_stub_set inspect "" 1 "Error response from daemon: No such object: vault-my-app"
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" up --runtime privileged --image team/my-app:1.0

    assert_success
    assert_output "vault-my-app started"
    assert_equal "$stderr" ""
    assert_docker_called run --privileged --stop-timeout 60 \
      -v vault-my-app-data:/var/lib/docker \
      -p 3000:80 --name vault-my-app -d team/my-app:1.0
  done
}

@test "up with an unreachable daemon on inspect fails with exit 1" {
  local vault
  docker_stub_set inspect "" 1 "Cannot connect to the Docker daemon."
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" up --runtime privileged

    assert_failure 1
    assert_equal "$stderr" "Cannot connect to the Docker daemon.
vault: error: cannot reach the Docker daemon
vault: hint: is Docker running, and can this user access it?"
    assert_docker_not_called run
  done
}

@test "up -h prints the usage and calls no docker" {
  local vault
  for vault in "${VAULTS[@]}"; do
    vault_run "$vault" up -h

    assert_success
    assert_line --index 0 "Usage: vault <command> [options] [dir] [args]"
    assert_equal "$(docker_stub_calls)" ""
  done
}
