# shellcheck shell=bash disable=SC2034 # RUNTIME_* globals are read by callers
# Library: docker pre-checks and runtime selection (Sysbox or --privileged).
# Sourcing this file only defines functions.

# Fails when docker is not on PATH.
# Usage: runtime_check_docker
# Returns 1 with "docker not found in PATH".
runtime_check_docker() {
  if ! docker_available; then
    output_error 'docker not found in PATH'
    return 1
  fi
  return 0
}

# Calls `docker info` once, reading the runtimes and the security options.
# Usage: runtime_probe
# Sets: RUNTIME_SYSBOX (1 when sysbox-runc is listed in .Runtimes),
#   RUNTIME_ROOTLESS (1 when a security option contains "rootless").
# Returns 1 when docker info fails (daemon unreachable); docker's own error
# is passed through on stderr, before the CLI's message.
runtime_probe() {
  local out runtimes security

  RUNTIME_SYSBOX=0
  RUNTIME_ROOTLESS=0
  if ! out="$(docker_run_cmd info --format '{{json .Runtimes}}{{"\n"}}{{json .SecurityOptions}}')"; then
    output_error 'cannot reach the Docker daemon'
    output_hint 'is Docker running, and can this user access it?'
    return 1
  fi

  runtimes="${out%%$'\n'*}"
  security=""
  case "$out" in
    *$'\n'*) security="${out#*$'\n'}" ;;
  esac

  case "$runtimes" in
    *'"sysbox-runc"'*) RUNTIME_SYSBOX=1 ;;
  esac
  case "$security" in
    *rootless*) RUNTIME_ROOTLESS=1 ;;
  esac
  return 0
}

# Refuses a rootless daemon (whatever the runtime). Call after runtime_probe.
# Usage: runtime_check_rootless
# Returns 1 with "rootless Docker is not supported" + hint.
runtime_check_rootless() {
  if [ "$RUNTIME_ROOTLESS" = 1 ]; then
    output_error 'rootless Docker is not supported'
    output_hint 'see Security in the README'
    return 1
  fi
  return 0
}

# Picks the runtime argument from the requested runtime and the probe.
# Call after runtime_probe.
# Usage: runtime_select <auto|sysbox|privileged>
# Sets: RUNTIME_ARG (--runtime=sysbox-runc or --privileged).
#   auto + Sysbox       -> --runtime=sysbox-runc
#   auto, no Sysbox     -> --privileged, with the fallback warning (the only warning)
#   sysbox + Sysbox     -> --runtime=sysbox-runc
#   sysbox, no Sysbox   -> error, return 1 (never falls back)
#   privileged          -> --privileged, no warning
runtime_select() {
  RUNTIME_ARG=""
  case "$1" in
    auto)
      if [ "$RUNTIME_SYSBOX" = 1 ]; then
        RUNTIME_ARG='--runtime=sysbox-runc'
      else
        output_warning 'sysbox-runc not found; running with --privileged (see Security in the README)'
        RUNTIME_ARG='--privileged'
      fi
      ;;
    sysbox)
      if [ "$RUNTIME_SYSBOX" != 1 ]; then
        output_error '--runtime=sysbox requested but sysbox-runc is not available'
        return 1
      fi
      RUNTIME_ARG='--runtime=sysbox-runc'
      ;;
    privileged)
      RUNTIME_ARG='--privileged'
      ;;
    *)
      output_error "invalid value for --runtime: '$1'"
      return 2
      ;;
  esac
  return 0
}

# Runs the daemon pre-checks of up/run, in order: docker info (daemon
# reachable), rootless, then the runtime table.
# Usage: runtime_resolve <auto|sysbox|privileged>
# Sets RUNTIME_SYSBOX, RUNTIME_ROOTLESS and RUNTIME_ARG. Returns 1 on failure.
runtime_resolve() {
  runtime_probe || return
  runtime_check_rootless || return
  runtime_select "$1"
}
