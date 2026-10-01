#!/usr/bin/env bash
# Library: SIGTERM / SIGINT handling and the shutdown sequence.
# Sourcing this file only defines functions.
# Requires compose.sh (compose_down) and dockerd.sh (dockerd_stop) to be
# sourced too.

# Traps TERM and INT to run the shutdown sequence.
# Usage: signals_install
signals_install() {
  trap 'signals_shutdown 15' TERM
  trap 'signals_shutdown 2' INT
}

# Ignores TERM and INT from now on.
# Usage: signals_ignore
signals_ignore() {
  trap '' TERM INT
}

# Shutdown sequence run on TERM / INT. Reads the globals COMPOSE_PID and
# DOCKERD_PID and increments SIGNALS_HANDLED (see compose_wait).
# - compose running: `docker compose down` (a failure only warns), stop
#   dockerd and return, so the caller collects compose's exit code.
# - compose not started: stop dockerd if it was started and exit with
#   128 + <signum>.
# Usage: signals_shutdown <signum>
signals_shutdown() {
  local signum="$1"

  signals_ignore
  SIGNALS_HANDLED=$((${SIGNALS_HANDLED:-0} + 1))

  if [ -n "${COMPOSE_PID:-}" ]; then
    _signals_compose_down
    dockerd_stop "${DOCKERD_PID:-}"
    return 0
  fi

  if [ -n "${DOCKERD_PID:-}" ]; then
    dockerd_stop "$DOCKERD_PID"
  fi
  exit $((128 + signum))
}

_signals_compose_down() {
  if ! compose_down; then
    echo "vault: docker compose down failed" >&2
  fi
}
