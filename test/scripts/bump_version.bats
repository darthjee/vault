#!/usr/bin/env bats
# Tests for scripts/bump_version.sh. The script runs on a temp work tree
# (scripts/test.sh mounts the repo read-only) holding the files it rewrites;
# docs/guides/vault.md is a minimal fixture.
# shellcheck disable=SC2154 # output/stderr/status are set by bats' run

bats_require_minimum_version 1.5.0

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  REPO_ROOT="$BATS_TEST_DIRNAME/../.."
  REPO_URL="https://github.com/darthjee/vault"
  WORK="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$WORK/cli/bin" "$WORK/docs/guides"
  cp -R "$REPO_ROOT/scripts" "$WORK/"

  printf '0.0.1\n' > "$WORK/VERSION"
  printf '# Vault\n\n**Current Version:** [0.0.1](%s/releases/tag/0.0.1)\n\n**Next Release:** [0.0.2](%s/compare/0.0.1...main)\n' \
    "$REPO_URL" "$REPO_URL" > "$WORK/README.md"
  printf '#!/usr/bin/env bash\nVAULT_VERSION="0.0.1"\n' > "$WORK/cli/bin/vault"
  printf '#!/bin/sh\nVAULT_VERSION="0.0.1"\n' > "$WORK/install.sh"
  GUIDES="$WORK/docs/guides/vault.md"
  printf '# Vault guides\n\n**Vault version:** 0.0.1\n\nText.\n' > "$GUIDES"

  SCRIPT="$WORK/scripts/bump_version.sh"
}

run_bump() {
  run --separate-stderr bash "$SCRIPT" "$@"
}

# Prints a checksum of every file the script may write.
snapshot() {
  (cd "$WORK" && cat VERSION README.md cli/bin/vault install.sh docs/guides/vault.md 2>/dev/null | cksum)
}

# Asserts every file carries VERSION and the README points NEXT as next release.
# Usage: assert_bumped VERSION NEXT
assert_bumped() {
  local version="$1" next="$2"
  assert_equal "$(cat "$WORK/VERSION")" "$version"
  run grep -xF "**Current Version:** [$version]($REPO_URL/releases/tag/$version)" "$WORK/README.md"
  assert_success
  run grep -xF "**Next Release:** [$next]($REPO_URL/compare/$version...main)" "$WORK/README.md"
  assert_success
  run grep -x "\*\*Vault version:\*\* $version" "$GUIDES"
  assert_success
  run grep -c 'Vault version' "$GUIDES"
  assert_output "1"
  run grep -x "VAULT_VERSION=\"$version\"" "$WORK/cli/bin/vault"
  assert_success
  run grep -x "VAULT_VERSION=\"$version\"" "$WORK/install.sh"
  assert_success
}

@test "an explicit version bumps VERSION, README, guides and VAULT_VERSION lines" {
  run_bump 1.2.3
  assert_success
  assert_equal "$output" "Version bumped from 0.0.1 to 1.2.3 (next release: 1.2.4)"
  assert_bumped 1.2.3 1.2.4
}

@test "without an argument it bumps the patch version" {
  printf '1.4.7\n' > "$WORK/VERSION"
  run_bump
  assert_success
  assert_equal "$output" "Version bumped from 1.4.7 to 1.4.8 (next release: 1.4.9)"
  assert_bumped 1.4.8 1.4.9
}

@test "patch bumps the patch version" {
  printf '1.4.7\n' > "$WORK/VERSION"
  run_bump patch
  assert_success
  assert_bumped 1.4.8 1.4.9
}

@test "minor bumps the minor version and resets the patch" {
  printf '1.4.7\n' > "$WORK/VERSION"
  run_bump minor
  assert_success
  assert_equal "$output" "Version bumped from 1.4.7 to 1.5.0 (next release: 1.5.1)"
  assert_bumped 1.5.0 1.5.1
}

@test "major bumps the major version and resets minor and patch" {
  printf '1.4.7\n' > "$WORK/VERSION"
  run_bump major
  assert_success
  assert_bumped 2.0.0 2.0.1
}

@test "a plain README version line is rewritten as a link" {
  printf '# Vault\n\n**Current Version:** 0.0.1\n\n**Next Release:** 0.0.2\n' > "$WORK/README.md"
  run_bump
  assert_success
  assert_bumped 0.0.2 0.0.3
}

@test "more than one argument prints usage and exits 1" {
  before="$(snapshot)"
  run_bump 1.2.3 extra
  assert_failure 1
  assert_equal "$stderr" "usage: $SCRIPT [patch|minor|major|X.Y.Z]"
  assert_equal "$(snapshot)" "$before"
}

@test "an invalid version fails" {
  before="$(snapshot)"
  run_bump 1.2
  assert_failure 1
  assert_equal "$stderr" "error: invalid version '1.2' (expected patch, minor, major or X.Y.Z)"
  assert_equal "$(snapshot)" "$before"
}

@test "an invalid VERSION file fails without writing anything" {
  printf 'banana\n' > "$WORK/VERSION"
  before="$(snapshot)"
  run_bump
  assert_failure 1
  assert_equal "$stderr" "error: invalid current version 'banana' in VERSION (expected X.Y.Z)"
  assert_equal "$(snapshot)" "$before"
}

@test "a missing guides file fails without writing anything" {
  rm "$GUIDES"
  before="$(snapshot)"
  run_bump 1.2.3
  assert_failure 1
  assert_equal "$stderr" "error: docs/guides/vault.md not found"
  assert_equal "$(snapshot)" "$before"
}

@test "a guides file without the version line fails without writing anything" {
  printf '# Vault guides\n' > "$GUIDES"
  before="$(snapshot)"
  run_bump 1.2.3
  assert_failure 1
  assert_equal "$stderr" "error: no '**Vault version:**' line found in docs/guides/vault.md"
  assert_equal "$(snapshot)" "$before"
}

@test "a guides file with two version lines fails without writing anything" {
  printf '**Vault version:** 0.0.1\n' >> "$GUIDES"
  before="$(snapshot)"
  run_bump 1.2.3
  assert_failure 1
  assert_equal "$stderr" "error: 2 '**Vault version:**' lines found in docs/guides/vault.md (expected 1)"
  assert_equal "$(snapshot)" "$before"
}

@test "a README without the Current Version line fails without writing anything" {
  printf '# Vault\n\n**Next Release:** 0.0.2\n' > "$WORK/README.md"
  before="$(snapshot)"
  run_bump 1.2.3
  assert_failure 1
  assert_equal "$stderr" "error: no '**Current Version:**' line found in README.md"
  assert_equal "$(snapshot)" "$before"
}

@test "a README without the Next Release line fails without writing anything" {
  printf '# Vault\n\n**Current Version:** 0.0.1\n' > "$WORK/README.md"
  before="$(snapshot)"
  run_bump 1.2.3
  assert_failure 1
  assert_equal "$stderr" "error: no '**Next Release:**' line found in README.md"
  assert_equal "$(snapshot)" "$before"
}

@test "a missing VAULT_VERSION line fails without writing anything" {
  printf '#!/bin/sh\n' > "$WORK/install.sh"
  before="$(snapshot)"
  run_bump 1.2.3
  assert_failure 1
  assert_equal "$stderr" "error: no 'VAULT_VERSION=\"X.Y.Z\"' line found in install.sh"
  assert_equal "$(snapshot)" "$before"
}

@test "duplicated VAULT_VERSION lines fail without writing anything" {
  printf 'VAULT_VERSION="0.0.1"\n' >> "$WORK/cli/bin/vault"
  before="$(snapshot)"
  run_bump 1.2.3
  assert_failure 1
  assert_equal "$stderr" "error: 2 'VAULT_VERSION=\"X.Y.Z\"' lines found in cli/bin/vault (expected 1)"
  assert_equal "$(snapshot)" "$before"
}
