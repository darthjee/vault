#!/usr/bin/env bash
# Library: copy the bundled CLI and its shell completions into a target dir.
# Sourcing this file only defines functions.

# Copies <bin> to <target>/vault (0755) and vault.bash / _vault from
# <completion_dir> to <target>/completion/ (0644). Prints nothing on success.
# Fails with "vault-install: error: <target> is not writable" when <target>
# is missing, not a directory or not writable; returns 1 on any failure.
# Usage: install_copy <bin> <completion_dir> <target>
install_copy() {
  local bin="$1"
  local completion_dir="$2"
  local target="$3"

  if ! _install_check_target "$target"; then
    echo "vault-install: error: $target is not writable" >&2
    return 1
  fi

  _install_copy_file "$bin" "$target/vault" 0755 || return 1
  mkdir -p "$target/completion" || return 1
  _install_copy_file "$completion_dir/vault.bash" "$target/completion/vault.bash" 0644 || return 1
  _install_copy_file "$completion_dir/_vault" "$target/completion/_vault" 0644 || return 1
}

_install_check_target() {
  local target="$1"
  [ -d "$target" ] && [ -w "$target" ]
}

_install_copy_file() {
  local src="$1"
  local dest="$2"
  local mode="$3"

  cp "$src" "$dest" && chmod "$mode" "$dest"
}
