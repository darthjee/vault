#!/usr/bin/env bash
# Installs the vault CLI and its shell completions from the Vault image.
#
# Usage:
#   curl -fsSL https://github.com/darthjee/vault/releases/latest/download/install.sh | bash
#
# Environment:
#   VAULT_VERSION      version to install (default: the version stamped below)
#   VAULT_INSTALL_DIR  where vault is copied (default: $HOME/.local/bin)
#   VAULT_IMAGE        image to install from (default: darthjee/vault:$VAULT_VERSION)
#
# It runs the image's vault-install entry, as the current user, against a
# staging dir, then moves the CLI into the install dir and the completions
# into ~/.local/share/vault/completion/. It never calls sudo.
#
# Self-contained (fetched with curl | bash): it sources nothing. Everything
# runs from main, called on the last line, so a truncated download runs nothing.
set -euo pipefail

requested_version="${VAULT_VERSION:-}"
VAULT_VERSION="0.1.0"
version="${requested_version:-$VAULT_VERSION}"

image="${VAULT_IMAGE:-darthjee/vault:$version}"
install_dir="${VAULT_INSTALL_DIR:-$HOME/.local/bin}"
completion_dir="$HOME/.local/share/vault/completion"
staging=""

main() {
  install_check_docker
  install_check_dir
  staging="$(mktemp -d)"
  trap install_cleanup EXIT
  install_fetch
  install_move
  install_report
  install_check_path
}

# Fails unless docker is on PATH and its daemon is reachable.
install_check_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    install_error "docker not found in PATH"
    exit 1
  fi
  if ! docker info >/dev/null 2>&1; then
    install_error "cannot reach the Docker daemon"
    install_hint "is Docker running, and can this user access it?"
    exit 1
  fi
}

# Creates the install dir when missing; fails unless it is a writable dir.
install_check_dir() {
  mkdir -p "$install_dir" 2>/dev/null || true
  if [ ! -d "$install_dir" ] || [ ! -w "$install_dir" ]; then
    install_error "$install_dir is not writable"
    exit 1
  fi
}

# Runs the image's install entry, as the current user, on the staging dir.
install_fetch() {
  if ! docker run --rm --user "$(id -u):$(id -g)" --entrypoint vault-install \
    -v "$staging:/install" "$image"; then
    install_error "failed to install from $image"
    exit 1
  fi
}

# Moves the CLI into the install dir and the completions into their dir.
install_move() {
  mv -f "$staging/vault" "$install_dir/vault"
  mkdir -p "$completion_dir"
  mv -f "$staging/completion/vault.bash" "$completion_dir/vault.bash"
  mv -f "$staging/completion/_vault" "$completion_dir/_vault"
}

# Prints the result and the completion setup lines.
install_report() {
  printf 'installed vault %s to %s/vault\n' "$version" "$install_dir"
  printf '%s\n' "bash completion: source ~/.local/share/vault/completion/vault.bash"
  printf '%s\n' "zsh completion: add ~/.local/share/vault/completion to fpath"
}

# Warns when the install dir is not an entry of PATH (ignoring a trailing /).
install_check_path() {
  local dir entry rest
  dir="$(install_strip_slash "$install_dir")"
  rest="${PATH:-}:"
  while [ -n "$rest" ]; do
    entry="${rest%%:*}"
    rest="${rest#*:}"
    if [ "$(install_strip_slash "$entry")" = "$dir" ]; then
      return 0
    fi
  done
  # shellcheck disable=SC2016 # $PATH is printed literally
  install_warning "$install_dir is not in PATH; add: export PATH=\"$install_dir:"'$PATH"'
}

# Prints <path> without its trailing "/" (a lone "/" is kept).
install_strip_slash() {
  local path="$1"
  if [ "${#path}" -gt 1 ]; then
    path="${path%/}"
  fi
  printf '%s\n' "$path"
}

# Removes the staging dir.
install_cleanup() {
  if [ -n "$staging" ]; then
    rm -rf "$staging"
  fi
}

install_error() {
  printf 'vault: error: %s\n' "$*" >&2
}

install_warning() {
  printf 'vault: warning: %s\n' "$*" >&2
}

install_hint() {
  printf 'vault: hint: %s\n' "$*" >&2
}

main "$@"
