# shellcheck shell=bash disable=SC2034 # INSTANCE_* globals are read by callers
# Library: the state of a vault-<name> instance and the TTY flags.
# Sourcing this file only defines functions.

# Reads the state of vault-<name> with one `docker inspect`.
# Usage: instance_state <name>
# Sets INSTANCE_STATE: running (.State.Running is true), stopped (any other
# value) or missing (docker reports "No such object", any case of the
# leading letter as docker versions differ; its error is hidden).
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
    *'No such object'* | *'no such object'*)
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

# Prints the status block of vault-<name> to stdout (see "Status output" in
# the CLI spec). <state> comes from instance_state. A missing instance
# prints only name and state (not found); otherwise one `docker inspect`
# reads the image, runtime, ports and env keys (never env values).
# Usage: instance_status_print <name> <running|stopped|missing>
# Returns 1 when docker inspect fails (its error is passed through).
instance_status_print() {
  local name="$1" state="$2" container out image runtime ports envs

  container="$(naming_container "$name")"
  if [ "$state" = missing ]; then
    _instance_status_line name "$container"
    _instance_status_line state 'not found'
    return 0
  fi

  out="$(docker_run_cmd inspect --format "$(_instance_status_format)" "$container")" || return 1
  image="$(_instance_line "$out" 1)"
  runtime="$(_instance_line "$out" 2)"
  ports="$(_instance_join "$(_instance_line "$out" 3)")"
  envs="$(_instance_join "$(_instance_line "$out" 4)")"
  case "$runtime" in
    sysbox-runc) ;;
    *) runtime=privileged ;;
  esac

  _instance_status_line name "$container"
  _instance_status_line state "$state"
  _instance_status_line image "$image"
  _instance_status_line runtime "$runtime"
  _instance_status_line ports "$ports"
  _instance_status_line volume "$(naming_volume "$name")"
  _instance_status_line env "$envs"
}

# Warns when none of the compose file names exists in <dir> (the inner
# stack may still find one through COMPOSE_FILE).
# Usage: instance_check_compose_file <dir>
instance_check_compose_file() {
  local file
  for file in compose.yaml compose.yml docker-compose.yaml docker-compose.yml; do
    if [ -f "$1/$file" ]; then
      return 0
    fi
  done
  output_warning "no compose file found in $1; relying on COMPOSE_FILE"
  return 0
}

# Runs docker with the given arguments. Its stderr is shown as it comes and
# copied to <stderr-file>; with <quiet> = 1 its stdout is discarded (the
# container ID of `docker run -d`). SIGINT is ignored by the copy, so
# Ctrl+C only reaches docker (graceful shutdown under `up -f`).
# Usage: instance_docker_run <stderr-file> <quiet 0|1> <args...>
# Returns docker's exit code.
instance_docker_run() {
  local file="$1" quiet="$2" rc=0
  shift 2

  if [ "$quiet" = 1 ]; then
    { docker_run_cmd "$@" 2>&1 >/dev/null | _instance_copy_stderr "$file"; } || rc=${PIPESTATUS[0]}
  else
    { docker_run_cmd "$@" 2>&1 1>&3 3>&- | _instance_copy_stderr "$file"; } 3>&1 || rc=${PIPESTATUS[0]}
  fi
  return "$rc"
}

# Turns the exit code of a `docker run` into the CLI's (contract 5).
# docker's stderr has already been shown.
# Usage: instance_run_result <status> <stderr> <passthrough 0|1>
#   status 0                               -> 0
#   passthrough and status not 125..127    -> status (the inner command's)
#   otherwise (the container did not start), reads RUNTIME_ARG:
#     stderr has "port is already allocated" or "address already in use"
#                                          -> port hint, 1
#     --runtime=sysbox-runc                -> Sysbox error + hint, 1
#     --privileged                         -> 1 (docker's error only)
instance_run_result() {
  local status="$1" err="$2" passthrough="$3"

  if [ "$status" -eq 0 ]; then
    return 0
  fi
  if [ "$passthrough" = 1 ]; then
    case "$status" in
      125 | 126 | 127) ;;
      *) return "$status" ;;
    esac
  fi

  case "$err" in
    *'port is already allocated'* | *'address already in use'*)
      output_hint 'choose another host port with -p HOST:80'
      return 1
      ;;
  esac
  if [ "${RUNTIME_ARG:-}" = '--runtime=sysbox-runc' ]; then
    output_error 'sysbox-runc failed to start the container'
    output_hint 'fix sysbox or use --runtime=privileged'
  fi
  return 1
}

# Copies stdin to stderr and to <file>, ignoring SIGINT.
# Usage: _instance_copy_stderr <file>
_instance_copy_stderr() {
  (
    trap '' INT
    tee "$1" >&2
  )
}

# Prints the `docker inspect` format of instance_status_print: one line
# each for the image, the runtime, the published ports (HOST->CONTAINER,
# space-separated) and the env keys (space-separated, values dropped).
# Usage: _instance_status_format
_instance_status_format() {
  # shellcheck disable=SC2016 # a Go template, not shell
  printf '%s' '{{.Config.Image}}{{"\n"}}{{.HostConfig.Runtime}}{{"\n"}}{{range $p, $b := .HostConfig.PortBindings}}{{range $b}}{{.HostPort}}->{{$p}} {{end}}{{end}}{{"\n"}}{{range .Config.Env}}{{index (split . "=") 0}} {{end}}'
}

# Prints line <n> (1-based) of <text>, or nothing.
# Usage: _instance_line <text> <n>
_instance_line() {
  local text="$1" n="$2" line i=0
  while IFS= read -r line || [ -n "$line" ]; do
    i=$((i + 1))
    if [ "$i" -eq "$n" ]; then
      printf '%s\n' "$line"
      return 0
    fi
  done <<<"$text"
  return 0
}

# Joins space-separated words with ", ".
# Usage: _instance_join <words>
_instance_join() {
  local word out="" sep=""
  for word in $1; do
    out="$out$sep$word"
    sep=', '
  done
  printf '%s\n' "$out"
}

# Prints one status line, the label padded to the width of "runtime:" + 1.
# Usage: _instance_status_line <label> <value>
_instance_status_line() {
  printf '%-9s %s\n' "$1:" "$2"
}
