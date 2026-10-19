#!/usr/bin/env bats
# Tests for scripts/release.sh, against a stub docker (no real builds).
# shellcheck disable=SC2154 # output/stderr/status are set by bats' run

bats_require_minimum_version 1.5.0

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  load helpers/docker_stub

  docker_stub_setup

  SCRIPT="$BATS_TEST_DIRNAME/../../scripts/release.sh"
  unset RELEASE_IMAGE PUSH DOCKER_VERSION SOURCE_DATE_EPOCH APK_REFRESH DOCKER_STUB_STATUS
}

run_release() {
  run --separate-stderr bash "$SCRIPT" "$@"
}

@test "without a tag it prints usage, exits 1 and never calls docker" {
  run_release
  assert_failure 1
  assert_equal "$stderr" "usage: $SCRIPT X.Y.Z"
  assert [ ! -s "$DOCKER_STUB_LOG" ]
}

@test "with an invalid PUSH it exits 1 and never calls docker" {
  PUSH=yes run_release 1.2.3
  assert_failure 1
  assert_equal "$stderr" "release: PUSH must be 'true' or 'false' (got 'yes')"
  assert [ ! -s "$DOCKER_STUB_LOG" ]
}

@test "by default it builds both platforms, tags, pushes with a fixed epoch" {
  local month
  month="$(date -u +%Y-%m)"
  run_release 1.2.3
  assert_success
  assert_equal "$(cat "$DOCKER_STUB_LOG")" \
    "buildx build --platform linux/amd64,linux/arm64 -t darthjee/vault:1.2.3 -t darthjee/vault:latest --build-arg APK_REFRESH=$month --output type=image,push=true,rewrite-timestamp=true ."
  assert_equal "$(cat "$DOCKER_STUB_EPOCH_LOG")" "0"
}

@test "with PUSH=false the output does not push" {
  PUSH=false run_release 1.2.3
  assert_success
  run grep -c -- "--output type=image,push=false,rewrite-timestamp=true" "$DOCKER_STUB_LOG"
  assert_output "1"
  run grep -c -- "--push" "$DOCKER_STUB_LOG"
  assert_output "0"
}

@test "APK_REFRESH, SOURCE_DATE_EPOCH, DOCKER_VERSION and RELEASE_IMAGE overrides are passed through" {
  APK_REFRESH=2020-01 SOURCE_DATE_EPOCH=1700000000 DOCKER_VERSION=27.0.0 \
    RELEASE_IMAGE=me/img run_release 2.0.0
  assert_success
  assert_equal "$(cat "$DOCKER_STUB_LOG")" \
    "buildx build --platform linux/amd64,linux/arm64 -t me/img:2.0.0 -t me/img:latest --build-arg APK_REFRESH=2020-01 --output type=image,push=true,rewrite-timestamp=true --build-arg DOCKER_VERSION=27.0.0 ."
  assert_equal "$(cat "$DOCKER_STUB_EPOCH_LOG")" "1700000000"
}

@test "a docker failure makes the release fail" {
  DOCKER_STUB_STATUS=3 run_release 1.2.3
  assert_failure 3
}
