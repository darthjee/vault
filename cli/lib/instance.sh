# shellcheck shell=bash disable=SC2034 # INSTANCE_* globals are read by callers
# Library: the state of a vault-<name> instance and the TTY flags.
# Sourcing this file only defines functions.

# Reads the state of vault-<name> with one `docker inspect`.
# Usage: instance_state <name>
# Sets INSTANCE_STATE: running (.State.Running is true), stopped (any other
# value) or missing (docker reports "No such object"; its error is hidden).
# Any other docker failure: docker's error is passed through on stderr, then
# "cannot reach the Docker daemon" + hint, return 1.
instance_state() {
  local container out rc=0

  container="$(naming_container "$1")"
  INSTANCE_STATE=""
  out="$(docker_run_cmd inspect --format '{{.State.Running}}' "$container" 2>&1)" || rc=$?

  if [ "$rc" -eq 0 ]; then
    case "$out" in
      true | *$'\n'true) INSTANCE_STATE=running ;;
      *) INSTANCE_STATE=stopped ;;
    esac
    return 0
  fi

  case "$out" in
    *'No such object'*)
      INSTANCE_STATE=missing
      return 0
      ;;
  esac

  if [ -n "$out" ]; then
    printf '%s\n' "$out" >&2
  fi
  output_error 'cannot reach the Docker daemon'
  output_hint 'is Docker running, and can this user access it?'
  return 1
}

# Fails unless vault-<name> is running (used by logs and compose).
# Usage: instance_require_running <name>
# Returns 1 with "instance vault-<name> is not running" when it is stopped
# or missing, or 1 when the daemon cannot be reached.
instance_require_running() {
  instance_state "$1" || return
  if [ "$INSTANCE_STATE" != running ]; then
    output_error "instance $(naming_container "$1") is not running"
    return 1
  fi
  return 0
}

# Fills INSTANCE_TTY_ARGS with -i when stdin is a TTY and -t when stdout is
# a TTY, always in that order (run and compose only).
# Usage: instance_tty_flags
instance_tty_flags() {
  INSTANCE_TTY_ARGS=()
  if [ -t 0 ]; then
    INSTANCE_TTY_ARGS+=(-i)
  fi
  if [ -t 1 ]; then
    INSTANCE_TTY_ARGS+=(-t)
  fi
  return 0
}
