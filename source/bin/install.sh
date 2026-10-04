#!/usr/bin/env bash
# Vault install entry (vault-install): copies the bundled CLI and its shell
# completions into the bind-mounted /install dir. Runs as the host user
# (--user), takes no arguments (any are ignored), never starts dockerd.
# Exits 0 silently on success, 1 with an error on stderr on failure.
set -euo pipefail

VAULT_LIB_DIR="/usr/local/lib/vault"
VAULT_INSTALL_BIN="/usr/local/bin/vault"
VAULT_INSTALL_COMPLETION_DIR="/usr/local/share/vault/completion"
VAULT_INSTALL_TARGET="/install"

# shellcheck source=/dev/null
source "$VAULT_LIB_DIR/install.sh"

if ! install_copy "$VAULT_INSTALL_BIN" "$VAULT_INSTALL_COMPLETION_DIR" "$VAULT_INSTALL_TARGET"; then
  exit 1
fi
