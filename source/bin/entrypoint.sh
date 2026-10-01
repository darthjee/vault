#!/usr/bin/env bash
# Vault entrypoint: starts the inner dockerd, waits for it and preloads
# image tarballs. This is the only place that reads the environment.
set -euo pipefail

VAULT_LIB_DIR="/usr/local/lib/vault"
VAULT_IMAGES_DIR="/vault/images"

# shellcheck source=/dev/null
source "$VAULT_LIB_DIR/preflight.sh"
# shellcheck source=/dev/null
source "$VAULT_LIB_DIR/dockerd.sh"
# shellcheck source=/dev/null
source "$VAULT_LIB_DIR/images.sh"

timeout="${VAULT_DOCKERD_TIMEOUT:-30}"

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

# Placeholder until #6 runs docker compose here.
echo "vault: dockerd is ready; the compose step is not implemented yet (see issue #6)"
wait "$DOCKERD_PID"
