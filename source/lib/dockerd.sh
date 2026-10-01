#!/usr/bin/env bash
# Library: start, wait for and stop the inner Docker daemon.
# Sourcing this file only defines functions.

# Starts dockerd in the background through the dind entrypoint, listening
# only on the unix socket, and stores its PID in DOCKERD_PID.
# Passing `dockerd` explicitly keeps the dind entrypoint from adding its
# default --host list (which includes a TCP host).
# Sets the global DOCKERD_PID, read by the entrypoint.
# Usage: dockerd_start
dockerd_start() {
  dockerd-entrypoint.sh dockerd --host=unix:///var/run/docker.sock &
  # shellcheck disable=SC2034 # read by the entrypoint
  DOCKERD_PID="$!"
}

# Polls `docker info` once per second until it succeeds, up to <timeout>
# polls. Prints the privileges hint and returns 1 on timeout.
# Usage: dockerd_wait <timeout>
dockerd_wait() {
  local timeout="$1"
  local attempt

  for ((attempt = 0; attempt < timeout; attempt++)); do
    if _dockerd_ready; then
      return 0
    fi
    sleep 1
  done

  dockerd_privileges_hint >&2
  return 1
}

# Sends SIGTERM to dockerd and waits for it to exit.
# An already-dead process is ignored.
# Usage: dockerd_stop <pid>
dockerd_stop() {
  local pid="$1"

  kill -TERM "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
}

# Prints the hint shown when dockerd cannot run (missing privileges).
dockerd_privileges_hint() {
  echo "dockerd failed to start; are you running with --privileged (or the sysbox runtime)?"
}

_dockerd_ready() {
  docker info >/dev/null 2>&1
}
