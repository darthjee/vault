#!/usr/bin/env bats
# Tests for scripts/github_release.sh, against a stub gh (no real GitHub
# calls). The script runs on a temp copy of the repo, because scripts/test.sh
# mounts the repo read-only and the script writes to build/.
# shellcheck disable=SC2154 # output/stderr/status are set by bats' run

bats_require_minimum_version 1.5.0

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  load helpers/gh_stub

  gh_stub_setup

  REPO_ROOT="$BATS_TEST_DIRNAME/../.."
  WORK="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$WORK"
  cp -R "$REPO_ROOT/scripts" "$REPO_ROOT/cli" "$REPO_ROOT/install.sh" "$WORK/"
  rm -rf "$WORK/build"

  SCRIPT="$WORK/scripts/github_release.sh"
  STAGE="$WORK/build/github-release"
  ASSETS="build/github-release/vault build/github-release/install.sh build/github-release/vault.bash build/github-release/_vault build/github-release/SHA256SUMS"

  GITHUB_TOKEN="test-token"
  export GITHUB_TOKEN
  unset GITHUB_REPOSITORY GH_TOKEN GH_STUB_VIEW_STATUS GH_STUB_CREATE_STATUS GH_STUB_UPLOAD_STATUS
}

run_release() {
  run --separate-stderr bash "$SCRIPT" "$@"
}

@test "without a tag it prints usage, exits 1 and never calls gh" {
  run_release
  assert_failure 1
  assert_equal "$stderr" "usage: $SCRIPT X.Y.Z"
  assert [ ! -s "$GH_STUB_LOG" ]
}

@test "without GITHUB_TOKEN it exits 1 and never calls gh" {
  unset GITHUB_TOKEN
  run_release 1.2.3
  assert_failure 1
  assert_equal "$stderr" "github-release: GITHUB_TOKEN must be set"
  assert [ ! -s "$GH_STUB_LOG" ]
  assert [ ! -e "$WORK/build/vault" ]
}

@test "with an empty GITHUB_TOKEN it exits 1 and never calls gh" {
  GITHUB_TOKEN="" run_release 1.2.3
  assert_failure 1
  assert_equal "$stderr" "github-release: GITHUB_TOKEN must be set"
  assert [ ! -s "$GH_STUB_LOG" ]
}

@test "without gh on PATH it exits 1" {
  local bin="$BATS_TEST_TMPDIR/nogh"
  mkdir -p "$bin"
  ln -s "$(command -v dirname)" "$bin/dirname"
  run --separate-stderr env PATH="$bin" "$(command -v bash)" "$SCRIPT" 1.2.3
  assert_failure 1
  assert_equal "$stderr" "github-release: gh not found in PATH"
}

@test "a new release is created, published as Latest, then the assets are uploaded" {
  run_release 1.2.3
  assert_success
  assert_line "github-release: released 1.2.3 to darthjee/vault"

  run cat "$GH_STUB_LOG"
  assert_equal "${#lines[@]}" 3
  assert_equal "${lines[0]}" "release view 1.2.3 --repo darthjee/vault"
  assert_equal "${lines[1]}" "release create 1.2.3 --repo darthjee/vault --title 1.2.3 --generate-notes --latest --verify-tag"
  assert_equal "${lines[2]}" "release upload 1.2.3 --repo darthjee/vault --clobber $ASSETS"
}

@test "an existing release is kept and its assets are replaced" {
  GH_STUB_VIEW_STATUS=0 run_release 1.2.3
  assert_success
  assert_line "github-release: release 1.2.3 already exists in darthjee/vault; replacing its assets"

  run cat "$GH_STUB_LOG"
  assert_equal "${#lines[@]}" 2
  assert_equal "${lines[0]}" "release view 1.2.3 --repo darthjee/vault"
  assert_equal "${lines[1]}" "release upload 1.2.3 --repo darthjee/vault --clobber $ASSETS"
  refute_output --partial "release create"
}

@test "GITHUB_REPOSITORY overrides the repository" {
  GITHUB_REPOSITORY="someone/fork" run_release 1.2.3
  assert_success

  run cat "$GH_STUB_LOG"
  assert_equal "${lines[1]}" "release create 1.2.3 --repo someone/fork --title 1.2.3 --generate-notes --latest --verify-tag"
  assert_equal "${lines[2]}" "release upload 1.2.3 --repo someone/fork --clobber $ASSETS"
}

@test "gh sees GITHUB_TOKEN as GH_TOKEN" {
  run_release 1.2.3
  assert_success

  run cat "$GH_STUB_TOKEN_LOG"
  assert_equal "${#lines[@]}" 3
  local line
  for line in "${lines[@]}"; do
    assert_equal "$line" "test-token"
  done
}

@test "the staged assets match their sources" {
  run_release 1.2.3
  assert_success

  cmp "$WORK/build/vault" "$STAGE/vault"
  cmp "$WORK/install.sh" "$STAGE/install.sh"
  cmp "$WORK/cli/completion/vault.bash" "$STAGE/vault.bash"
  cmp "$WORK/cli/completion/_vault" "$STAGE/_vault"
}

@test "SHA256SUMS lists the four files by bare name and verifies" {
  run_release 1.2.3
  assert_success

  run cat "$STAGE/SHA256SUMS"
  assert_equal "${#lines[@]}" 4
  assert_regex "${lines[0]}" '^[0-9a-f]{64}  vault$'
  assert_regex "${lines[1]}" '^[0-9a-f]{64}  install.sh$'
  assert_regex "${lines[2]}" '^[0-9a-f]{64}  vault.bash$'
  assert_regex "${lines[3]}" '^[0-9a-f]{64}  _vault$'

  cd "$STAGE"
  run sha256sum -c SHA256SUMS
  assert_success
}

@test "a stale staging dir is wiped" {
  mkdir -p "$STAGE"
  echo stale >"$STAGE/leftover"
  run_release 1.2.3
  assert_success
  assert [ ! -e "$STAGE/leftover" ]
}

@test "a missing asset source fails before calling gh" {
  rm "$WORK/cli/completion/_vault"
  run_release 1.2.3
  assert_failure 1
  assert_equal "$stderr" "github-release: missing asset source: cli/completion/_vault"
  assert [ ! -s "$GH_STUB_LOG" ]
}

@test "a create failure exits non-zero and uploads nothing" {
  GH_STUB_CREATE_STATUS=1 run_release 1.2.3
  assert_failure

  run cat "$GH_STUB_LOG"
  refute_output --partial "release upload"
}

@test "an upload failure exits non-zero" {
  GH_STUB_UPLOAD_STATUS=1 run_release 1.2.3
  assert_failure
  refute_output --partial "github-release: released"
}
