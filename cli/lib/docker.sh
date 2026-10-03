# shellcheck shell=bash
# Library: the single entry point for docker calls.
# Every docker call goes through docker_run_cmd, so tests can stub it (a
# stub "docker" first on PATH, or a redefined function).
# Sourcing this file only defines functions.

# Runs docker with the given arguments, verbatim.
# Usage: docker_run_cmd <args...>
docker_run_cmd() {
  command docker "$@"
}

# Returns 0 when docker is on PATH, 1 otherwise.
# Usage: docker_available
docker_available() {
  command -v docker >/dev/null 2>&1
}
