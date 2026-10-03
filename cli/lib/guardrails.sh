# shellcheck shell=bash
# Library: guardrails (usage errors, exit 2) on the merged volumes and
# ports, flags and .vaultrc entries alike: never mount the host Docker
# socket, never publish the Docker daemon ports 2375/2376.
# Sourcing this file only defines functions.

# Checks every merged volume (CONFIG_VOLUMES) and port (CONFIG_PORTS).
# Usage: guardrails_check_all <docker-host>
#   docker-host: the DOCKER_HOST value ("" when unset), passed by bin/vault
# Returns 2 on the first refusal.
guardrails_check_all() {
  local docker_host="$1" volume port
  for volume in ${CONFIG_VOLUMES[@]+"${CONFIG_VOLUMES[@]}"}; do
    guardrails_check_volume "$volume" "$docker_host" || return
  done
  for port in ${CONFIG_PORTS[@]+"${CONFIG_PORTS[@]}"}; do
    guardrails_check_port "$port" || return
  done
  return 0
}

# Refuses a volume whose source (the text before the first ":", or the
# whole value) is the Docker socket: its last path component is
# docker.sock, or it is the path of a unix:// DOCKER_HOST.
# Usage: guardrails_check_volume <volume> <docker-host>
# Returns 2 with "refusing to mount the Docker socket (<src>)".
guardrails_check_volume() {
  local source="${1%%:*}" docker_host="$2" path last
  path="$(_guardrails_strip_slashes "$source")"
  last="${path##*/}"
  if [ "$last" = docker.sock ] || _guardrails_is_docker_host "$path" "$docker_host"; then
    output_error "refusing to mount the Docker socket ($source)"
    return 2
  fi
  return 0
}

# Refuses a port whose container side (the last ":" field, without /tcp or
# /udp; a single port or an A-B range) is or covers 2375 or 2376. Forms:
# CONTAINER, HOST:CONTAINER, IP:HOST:CONTAINER, [IPv6]:HOST:CONTAINER.
# Usage: guardrails_check_port <port>
# Returns 2 with "refusing to publish the Docker daemon port <2375|2376>".
guardrails_check_port() {
  local container="${1##*:}" first last daemon_port
  container="${container%%/*}"
  case "$container" in
    *-*)
      first="${container%%-*}"
      last="${container#*-}"
      ;;
    *)
      first="$container"
      last="$container"
      ;;
  esac
  _guardrails_is_number "$first" || return 0
  _guardrails_is_number "$last" || return 0
  first=$((10#$first))
  last=$((10#$last))
  for daemon_port in 2375 2376; do
    if [ "$first" -le "$daemon_port" ] && [ "$daemon_port" -le "$last" ]; then
      output_error "refusing to publish the Docker daemon port $daemon_port"
      return 2
    fi
  done
  return 0
}

# Returns 0 when <path> is the path of a unix:// <docker-host>.
# Usage: _guardrails_is_docker_host <path> <docker-host>
_guardrails_is_docker_host() {
  local path="$1" docker_host="$2" socket
  case "$docker_host" in
    unix://?*) ;;
    *) return 1 ;;
  esac
  socket="$(_guardrails_strip_slashes "${docker_host#unix://}")"
  [ "$path" = "$socket" ]
}

# Prints <path> without trailing slashes ("/" stays "/").
# Usage: _guardrails_strip_slashes <path>
_guardrails_strip_slashes() {
  local path="$1"
  while [ "${#path}" -gt 1 ] && [ "${path%/}" != "$path" ]; do
    path="${path%/}"
  done
  printf '%s\n' "$path"
}

# Returns 0 when <value> is a non-empty string of digits.
# Usage: _guardrails_is_number <value>
_guardrails_is_number() {
  case "$1" in
    "" | *[!0123456789]*) return 1 ;;
  esac
  return 0
}
