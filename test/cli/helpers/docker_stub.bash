# shellcheck shell=bash disable=SC2034 # constants are used by the tests
# Test helper: a stub "docker" executable first on PATH.
# Load it with `load helpers/docker_stub` and call docker_stub_setup in setup().
#
# - Each call appends one line to $DOCKER_STUB_LOG: the arguments joined by
#   a tab, so values with spaces stay distinct.
# - Scripted output per subcommand (the first argument), from files under
#   $DOCKER_STUB_DIR: <subcommand>.stdout, <subcommand>.stderr and
#   <subcommand>.status (exit code, default 0). Set them with docker_stub_set.
# - Per call: docker_stub_set_nth scripts the n-th call (1-based) of a
#   subcommand; the other calls keep the plain <subcommand>.* files.
# - Defaults: the daemon is reachable, `docker info` lists runc only and no
#   rootless security option.

# Default `docker info` stdout: runtimes JSON, then security options JSON.
DOCKER_STUB_INFO_RUNC='{"io.containerd.runc.v2":{"path":"runc"},"runc":{"path":"runc"}}'
DOCKER_STUB_INFO_SYSBOX='{"io.containerd.runc.v2":{"path":"runc"},"runc":{"path":"runc"},"sysbox-runc":{"path":"/usr/bin/sysbox-runc"}}'
DOCKER_STUB_SECURITY_DEFAULT='["name=seccomp,profile=builtin","name=cgroupns"]'
DOCKER_STUB_SECURITY_ROOTLESS='["name=seccomp,profile=builtin","name=rootless","name=cgroupns"]'

# Creates the stub, puts it first on PATH and scripts the default outputs.
# Sets DOCKER_STUB_BIN, DOCKER_STUB_DIR and DOCKER_STUB_LOG.
docker_stub_setup() {
  DOCKER_STUB_BIN="$BATS_TEST_TMPDIR/docker-stub/bin"
  DOCKER_STUB_DIR="$BATS_TEST_TMPDIR/docker-stub/out"
  DOCKER_STUB_LOG="$BATS_TEST_TMPDIR/docker-stub/calls.log"
  export DOCKER_STUB_DIR DOCKER_STUB_LOG

  mkdir -p "$DOCKER_STUB_BIN" "$DOCKER_STUB_DIR"
  : >"$DOCKER_STUB_LOG"

  cat >"$DOCKER_STUB_BIN/docker" <<STUB
#!$(command -v bash)
line=""
sep=""
for arg in "\$@"; do
  line="\$line\$sep\$arg"
  sep="\$(printf '\\t')"
done
printf '%s\\n' "\$line" >>"\$DOCKER_STUB_LOG"
sub="\${1:-}"
n=0
while IFS= read -r logged || [ -n "\$logged" ]; do
  if [ "\${logged%%\$(printf '\\t')*}" = "\$sub" ]; then
    n=\$((n + 1))
  fi
done <"\$DOCKER_STUB_LOG"
base="\$DOCKER_STUB_DIR/\$sub"
if [ -f "\$base.\$n.status" ]; then
  base="\$base.\$n"
fi
if [ -f "\$base.stdout" ]; then
  cat "\$base.stdout"
fi
if [ -f "\$base.stderr" ]; then
  cat "\$base.stderr" >&2
fi
status=0
if [ -f "\$base.status" ]; then
  status="\$(cat "\$base.status")"
fi
exit "\$status"
STUB
  chmod 0755 "$DOCKER_STUB_BIN/docker"

  PATH="$DOCKER_STUB_BIN:$PATH"
  export PATH

  docker_stub_info "$DOCKER_STUB_INFO_RUNC" "$DOCKER_STUB_SECURITY_DEFAULT"
}

# Scripts the output of one subcommand.
# Usage: docker_stub_set <subcommand> <stdout> [status] [stderr]
docker_stub_set() {
  local sub="$1"
  printf '%s\n' "$2" >"$DOCKER_STUB_DIR/$sub.stdout"
  printf '%s\n' "${3:-0}" >"$DOCKER_STUB_DIR/$sub.status"
  if [ -n "${4:-}" ]; then
    printf '%s\n' "$4" >"$DOCKER_STUB_DIR/$sub.stderr"
  else
    rm -f "$DOCKER_STUB_DIR/$sub.stderr"
  fi
}

# Scripts the output of the n-th call (1-based) of one subcommand only.
# Usage: docker_stub_set_nth <subcommand> <n> <stdout> [status] [stderr]
docker_stub_set_nth() {
  local sub="$1" n="$2"
  shift 2
  docker_stub_set "$sub.$n" "$@"
}

# Scripts a successful `docker info`: runtimes JSON and security options JSON.
# Usage: docker_stub_info <runtimes-json> <security-options-json>
docker_stub_info() {
  docker_stub_set info "$1
$2"
}

# Scripts a failing `docker info` (daemon unreachable).
# Usage: docker_stub_info_fails
docker_stub_info_fails() {
  docker_stub_set info "" 1 "Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?"
}

# Prints the recorded calls, one per line, arguments tab-separated.
docker_stub_calls() {
  cat "$DOCKER_STUB_LOG"
}

# Prints the number of recorded calls whose first argument is <subcommand>.
# Usage: docker_stub_count <subcommand>
docker_stub_count() {
  local sub="$1" line count=0
  while IFS= read -r line || [ -n "$line" ]; do
    if [ "${line%%	*}" = "$sub" ]; then
      count=$((count + 1))
    fi
  done <"$DOCKER_STUB_LOG"
  printf '%s\n' "$count"
}

# Fails unless one recorded call has exactly the given arguments.
# Usage: assert_docker_called <args...>
assert_docker_called() {
  local expected="" sep="" arg line
  for arg in "$@"; do
    expected="$expected$sep$arg"
    sep="	"
  done
  while IFS= read -r line || [ -n "$line" ]; do
    if [ "$line" = "$expected" ]; then
      return 0
    fi
  done <"$DOCKER_STUB_LOG"
  printf 'expected docker call: %s\nrecorded calls:\n%s\n' "$*" "$(docker_stub_calls)" >&2
  return 1
}

# Fails when any recorded call has <subcommand> as its first argument.
# Usage: assert_docker_not_called <subcommand>
assert_docker_not_called() {
  local count
  count="$(docker_stub_count "$1")"
  if [ "$count" -ne 0 ]; then
    printf 'expected no "docker %s" call, got %s:\n%s\n' "$1" "$count" "$(docker_stub_calls)" >&2
    return 1
  fi
}

# Replaces PATH with one directory linking every executable of the current
# PATH except docker (and the stub), so nothing named docker is reachable.
# Usage: docker_stub_hide
docker_stub_hide() {
  local dir="$BATS_TEST_TMPDIR/no-docker/bin" entry file name
  local old_ifs="$IFS"
  mkdir -p "$dir"
  IFS=:
  # shellcheck disable=SC2086 # split PATH on ":"
  set -- $PATH
  IFS="$old_ifs"
  for entry in "$@"; do
    [ -d "$entry" ] || continue
    [ "$entry" != "$DOCKER_STUB_BIN" ] || continue
    for file in "$entry"/*; do
      name="${file##*/}"
      [ "$name" != docker ] || continue
      [ -x "$file" ] && [ ! -d "$file" ] || continue
      [ -e "$dir/$name" ] || ln -s "$file" "$dir/$name"
    done
  done
  PATH="$dir"
  export PATH
}
