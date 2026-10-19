#!/usr/bin/env bats
# Tests for scripts/check_reproducible.sh, against a stub docker (no real
# builds). The script runs on a temp copy of the repo, because scripts/test.sh
# mounts the repo read-only and the script may write build/vault.
# shellcheck disable=SC2154 # output/stderr/status are set by bats' run

bats_require_minimum_version 1.5.0

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  load helpers/docker_stub

  docker_stub_setup

  REPO_ROOT="$BATS_TEST_DIRNAME/../.."
  WORK="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$WORK/build"
  cp -R "$REPO_ROOT/scripts" "$REPO_ROOT/cli" "$WORK/"
  printf '#!/bin/sh\n' >"$WORK/build/vault"

  SCRIPT="$WORK/scripts/check_reproducible.sh"
  LAYERS='["sha256:aaa","sha256:bbb","sha256:ccc"]'
  unset SOURCE_DATE_EPOCH APK_REFRESH DOCKER_VERSION DOCKER_STUB_STATUS DOCKER_STUB_BUILD_STATUS
}

run_check() {
  run --separate-stderr bash "$SCRIPT"
}

build_calls() {
  grep '^buildx build ' "$DOCKER_STUB_LOG"
}

@test "identical layer lists exit 0 and report the layer count" {
  docker_stub_inspect vault-repro-check:a "$LAYERS"
  docker_stub_inspect vault-repro-check:b "$LAYERS"
  run_check
  assert_success
  assert_line "reproducible: 3 layers identical"
}

@test "differing layer lists exit 1 and name the differing index" {
  docker_stub_inspect vault-repro-check:a "$LAYERS"
  docker_stub_inspect vault-repro-check:b '["sha256:aaa","sha256:XXX","sha256:ccc"]'
  run_check
  assert_failure 1
  assert_equal "$stderr" "check-reproducible: layers differ at index(es): 1 (3 vs 3 layers)"
  refute_line --partial "layers identical"
}

@test "a different layer count names the extra indexes" {
  docker_stub_inspect vault-repro-check:a "$LAYERS"
  docker_stub_inspect vault-repro-check:b '["sha256:aaa"]'
  run_check
  assert_failure 1
  assert_equal "$stderr" "check-reproducible: layers differ at index(es): 1 2 (3 vs 1 layers)"
}

@test "a failing build exits non-zero and still removes the tags" {
  DOCKER_STUB_BUILD_STATUS=2 run_check
  assert_failure 2
  run grep -c '^image inspect ' "$DOCKER_STUB_LOG"
  assert_output "0"
  run grep -cx 'image rm -f vault-repro-check:a vault-repro-check:b' "$DOCKER_STUB_LOG"
  assert_output "1"
}

@test "both builds use --no-cache, the same APK_REFRESH, epoch 0 and rewrite-timestamp" {
  local month
  month="$(date -u +%Y-%m)"
  docker_stub_inspect vault-repro-check:a "$LAYERS"
  docker_stub_inspect vault-repro-check:b "$LAYERS"
  run_check
  assert_success
  run build_calls
  assert_equal "${#lines[@]}" 2
  assert_equal "${lines[0]}" \
    "buildx build --no-cache --build-arg APK_REFRESH=$month --output type=docker,rewrite-timestamp=true -t vault-repro-check:a ."
  assert_equal "${lines[1]}" \
    "buildx build --no-cache --build-arg APK_REFRESH=$month --output type=docker,rewrite-timestamp=true -t vault-repro-check:b ."
  run sort -u "$DOCKER_STUB_EPOCH_LOG"
  assert_output "0"
}

@test "APK_REFRESH, SOURCE_DATE_EPOCH and DOCKER_VERSION overrides are passed to both builds" {
  docker_stub_inspect vault-repro-check:a "$LAYERS"
  docker_stub_inspect vault-repro-check:b "$LAYERS"
  APK_REFRESH=2020-01 SOURCE_DATE_EPOCH=42 DOCKER_VERSION=27.0.0 run_check
  assert_success
  run build_calls
  assert_equal "${#lines[@]}" 2
  assert_equal "${lines[0]}" \
    "buildx build --no-cache --build-arg APK_REFRESH=2020-01 --output type=docker,rewrite-timestamp=true -t vault-repro-check:a --build-arg DOCKER_VERSION=27.0.0 ."
  assert_equal "${lines[1]}" \
    "buildx build --no-cache --build-arg APK_REFRESH=2020-01 --output type=docker,rewrite-timestamp=true -t vault-repro-check:b --build-arg DOCKER_VERSION=27.0.0 ."
  run sort -u "$DOCKER_STUB_EPOCH_LOG"
  assert_output "42"
}

@test "both tags are removed after the check" {
  docker_stub_inspect vault-repro-check:a "$LAYERS"
  docker_stub_inspect vault-repro-check:b '["sha256:zzz"]'
  run_check
  assert_failure 1
  run tail -n 1 "$DOCKER_STUB_LOG"
  assert_output "image rm -f vault-repro-check:a vault-repro-check:b"
}

@test "a missing build/vault is bundled first" {
  rm -f "$WORK/build/vault"
  docker_stub_inspect vault-repro-check:a "$LAYERS"
  docker_stub_inspect vault-repro-check:b "$LAYERS"
  run_check
  assert_success
  assert [ -x "$WORK/build/vault" ]
}
