#!/usr/bin/env bats
# Tests for install.sh (the curl | bash installer), against a stub docker.
# shellcheck disable=SC2154 # output/stderr/status are set by bats' run

bats_require_minimum_version 1.5.0

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  load ../cli/helpers/docker_stub
  load helpers/install_stub

  docker_stub_setup
  install_stub_setup

  INSTALL_SH="$BATS_TEST_DIRNAME/../../install.sh"
  VERSION="$(cat "$BATS_TEST_DIRNAME/../../VERSION")"

  HOME="$BATS_TEST_TMPDIR/home"
  STAGING_TMP="$BATS_TEST_TMPDIR/tmp"
  mkdir -p "$HOME" "$STAGING_TMP"
  export HOME

  BIN_DIR="$HOME/.local/bin"
  COMPLETION_DIR="$HOME/.local/share/vault/completion"
  PATH="$BIN_DIR:$PATH"
  export PATH

  unset VAULT_VERSION VAULT_IMAGE VAULT_INSTALL_DIR
}

# Runs install.sh the way curl | bash does (script on stdin), with its
# staging dir created under $STAGING_TMP.
run_install() {
  TMPDIR="$STAGING_TMP" run --separate-stderr bash <"$INSTALL_SH"
}

# Fails unless <dir> holds the staged vault and its completions.
assert_installed() {
  local bin_dir="$1" mark="${2:-stub}"
  assert [ -x "$bin_dir/vault" ]
  assert_equal "$(cat "$bin_dir/vault")" "vault $mark"
  assert_equal "$(cat "$COMPLETION_DIR/vault.bash")" "vault.bash $mark"
  assert_equal "$(cat "$COMPLETION_DIR/_vault")" "_vault $mark"
}

@test "install.sh has exactly one stamped version line, equal to VERSION" {
  run grep -cE '^VAULT_VERSION="[0-9]+\.[0-9]+\.[0-9]+"$' "$INSTALL_SH"
  assert_output 1
  run grep -E '^VAULT_VERSION=' "$INSTALL_SH"
  assert_output "VAULT_VERSION=\"$VERSION\""
}

@test "installs from the stamped image into the default dirs" {
  run_install

  assert_success
  assert_installed "$BIN_DIR"
  local staging
  staging="$(install_stub_staging)"
  assert [ -n "$staging" ]
  assert_docker_called info
  assert_docker_called run --rm --user "$(id -u):$(id -g)" --entrypoint vault-install \
    -v "$staging:/install" "darthjee/vault:$VERSION"
}

@test "prints the installed line and the completion setup lines on stdout" {
  run_install

  assert_success
  assert_output "installed vault $VERSION to $BIN_DIR/vault
bash completion: source ~/.local/share/vault/completion/vault.bash
zsh completion: add ~/.local/share/vault/completion to fpath"
  assert_equal "$stderr" ""
}

@test "also runs as a file" {
  TMPDIR="$STAGING_TMP" run --separate-stderr bash "$INSTALL_SH"

  assert_success
  assert_installed "$BIN_DIR"
}

@test "VAULT_VERSION pins the image tag and the version shown" {
  VAULT_VERSION=9.9.9 run_install

  assert_success
  assert_line --index 0 "installed vault 9.9.9 to $BIN_DIR/vault"
  assert_docker_called run --rm --user "$(id -u):$(id -g)" --entrypoint vault-install \
    -v "$(install_stub_staging):/install" "darthjee/vault:9.9.9"
}

@test "VAULT_IMAGE overrides the image" {
  VAULT_IMAGE=vault:local run_install

  assert_success
  assert_line --index 0 "installed vault $VERSION to $BIN_DIR/vault"
  assert_docker_called run --rm --user "$(id -u):$(id -g)" --entrypoint vault-install \
    -v "$(install_stub_staging):/install" vault:local
}

@test "VAULT_INSTALL_DIR overrides the install dir" {
  local dir="$BATS_TEST_TMPDIR/my bin"
  mkdir -p "$dir"
  PATH="$dir:$PATH" VAULT_INSTALL_DIR="$dir" run_install

  assert_success
  assert_installed "$dir"
  assert [ ! -e "$BIN_DIR/vault" ]
  assert_line --index 0 "installed vault $VERSION to $dir/vault"
  assert_equal "$stderr" ""
}

@test "creates a missing install dir" {
  local dir="$BATS_TEST_TMPDIR/new/nested/bin"
  PATH="$dir:$PATH" VAULT_INSTALL_DIR="$dir" run_install

  assert_success
  assert_installed "$dir"
}

@test "a non-writable install dir fails before any docker run" {
  if [ "$(id -u)" -eq 0 ]; then
    skip "root can write anywhere"
  fi
  local dir="$BATS_TEST_TMPDIR/locked"
  mkdir -p "$dir"
  chmod 0555 "$dir"
  VAULT_INSTALL_DIR="$dir" run_install
  chmod 0755 "$dir"

  assert_failure 1
  assert_equal "$stderr" "vault: error: $dir is not writable"
  assert_docker_not_called run
}

@test "an install dir that cannot be created fails before any docker run" {
  if [ "$(id -u)" -eq 0 ]; then
    skip "root can write anywhere"
  fi
  local parent="$BATS_TEST_TMPDIR/locked"
  mkdir -p "$parent"
  chmod 0555 "$parent"
  VAULT_INSTALL_DIR="$parent/bin" run_install
  chmod 0755 "$parent"

  assert_failure 1
  assert_equal "$stderr" "vault: error: $parent/bin is not writable"
  assert_docker_not_called run
}

@test "an install dir that is a file fails before any docker run" {
  local file="$BATS_TEST_TMPDIR/a-file"
  touch "$file"
  VAULT_INSTALL_DIR="$file" run_install

  assert_failure 1
  assert_equal "$stderr" "vault: error: $file is not writable"
  assert_docker_not_called run
}

@test "docker missing from PATH fails" {
  docker_stub_hide
  run_install

  assert_failure 1
  assert_equal "$stderr" "vault: error: docker not found in PATH"
  assert_output ""
}

@test "an unreachable daemon fails with a hint" {
  docker_stub_info_fails
  run_install

  assert_failure 1
  assert_equal "$stderr" "vault: error: cannot reach the Docker daemon
vault: hint: is Docker running, and can this user access it?"
  assert_docker_not_called run
  assert [ ! -e "$BIN_DIR" ]
}

@test "a failing docker run fails and leaves the install dir untouched" {
  mkdir -p "$BIN_DIR"
  printf 'old\n' >"$BIN_DIR/vault"
  docker_stub_set run "" 125 "docker: Error response from daemon: manifest unknown."
  run_install

  assert_failure 1
  assert_equal "$stderr" "docker: Error response from daemon: manifest unknown.
vault: error: failed to install from darthjee/vault:$VERSION"
  assert_output ""
  assert_equal "$(cat "$BIN_DIR/vault")" "old"
  assert_equal "$(find "$BIN_DIR" -mindepth 1)" "$BIN_DIR/vault"
  assert [ ! -e "$COMPLETION_DIR" ]
}

@test "warns when the install dir is not in PATH, and still succeeds" {
  PATH="${PATH#"$BIN_DIR":}" run_install

  assert_success
  assert_installed "$BIN_DIR"
  # shellcheck disable=SC2016 # $PATH is printed literally
  assert_equal "$stderr" "vault: warning: $BIN_DIR is not in PATH; add: export PATH=\"$BIN_DIR:"'$PATH"'
}

@test "a prefix of a PATH entry is not a match" {
  PATH="$BIN_DIR-other:${PATH#"$BIN_DIR":}" run_install

  assert_success
  assert_output --partial "installed vault"
  assert_equal "${stderr%%;*}" "vault: warning: $BIN_DIR is not in PATH"
}

@test "no warning when the PATH entry has a trailing slash" {
  PATH="$BIN_DIR/:${PATH#"$BIN_DIR":}" run_install

  assert_success
  assert_equal "$stderr" ""
}

@test "no warning when the install dir has a trailing slash" {
  VAULT_INSTALL_DIR="$BIN_DIR/" run_install

  assert_success
  assert_equal "$stderr" ""
}

@test "re-running overwrites an existing install" {
  INSTALL_STUB_MARK=first run_install
  assert_success
  assert_installed "$BIN_DIR" first

  INSTALL_STUB_MARK=second run_install
  assert_success
  assert_installed "$BIN_DIR" second
}

@test "removes the staging dir afterwards" {
  run_install

  assert_success
  assert [ ! -e "$(install_stub_staging)" ]
  assert_equal "$(find "$STAGING_TMP" -mindepth 1)" ""
}

@test "removes the staging dir when docker run fails" {
  docker_stub_set run "" 1
  run_install

  assert_failure 1
  assert [ ! -e "$(install_stub_staging)" ]
  assert_equal "$(find "$STAGING_TMP" -mindepth 1)" ""
}

@test "writes nothing outside the install, completion and staging dirs" {
  run_install

  assert_success
  assert_equal "$(cd "$HOME" && find . -type f | sort)" "./.local/bin/vault
./.local/share/vault/completion/_vault
./.local/share/vault/completion/vault.bash"
}
