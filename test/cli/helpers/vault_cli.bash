# shellcheck shell=bash disable=SC2034 # variables are used by the tests
# Test helper: run the vault CLI (source tree and bundle) with the stub
# docker. Load it after helpers/docker_stub and call vault_cli_setup in
# setup().

# Sets VAULTS (cli/bin/vault and build/vault), VERSION, IMAGE, PROJ (an
# empty project dir, the cwd) and the common messages; starts the stub
# docker with no vault-proj instance ("No such object").
vault_cli_setup() {
  ROOT="$BATS_TEST_DIRNAME/../.."
  VAULTS=("$ROOT/cli/bin/vault" "$ROOT/build/vault")
  VERSION="$(cat "$ROOT/VERSION")"
  IMAGE="darthjee/vault:$VERSION"
  docker_stub_setup
  unset DOCKER_HOST

  WORK="$BATS_TEST_TMPDIR/work"
  mkdir -p "$WORK/proj"
  WORK="$(cd "$WORK" && pwd)"
  PROJ="$WORK/proj"
  cd "$PROJ" || return

  NO_SUCH='Error response from daemon: No such object: vault-proj'
  DAEMON_DOWN='Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?'
  DAEMON_ERROR="$DAEMON_DOWN
vault: error: cannot reach the Docker daemon
vault: hint: is Docker running, and can this user access it?"
  NOT_RUNNING='vault: error: instance vault-proj is not running'
  # shellcheck disable=SC2016 # a Go template, not shell
  STATUS_FORMAT='{{.Config.Image}}{{"\n"}}{{.Image}}{{"\n"}}{{.HostConfig.Runtime}} {{.HostConfig.Privileged}}{{"\n"}}{{range $p, $b := .HostConfig.PortBindings}}{{range $b}}{{.HostPort}}->{{$p}} {{end}}{{end}}{{"\n"}}{{range .Config.Env}}{{index (split . "=") 0}} {{end}}'

  docker_stub_set inspect "" 1 "$NO_SUCH"
}

# Runs <vault> with the arguments (bats `run --separate-stderr`), after
# clearing the docker call log.
# Usage: vault_run <vault> <args...>
vault_run() {
  local vault="$1"
  shift
  if [ ! -x "$vault" ]; then
    fail "executable not found: $vault (run make bundle-cli)"
  fi
  : >"$DOCKER_STUB_LOG"
  run --separate-stderr "$vault" "$@"
}

# Scripts a running (1st inspect: true) or stopped (false) vault-proj whose
# 2nd inspect (the status one) returns the given lines.
# Usage: vault_stub_instance <true|false> <status-inspect-stdout>
vault_stub_instance() {
  docker_stub_set_nth inspect 1 "$1"
  docker_stub_set_nth inspect 2 "$2"
}
