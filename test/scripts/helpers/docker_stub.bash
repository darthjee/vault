# shellcheck shell=bash
# Test helper: a stub "docker" executable first on PATH (no real docker calls).
# Load it with `load helpers/docker_stub` and call docker_stub_setup in setup().
#
# - Each call appends one line to $DOCKER_STUB_LOG: the arguments joined by a
#   space.
# - Each call appends the SOURCE_DATE_EPOCH it saw to $DOCKER_STUB_EPOCH_LOG
#   ("<unset>" when it was not in the environment).
# - Each call exits with $DOCKER_STUB_STATUS (default 0), read at call time.

# Creates the stub and puts it first on PATH.
# Sets DOCKER_STUB_BIN, DOCKER_STUB_LOG and DOCKER_STUB_EPOCH_LOG.
docker_stub_setup() {
  DOCKER_STUB_BIN="$BATS_TEST_TMPDIR/docker-stub/bin"
  DOCKER_STUB_LOG="$BATS_TEST_TMPDIR/docker-stub/calls.log"
  DOCKER_STUB_EPOCH_LOG="$BATS_TEST_TMPDIR/docker-stub/epoch.log"
  export DOCKER_STUB_LOG DOCKER_STUB_EPOCH_LOG

  mkdir -p "$DOCKER_STUB_BIN"
  : >"$DOCKER_STUB_LOG"
  : >"$DOCKER_STUB_EPOCH_LOG"

  cat >"$DOCKER_STUB_BIN/docker" <<STUB
#!$(command -v bash)
printf '%s\\n' "\$*" >>"\$DOCKER_STUB_LOG"
printf '%s\\n' "\${SOURCE_DATE_EPOCH-<unset>}" >>"\$DOCKER_STUB_EPOCH_LOG"
exit "\${DOCKER_STUB_STATUS:-0}"
STUB
  chmod +x "$DOCKER_STUB_BIN/docker"

  PATH="$DOCKER_STUB_BIN:$PATH"
  export PATH
}
