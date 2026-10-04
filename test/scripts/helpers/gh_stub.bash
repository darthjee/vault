# shellcheck shell=bash
# Test helper: a stub "gh" executable first on PATH (no real GitHub calls).
# Load it with `load helpers/gh_stub` and call gh_stub_setup in setup().
#
# - Each call appends one line to $GH_STUB_LOG: the arguments joined by a
#   space.
# - Each call appends the GH_TOKEN it saw to $GH_STUB_TOKEN_LOG.
# - Exit codes, from env vars (read at call time):
#     gh release view    -> $GH_STUB_VIEW_STATUS   (default 1: no release yet)
#     gh release create  -> $GH_STUB_CREATE_STATUS (default 0)
#     gh release upload  -> $GH_STUB_UPLOAD_STATUS (default 0)
#   Any other call exits 0.

# Creates the stub and puts it first on PATH.
# Sets GH_STUB_BIN, GH_STUB_LOG and GH_STUB_TOKEN_LOG.
gh_stub_setup() {
  GH_STUB_BIN="$BATS_TEST_TMPDIR/gh-stub/bin"
  GH_STUB_LOG="$BATS_TEST_TMPDIR/gh-stub/calls.log"
  GH_STUB_TOKEN_LOG="$BATS_TEST_TMPDIR/gh-stub/token.log"
  export GH_STUB_LOG GH_STUB_TOKEN_LOG

  mkdir -p "$GH_STUB_BIN"
  : >"$GH_STUB_LOG"
  : >"$GH_STUB_TOKEN_LOG"

  cat >"$GH_STUB_BIN/gh" <<STUB
#!$(command -v bash)
printf '%s\\n' "\$*" >>"\$GH_STUB_LOG"
printf '%s\\n' "\${GH_TOKEN:-}" >>"\$GH_STUB_TOKEN_LOG"
case "\${1:-} \${2:-}" in
  "release view") exit "\${GH_STUB_VIEW_STATUS:-1}" ;;
  "release create") exit "\${GH_STUB_CREATE_STATUS:-0}" ;;
  "release upload") exit "\${GH_STUB_UPLOAD_STATUS:-0}" ;;
esac
exit 0
STUB
  chmod +x "$GH_STUB_BIN/gh"

  PATH="$GH_STUB_BIN:$PATH"
  export PATH
}
