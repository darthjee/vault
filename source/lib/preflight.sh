#!/usr/bin/env bash
# Library: fast checks run before dockerd is started.
# Sourcing this file only defines functions.
# Requires dockerd.sh (dockerd_privileges_hint) to be sourced too.

# Validates the dockerd timeout: must be a positive integer.
# Usage: preflight_check_timeout <value>
preflight_check_timeout() {
  local value="$1"

  if [[ "$value" =~ ^[1-9][0-9]*$ ]]; then
    return 0
  fi

  echo "VAULT_DOCKERD_TIMEOUT must be a positive integer, got: '$value'" >&2
  return 1
}

# Probes for the privileges dockerd needs by mounting a tmpfs.
# Succeeds under both --privileged and the sysbox runtime.
# Usage: preflight_check_privileges
preflight_check_privileges() {
  local dir
  dir="$(mktemp -d)"

  if _preflight_mount_tmpfs "$dir"; then
    umount "$dir" || true
    rmdir "$dir"
    return 0
  fi

  rmdir "$dir"
  dockerd_privileges_hint >&2
  return 1
}

_preflight_mount_tmpfs() {
  local dir="$1"
  mount -t tmpfs none "$dir" 2>/dev/null
}
