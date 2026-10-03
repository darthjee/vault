#!/usr/bin/env bats
# Tests for cli/lib/naming.sh (instance naming).
# shellcheck disable=SC2154 # output/stderr/status are set by bats' run

bats_require_minimum_version 1.5.0

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  ROOT="$BATS_TEST_DIRNAME/../.."
  # shellcheck source=SCRIPTDIR/../../cli/lib/output.sh
  source "$ROOT/cli/lib/output.sh"
  # shellcheck source=SCRIPTDIR/../../cli/lib/args.sh
  source "$ROOT/cli/lib/args.sh"
  # shellcheck source=SCRIPTDIR/../../cli/lib/naming.sh
  source "$ROOT/cli/lib/naming.sh"
}

@test "naming_from_image drops registry, path, tag and digest" {
  assert_equal "$(naming_from_image my-app)" my-app
  assert_equal "$(naming_from_image my-app:1.0)" my-app
  assert_equal "$(naming_from_image darthjee/vault:0.2.0)" vault
  assert_equal "$(naming_from_image registry.example.com/team/my-app:1.0)" my-app
  assert_equal "$(naming_from_image registry.example.com:5000/team/my-app:1.0)" my-app
  assert_equal "$(naming_from_image registry.example.com:5000/my-app)" my-app
  assert_equal "$(naming_from_image team/my-app@sha256:abcdef)" my-app
  assert_equal "$(naming_from_image team/my-app:1.0@sha256:abcdef)" my-app
}

@test "naming_sanitize lowercases and drops characters outside [a-z0-9_.-]" {
  assert_equal "$(naming_sanitize 'My App!')" myapp
  assert_equal "$(naming_sanitize 'Proj_1.2-x')" proj_1.2-x
  assert_equal "$(naming_sanitize 'çé ABC')" abc
  assert_equal "$(naming_sanitize '!!!')" ""
}

@test "naming_valid matches [a-z0-9][a-z0-9_.-]*" {
  naming_valid my-app
  naming_valid 0.a_b
  run naming_valid My-App
  assert_failure
  run naming_valid -app
  assert_failure
  run naming_valid ""
  assert_failure
}

@test "naming_container and naming_volume" {
  assert_equal "$(naming_container my-app)" vault-my-app
  assert_equal "$(naming_volume my-app)" vault-my-app-data
}

@test "an explicit name wins over --image and [dir], unaltered" {
  naming_resolve my.app 1 registry/other:1 1 /src/Proj

  assert_equal "$NAMING_NAME" my.app
}

@test "--image without [dir] gives the image name" {
  naming_resolve "" 1 registry.example.com/team/My-App:1.0 0 /work/cwd

  assert_equal "$NAMING_NAME" my-app
}

@test "--image with [dir] gives the basename of [dir]" {
  naming_resolve "" 1 registry/team/other:1 1 /src/proj

  assert_equal "$NAMING_NAME" proj
}

@test "no --image gives the basename of the dir, sanitized" {
  naming_resolve "" 0 darthjee/vault:0.0.1 0 "/home/me/My App!"

  assert_equal "$NAMING_NAME" myapp
}

@test "trailing slashes are ignored in the dir" {
  naming_resolve "" 0 "" 1 /src/proj//

  assert_equal "$NAMING_NAME" proj
}

@test "an empty sanitized dir basename fails with the hint (exit 2)" {
  run --separate-stderr naming_resolve "" 0 "" 1 "/src/!!!"

  assert_failure 2
  assert_output ""
  assert_equal "$stderr" "vault: error: cannot derive an instance name from '!!!'
vault: hint: pass --name <name>"
}

@test "the root directory cannot give a name (exit 2)" {
  run --separate-stderr naming_resolve "" 0 "" 0 /

  assert_failure 2
  assert_equal "$stderr" "vault: error: cannot derive an instance name from '/'
vault: hint: pass --name <name>"
}

@test "an empty sanitized image name fails with the hint (exit 2)" {
  run --separate-stderr naming_resolve "" 1 "registry/ÉÉ:1" 0 /work

  assert_failure 2
  assert_equal "$stderr" "vault: error: cannot derive an instance name from 'ÉÉ'
vault: hint: pass --name <name>"
}
