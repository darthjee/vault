#!/usr/bin/env bash
# Usage: IMAGE=darthjee/vault:dev [SMOKE_TIMEOUT=120] scripts/test_cli_e2e.sh
# End-to-end test of the bundled CLI (build/vault) against a built image.
# Drives a real instance, named e2e-<pid>, with the test/fixture compose stack:
#   - `vault up --runtime=privileged -p 127.0.0.1:<free port>:80` prints
#     "vault-e2e-<pid> started", and HTTP / answers within SMOKE_TIMEOUT;
#   - `vault status` names the container and the privileged runtime;
#   - `vault compose ps` lists the fixture's web service;
#   - `vault down` removes the container and keeps the data volume.
# Then installs the CLI with install.sh from that local image into a temp
# HOME and install dir: the installed vault prints "vault $(cat VERSION)",
# is owned by the current user, and both completions are in place.
# The container, the data volume and the temp dir are always removed.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

IMAGE="${IMAGE:-}"
SMOKE_TIMEOUT="${SMOKE_TIMEOUT:-120}"
FIXTURE_DIR="$PWD/test/fixture"
VAULT="$PWD/build/vault"
NAME="e2e-$$"
CONTAINER="vault-$NAME"
VOLUME="vault-$NAME-data"
WORK=""
PORT=""

main() {
  validate_inputs
  trap _cleanup EXIT
  WORK="$(mktemp -d)"
  PORT="$(free_port)"
  cli_up
  wait_for_http
  cli_status
  cli_compose_ps
  cli_down
  install_cli
  echo "test-cli-e2e: OK"
}

validate_inputs() {
  if [ -z "$IMAGE" ]; then
    echo "test-cli-e2e: IMAGE is required" >&2
    exit 1
  fi
  if ! [[ "$SMOKE_TIMEOUT" =~ ^[1-9][0-9]*$ ]]; then
    echo "test-cli-e2e: SMOKE_TIMEOUT must be a positive integer (got '$SMOKE_TIMEOUT')" >&2
    exit 1
  fi
  if [ ! -f "$FIXTURE_DIR/docker-compose.yml" ]; then
    echo "test-cli-e2e: fixture not found: test/fixture/docker-compose.yml" >&2
    exit 1
  fi
  if [ ! -x "$VAULT" ]; then
    echo "test-cli-e2e: build/vault not found or not executable (run make bundle-cli)" >&2
    exit 1
  fi
}

# Prints a free TCP port on 127.0.0.1 (racy between pick and bind; fine for CI).
free_port() {
  local port
  port="$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1])')" \
    || fail "could not pick a free port"
  [[ "$port" =~ ^[0-9]+$ ]] || fail "could not pick a free port (got '$port')"
  echo "$port"
}

cli_up() {
  local output

  echo "test-cli-e2e: vault up $NAME ($IMAGE) on 127.0.0.1:$PORT"
  output="$("$VAULT" up --name "$NAME" --image "$IMAGE" --runtime=privileged \
    -p "127.0.0.1:$PORT:80" "$FIXTURE_DIR" </dev/null 2>&1)" \
    || fail "vault up exited non-zero: $output"
  if ! grep -Fq "$CONTAINER started" <<<"$output"; then
    fail "vault up did not print '$CONTAINER started': $output"
  fi
  echo "test-cli-e2e: up"
}

wait_for_http() {
  local deadline=$((SECONDS + SMOKE_TIMEOUT))

  echo "test-cli-e2e: waiting for http://127.0.0.1:$PORT/ (timeout ${SMOKE_TIMEOUT}s)"
  until curl -fsS -o /dev/null "http://127.0.0.1:$PORT/" 2>/dev/null; do
    if [ "$(_running)" != "true" ]; then
      fail "container exited before port $PORT answered"
    fi
    if [ "$SECONDS" -ge "$deadline" ]; then
      fail "port $PORT did not answer within ${SMOKE_TIMEOUT}s"
    fi
    sleep 2
  done
  echo "test-cli-e2e: http answered"
}

cli_status() {
  local output

  output="$("$VAULT" status --name "$NAME" </dev/null 2>&1)" \
    || fail "vault status exited non-zero: $output"
  if ! grep -Fq "$CONTAINER" <<<"$output"; then
    fail "vault status did not name $CONTAINER: $output"
  fi
  if ! grep -Eq '^runtime:.*privileged' <<<"$output"; then
    fail "vault status did not report the privileged runtime: $output"
  fi
  echo "test-cli-e2e: status"
}

cli_compose_ps() {
  local output

  output="$("$VAULT" compose --name "$NAME" ps </dev/null 2>&1)" \
    || fail "vault compose ps exited non-zero: $output"
  if ! grep -Eq '(^|[[:space:]])web([[:space:]]|$)' <<<"$output"; then
    fail "vault compose ps did not list the web service: $output"
  fi
  echo "test-cli-e2e: compose ps"
}

cli_down() {
  local output expected

  expected="$CONTAINER stopped and removed (volume $VOLUME kept)"
  output="$("$VAULT" down --name "$NAME" </dev/null 2>&1)" \
    || fail "vault down exited non-zero: $output"
  if ! grep -Fq "$expected" <<<"$output"; then
    fail "vault down did not print '$expected': $output"
  fi
  if docker container inspect "$CONTAINER" >/dev/null 2>&1; then
    fail "container $CONTAINER still exists after vault down"
  fi
  if ! docker volume inspect "$VOLUME" >/dev/null 2>&1; then
    fail "volume $VOLUME was not kept by vault down"
  fi
  echo "test-cli-e2e: down"
}

install_cli() {
  local version output expected owner file

  version="$(tr -d '[:space:]' < VERSION)"
  output="$(HOME="$WORK/home" VAULT_INSTALL_DIR="$WORK/bin" VAULT_IMAGE="$IMAGE" \
    bash install.sh </dev/null)" || fail "install.sh exited non-zero: $output"
  expected="installed vault $version to $WORK/bin/vault"
  if ! grep -Fq "$expected" <<<"$output"; then
    fail "install.sh did not print '$expected': $output"
  fi

  output="$("$WORK/bin/vault" version </dev/null 2>&1)" \
    || fail "installed vault version exited non-zero: $output"
  if [ "$output" != "vault $version" ]; then
    fail "installed vault version printed '$output' (expected 'vault $version')"
  fi

  owner="$(stat -c %u "$WORK/bin/vault" 2>/dev/null || stat -f %u "$WORK/bin/vault")" \
    || fail "could not stat the installed vault"
  if [ "$owner" != "$(id -u)" ]; then
    fail "installed vault is owned by uid $owner (expected $(id -u))"
  fi

  for file in vault.bash _vault; do
    [ -f "$WORK/home/.local/share/vault/completion/$file" ] \
      || fail "install.sh did not install completion/$file"
  done
  echo "test-cli-e2e: install"
}

fail() {
  echo "test-cli-e2e: FAILED: $1" >&2
  if docker container inspect "$CONTAINER" >/dev/null 2>&1; then
    echo "----- docker logs $CONTAINER -----" >&2
    docker logs "$CONTAINER" >&2 2>&1 || true
    echo "-----------------------------" >&2
  fi
  exit 1
}

_running() {
  docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null || echo "false"
}

_cleanup() {
  docker rm -fv "$CONTAINER" >/dev/null 2>&1 || true
  docker volume rm "$VOLUME" >/dev/null 2>&1 || true
  if [ -n "$WORK" ]; then
    rm -rf "$WORK"
  fi
}

main "$@"
