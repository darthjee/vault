# shellcheck shell=bash
# Test helper: a stub "docker" executable first on PATH (no real docker calls).
# Load it with `load helpers/docker_stub` and call docker_stub_setup in setup().
#
# - Each call appends one line to $DOCKER_STUB_LOG: the arguments joined by a
#   space.
# - Each call appends the SOURCE_DATE_EPOCH it saw to $DOCKER_STUB_EPOCH_LOG
#   ("<unset>" when it was not in the environment).
# - `docker image inspect ... TAG` prints the output registered for TAG with
#   docker_stub_inspect (nothing when none was registered).
# - Exit codes, from env vars (read at call time):
#     docker buildx build -> $DOCKER_STUB_BUILD_STATUS (default $DOCKER_STUB_STATUS)
#     any other call      -> $DOCKER_STUB_STATUS       (default 0)

# Creates the stub and puts it first on PATH.
# Sets DOCKER_STUB_BIN, DOCKER_STUB_LOG, DOCKER_STUB_EPOCH_LOG and
# DOCKER_STUB_INSPECT_DIR.
docker_stub_setup() {
  DOCKER_STUB_BIN="$BATS_TEST_TMPDIR/docker-stub/bin"
  DOCKER_STUB_LOG="$BATS_TEST_TMPDIR/docker-stub/calls.log"
  DOCKER_STUB_EPOCH_LOG="$BATS_TEST_TMPDIR/docker-stub/epoch.log"
  DOCKER_STUB_INSPECT_DIR="$BATS_TEST_TMPDIR/docker-stub/inspect"
  export DOCKER_STUB_LOG DOCKER_STUB_EPOCH_LOG DOCKER_STUB_INSPECT_DIR

  mkdir -p "$DOCKER_STUB_BIN" "$DOCKER_STUB_INSPECT_DIR"
  : >"$DOCKER_STUB_LOG"
  : >"$DOCKER_STUB_EPOCH_LOG"

  cat >"$DOCKER_STUB_BIN/docker" <<STUB
#!$(command -v bash)
printf '%s\\n' "\$*" >>"\$DOCKER_STUB_LOG"
printf '%s\\n' "\${SOURCE_DATE_EPOCH-<unset>}" >>"\$DOCKER_STUB_EPOCH_LOG"
case "\${1:-} \${2:-}" in
  "buildx build") exit "\${DOCKER_STUB_BUILD_STATUS:-\${DOCKER_STUB_STATUS:-0}}" ;;
  "image inspect")
    file="\$DOCKER_STUB_INSPECT_DIR/\$(printf '%s' "\${!#}" | tr ':/' '__')"
    if [ -f "\$file" ]; then
      cat "\$file"
    fi
    ;;
esac
exit "\${DOCKER_STUB_STATUS:-0}"
STUB
  chmod +x "$DOCKER_STUB_BIN/docker"

  PATH="$DOCKER_STUB_BIN:$PATH"
  export PATH
}

# Registers the output `docker image inspect ... TAG` prints.
# Usage: docker_stub_inspect TAG OUTPUT
docker_stub_inspect() {
  printf '%s\n' "$2" >"$DOCKER_STUB_INSPECT_DIR/$(printf '%s' "$1" | tr ':/' '__')"
}
