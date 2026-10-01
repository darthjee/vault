#!/usr/bin/env bash
# Library: run, wait for and tear down the docker compose stack.
# Sourcing this file only defines functions.

# Starts docker compose in the background and stores its PID in COMPOSE_PID.
# - no args   -> docker compose up "${COMPOSE_UP_ARGS[@]}"
# - with args -> docker compose "$@"
# COMPOSE_UP_ARGS is a bash array set by the caller; it may be empty or unset.
# stdin is passed through explicitly (<&0): a background job would otherwise
# get /dev/null, breaking passthrough commands such as `exec app sh`.
# Sets the global COMPOSE_PID, read by the entrypoint and the signal handler.
# Usage: compose_run [args...]
compose_run() {
  local args=()

  if [ "$#" -eq 0 ]; then
    args=(up ${COMPOSE_UP_ARGS[@]+"${COMPOSE_UP_ARGS[@]}"})
  else
    args=("$@")
  fi

  _compose "${args[@]}" <&0 &
  # shellcheck disable=SC2034 # read by the entrypoint and the signal handler
  COMPOSE_PID="$!"
}

# Runs `docker compose down` and returns its status.
# Usage: compose_down
compose_down() {
  _compose down
}

# Waits for the compose job and returns its real exit code.
# A trapped signal interrupts `wait` (status 128 + signal); the handler
# increments SIGNALS_HANDLED, so when the counter moved we wait again on the
# same PID, which returns the status bash remembered for the reaped child.
# Usage: compose_wait <pid>
compose_wait() {
  local pid="$1"
  local status
  local handled

  while true; do
    handled="${SIGNALS_HANDLED:-0}"
    status=0
    wait "$pid" || status=$?

    if [ "${SIGNALS_HANDLED:-0}" -eq "$handled" ]; then
      return "$status"
    fi
  done
}

_compose() {
  docker compose "$@"
}
