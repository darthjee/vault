#!/usr/bin/env bash
# Usage: IMAGE=darthjee/vault:dev [SMOKE_TIMEOUT=120] scripts/test_image.sh
# Smoke-tests a built Vault image: runs it (--privileged) with the
# test/fixture compose stack on a random localhost port, waits for HTTP 200
# on /, asserts nothing listens on 2375, stops it and expects exit code 0.
# The container (and its anonymous volume) is always removed.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

IMAGE="${IMAGE:-}"
SMOKE_TIMEOUT="${SMOKE_TIMEOUT:-120}"
NAME="vault-smoke-$$"
FIXTURE_DIR="$PWD/test/fixture"

main() {
  local port

  validate_inputs
  trap _cleanup EXIT
  start_container
  port="$(host_port)"
  wait_for_http "$port"
  assert_no_docker_tcp_listener
  assert_clean_stop
  echo "test-image: OK"
}

validate_inputs() {
  if [ -z "$IMAGE" ]; then
    echo "test-image: IMAGE is required" >&2
    exit 1
  fi
  if ! [[ "$SMOKE_TIMEOUT" =~ ^[1-9][0-9]*$ ]]; then
    echo "test-image: SMOKE_TIMEOUT must be a positive integer (got '$SMOKE_TIMEOUT')" >&2
    exit 1
  fi
  if [ ! -f "$FIXTURE_DIR/docker-compose.yml" ]; then
    echo "test-image: fixture not found: test/fixture/docker-compose.yml" >&2
    exit 1
  fi
}

start_container() {
  echo "test-image: starting $IMAGE as $NAME"
  docker run -d --privileged --name "$NAME" \
    -v "$FIXTURE_DIR:/vault:ro" \
    -p 127.0.0.1::80 \
    "$IMAGE" >/dev/null || fail "docker run"
}

host_port() {
  local port
  port="$(docker port "$NAME" 80/tcp | sed -n 's/^127\.0\.0\.1:\([0-9][0-9]*\)$/\1/p' | head -n 1)"
  [ -n "$port" ] || fail "could not determine host port for 80/tcp"
  echo "$port"
}

wait_for_http() {
  local port="$1"
  local deadline=$((SECONDS + SMOKE_TIMEOUT))

  echo "test-image: waiting for http://127.0.0.1:$port/ (timeout ${SMOKE_TIMEOUT}s)"
  until curl -fsS -o /dev/null "http://127.0.0.1:$port/" 2>/dev/null; do
    if [ "$(_running)" != "true" ]; then
      fail "container exited before port 80 answered"
    fi
    if [ "$SECONDS" -ge "$deadline" ]; then
      fail "port 80 did not answer within ${SMOKE_TIMEOUT}s"
    fi
    sleep 2
  done
  echo "test-image: port 80 answered"
}

assert_no_docker_tcp_listener() {
  local listeners
  listeners="$(docker exec "$NAME" netstat -ltn)" || fail "netstat inside the container"
  if grep -Eq ':2375[[:space:]]' <<<"$listeners"; then
    fail "dockerd is listening on TCP 2375"
  fi
  echo "test-image: no listener on 2375"
}

assert_clean_stop() {
  local code
  docker stop -t 30 "$NAME" >/dev/null || fail "docker stop"
  code="$(docker inspect -f '{{.State.ExitCode}}' "$NAME")" || fail "docker inspect exit code"
  if [ "$code" != "0" ]; then
    fail "container exited with code $code after docker stop (expected 0)"
  fi
  echo "test-image: stopped cleanly (exit 0)"
}

fail() {
  echo "test-image: FAILED: $1" >&2
  echo "----- docker logs $NAME -----" >&2
  docker logs "$NAME" >&2 2>&1 || true
  echo "-----------------------------" >&2
  exit 1
}

_running() {
  docker inspect -f '{{.State.Running}}' "$NAME" 2>/dev/null || echo "false"
}

_cleanup() {
  docker rm -fv "$NAME" >/dev/null 2>&1 || true
}

main "$@"
