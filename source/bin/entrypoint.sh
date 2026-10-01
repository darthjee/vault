#!/usr/bin/env bash
# Vault entrypoint: starts the inner dockerd, waits for it, preloads image
# tarballs, then runs docker compose from /vault and exits with its exit
# code. SIGTERM / SIGINT run the shutdown sequence (compose down, stop
# dockerd). This is the only place that reads the environment.
set -euo pipefail

VAULT_LIB_DIR="/usr/local/lib/vault"
VAULT_IMAGES_DIR="/vault/images"
VAULT_WORKDIR="/vault"

# shellcheck source=/dev/null
source "$VAULT_LIB_DIR/preflight.sh"
# shellcheck source=/dev/null
source "$VAULT_LIB_DIR/dockerd.sh"
# shellcheck source=/dev/null
source "$VAULT_LIB_DIR/images.sh"
# shellcheck source=/dev/null
source "$VAULT_LIB_DIR/compose.sh"
# shellcheck source=/dev/null
source "$VAULT_LIB_DIR/signals.sh"

# Installed first so a signal at any point runs the shutdown sequence.
signals_install

timeout="${VAULT_DOCKERD_TIMEOUT:-30}"
# Whitespace split, no quoting support; read by compose_run.
read -ra COMPOSE_UP_ARGS <<< "${COMPOSE_UP_ARGS:-}"

if ! preflight_check_timeout "$timeout"; then
  exit 1
fi

if ! preflight_check_privileges; then
  exit 1
fi

dockerd_start

if ! dockerd_wait "$timeout"; then
  dockerd_stop "$DOCKERD_PID"
  exit 1
fi

if ! images_load_dir "$VAULT_IMAGES_DIR"; then
  dockerd_stop "$DOCKERD_PID"
  exit 1
fi

cd "$VAULT_WORKDIR"
compose_run "$@"

# Called directly (not in a subshell): wait only works on our own children.
status=0
compose_wait "$COMPOSE_PID" || status=$?

# Compose is done: a late signal must not trigger a teardown.
signals_ignore
dockerd_stop "$DOCKERD_PID"

exit "$status"
