#!/usr/bin/env bats
# End-to-end resolution tests: source cli/bin/vault and build/vault, call
# vault_resolve with the stub docker, assert the exact `docker run` list.
# shellcheck disable=SC2154 # output/stderr/status are set by bats' run

bats_require_minimum_version 1.5.0

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  load helpers/docker_stub

  ROOT="$BATS_TEST_DIRNAME/../.."
  SOURCE_VAULT="$ROOT/cli/bin/vault"
  BUNDLE_VAULT="$ROOT/build/vault"
  VERSION="$(cat "$ROOT/VERSION")"
  docker_stub_setup
  unset DOCKER_HOST

  WORK="$BATS_TEST_TMPDIR/work"
  mkdir -p "$WORK/proj" "$WORK/other dir"
  WORK="$(cd "$WORK" && pwd)"
  PROJ="$WORK/proj"
  cd "$PROJ" || return

  FALLBACK='vault: warning: sysbox-runc not found; running with --privileged (see Security in the README)'
}

# Sources <vault> in a fresh bash (set -euo pipefail, as when executed),
# runs vault_resolve with the arguments and prints CONTAINER_ARGS, one per
# line (or NAMING_NAME when RESOLVE_PRINT=name).
# Usage: resolve <vault> <command> <args...>
resolve() {
  local vault="$1"
  shift
  if [ ! -x "$vault" ]; then
    echo "executable not found: $vault (run make bundle-cli)" >&2
    return 99
  fi
  bash -c '
    vault="$1"
    shift
    # shellcheck disable=SC1090
    source "$vault"
    vault_resolve "$@" || exit
    if [ "${RESOLVE_PRINT:-}" = name ]; then
      printf "%s\n" "$NAMING_NAME"
      exit 0
    fi
    for arg in ${CONTAINER_ARGS[@]+"${CONTAINER_ARGS[@]}"}; do
      printf "%s\n" "$arg"
    done
  ' resolve "$vault" "$@"
}

# Joins the arguments with newlines (the expected `resolve` output).
lines() {
  printf '%s\n' "$@"
}

@test "sourcing bin/vault does not run vault_main" {
  local vault
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    # shellcheck disable=SC2016 # expanded by the inner bash
    run --separate-stderr bash -c 'source "$1"; echo sourced' resolve "$vault"

    assert_success
    assert_output sourced
    assert_equal "$stderr" ""
  done
}

@test "up with defaults: privileged fallback, /vault mount, default port and image" {
  local vault
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    run --separate-stderr resolve "$vault" up

    assert_success
    assert_equal "$stderr" "$FALLBACK"
    assert_output "$(lines run --privileged --stop-timeout 60 \
      -v "$PROJ:/vault" -v vault-proj-data:/var/lib/docker \
      -p 3000:80 --name vault-proj -d "darthjee/vault:$VERSION")"
  done
}

@test "up with Sysbox: --runtime=sysbox-runc, no warning, one docker info" {
  local vault
  docker_stub_info "$DOCKER_STUB_INFO_SYSBOX" "$DOCKER_STUB_SECURITY_DEFAULT"
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    : >"$DOCKER_STUB_LOG"
    run --separate-stderr resolve "$vault" up -f

    assert_success
    assert_equal "$stderr" ""
    assert_output "$(lines run --runtime=sysbox-runc --stop-timeout 60 \
      -v "$PROJ:/vault" -v vault-proj-data:/var/lib/docker \
      -p 3000:80 --name vault-proj "darthjee/vault:$VERSION")"
    assert_equal "$(docker_stub_count info)" 1
  done
}

@test "up with every flag, [dir] given, .vault.env first" {
  local vault
  touch "$WORK/other dir/.vault.env"
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    run --separate-stderr resolve "$vault" up --runtime privileged \
      --stop-timeout 5 -v "/a b:/c" -v /d:/e -p 8080:80 -p 8443:443 \
      --env-file x.env -e "A=1 2" -e B --name my-app "$WORK/other dir/" --image img:2

    assert_success
    assert_equal "$stderr" ""
    assert_output "$(lines run --privileged --stop-timeout 5 \
      -v "$WORK/other dir:/vault" -v vault-my-app-data:/var/lib/docker \
      -v "/a b:/c" -v /d:/e -p 8080:80 -p 8443:443 \
      --env-file "$WORK/other dir/.vault.env" --env-file x.env \
      -e "A=1 2" -e B --name vault-my-app -d img:2)"
  done
}

@test "a relative [dir] is mounted as an absolute path" {
  local vault
  cd "$WORK" || return
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    run --separate-stderr resolve "$vault" up --runtime privileged proj

    assert_success
    assert_line --index 5 "$PROJ:/vault"
  done
}

@test "up with --image and no [dir]: image-derived name, no /vault mount" {
  local vault
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    run --separate-stderr resolve "$vault" up --runtime privileged \
      --image registry.example.com:5000/team/My-App:1.0

    assert_success
    assert_output "$(lines run --privileged --stop-timeout 60 \
      -v vault-my-app-data:/var/lib/docker -p 3000:80 --name vault-my-app -d \
      registry.example.com:5000/team/My-App:1.0)"
  done
}

@test "edge case 14: any --image version is used as given, no version check" {
  local vault
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    run --separate-stderr resolve "$vault" up --runtime privileged --image darthjee/vault:9.9.9 .

    assert_success
    assert_equal "$stderr" ""
    assert_line --index 7 vault-proj-data:/var/lib/docker
    assert_line darthjee/vault:9.9.9
  done
}

@test "run: --rm, no --name, no -d, the compose args after the image" {
  local vault
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    run --separate-stderr resolve "$vault" run --runtime privileged config --services

    assert_success
    assert_output "$(lines run --privileged --stop-timeout 60 \
      -v "$PROJ:/vault" -v vault-proj-data:/var/lib/docker \
      -p 3000:80 --rm "darthjee/vault:$VERSION" config --services)"
  done
}

@test "run: an existing directory is [dir]" {
  local vault
  cd "$WORK" || return
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    run --separate-stderr resolve "$vault" run --runtime privileged proj ps

    assert_success
    assert_line --index 5 "$PROJ:/vault"
    assert_line --index 12 ps
  done
}

@test ".vaultrc feeds the values; image= keeps the dir name and the /vault mount" {
  local vault
  cat >"$PROJ/.vaultrc" <<'EOF'
# project defaults
image=team/other:3
runtime=privileged
stop-timeout=15
port=9000:80
volume=./data:/data
env=RAILS_ENV=production
env-file=.env.prod
EOF
  touch "$PROJ/.vault.env"
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    run --separate-stderr resolve "$vault" up

    assert_success
    assert_equal "$stderr" ""
    assert_output "$(lines run --privileged --stop-timeout 15 \
      -v "$PROJ:/vault" -v vault-proj-data:/var/lib/docker \
      -v "$PROJ/data:/data" -p 9000:80 \
      --env-file "$PROJ/.vault.env" --env-file "$PROJ/.env.prod" \
      -e RAILS_ENV=production --name vault-proj -d team/other:3)"
  done
}

@test ".vaultrc is read from [dir], and flags replace per key" {
  local vault
  cat >"$WORK/other dir/.vaultrc" <<'EOF'
name=from-rc
port=9000:80
env=A=1
EOF
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    run --separate-stderr resolve "$vault" up --runtime privileged -p 1:80 "$WORK/other dir"

    assert_success
    assert_output "$(lines run --privileged --stop-timeout 60 \
      -v "$WORK/other dir:/vault" -v vault-from-rc-data:/var/lib/docker \
      -p 1:80 -e A=1 --name vault-from-rc -d "darthjee/vault:$VERSION")"
  done
}

@test "a .vaultrc guardrail hit fails with exit 2" {
  local vault
  printf 'volume=/var/run/docker.sock:/var/run/docker.sock\n' >"$PROJ/.vaultrc"
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    run --separate-stderr resolve "$vault" up --runtime privileged

    assert_failure 2
    assert_output ""
    assert_equal "$stderr" "vault: error: refusing to mount the Docker socket (/var/run/docker.sock)"
  done
}

@test "a .vaultrc port 2375 fails with exit 2" {
  local vault
  printf 'port=2375\n' >"$PROJ/.vaultrc"
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    run --separate-stderr resolve "$vault" run --runtime privileged

    assert_failure 2
    assert_equal "$stderr" "vault: error: refusing to publish the Docker daemon port 2375"
  done
}

@test "the DOCKER_HOST socket path is refused" {
  local vault
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    DOCKER_HOST=unix:///tmp/d.sock run --separate-stderr resolve "$vault" up --runtime privileged -v /tmp/d.sock:/s

    assert_failure 2
    assert_equal "$stderr" "vault: error: refusing to mount the Docker socket (/tmp/d.sock)"
  done
}

@test "a malformed .vaultrc fails with exit 1 before docker is used (edge case 11)" {
  local vault
  printf 'name=a\nbroken\n' >"$PROJ/.vaultrc"
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    run --separate-stderr resolve "$vault" up

    assert_failure 1
    assert_equal "$stderr" "vault: error: .vaultrc:2: expected key=value"
  done
  assert_docker_not_called info
}

@test "a .vaultrc unknown key warns and continues (edge case 11)" {
  local vault
  printf 'colour=red\n' >"$PROJ/.vaultrc"
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    run --separate-stderr resolve "$vault" up --runtime privileged

    assert_success
    assert_equal "$stderr" "vault: warning: .vaultrc:1: unknown key 'colour'"
  done
}

@test "docker missing fails with exit 1 (edge case 1)" {
  local vault
  docker_stub_hide
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    run --separate-stderr resolve "$vault" up

    assert_failure 1
    assert_equal "$stderr" "vault: error: docker not found in PATH"
  done
}

@test "docker missing also fails for commands without docker info" {
  local vault
  docker_stub_hide
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    run --separate-stderr resolve "$vault" status

    assert_failure 1
    assert_equal "$stderr" "vault: error: docker not found in PATH"
  done
}

@test "an unreachable daemon fails with exit 1 (edge case 1)" {
  local vault
  docker_stub_info_fails
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    run --separate-stderr resolve "$vault" run

    assert_failure 1
    assert_output ""
    assert_equal "$stderr" "Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
vault: error: cannot reach the Docker daemon
vault: hint: is Docker running, and can this user access it?"
  done
}

@test "forced sysbox without Sysbox fails with exit 1 (edge case 3)" {
  local vault
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    run --separate-stderr resolve "$vault" up --runtime sysbox

    assert_failure 1
    assert_output ""
    assert_equal "$stderr" "vault: error: --runtime=sysbox requested but sysbox-runc is not available"
  done
}

@test "rootless is refused, even with --runtime privileged" {
  local vault
  docker_stub_info "$DOCKER_STUB_INFO_SYSBOX" "$DOCKER_STUB_SECURITY_ROOTLESS"
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    run --separate-stderr resolve "$vault" up --runtime privileged

    assert_failure 1
    assert_equal "$stderr" 'vault: error: rootless Docker is not supported
vault: hint: see Security in the README'
  done
}

@test "the pre-checks come before the guardrails" {
  local vault
  docker_stub_info_fails
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    run --separate-stderr resolve "$vault" up -p 2375

    assert_failure 1
  done
}

@test "down/logs/status/compose resolve the name without docker info" {
  local vault command
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    for command in down logs status compose; do
      RESOLVE_PRINT=name run --separate-stderr resolve "$vault" "$command"

      assert_success
      assert_output proj
    done
  done
  assert_docker_not_called info
}

@test "an empty derived name fails with exit 2 (edge case 9)" {
  local vault
  mkdir -p "$WORK/!!!"
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    run --separate-stderr resolve "$vault" status "$WORK/!!!"

    assert_failure 2
    assert_equal "$stderr" "vault: error: cannot derive an instance name from '!!!'
vault: hint: pass --name <name>"
  done
}

@test "a derived name is sanitized (edge case 9)" {
  local vault
  mkdir -p "$WORK/My App!"
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    RESOLVE_PRINT=name run --separate-stderr resolve "$vault" down "$WORK/My App!"

    assert_success
    assert_output myapp
  done
}

@test "usage errors exit 2 before any docker call" {
  local vault
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    run --separate-stderr resolve "$vault" up --nope

    assert_failure 2
    assert_equal "$stderr" "vault: error: unknown option '--nope'
vault: hint: run \"vault help\""
  done
  assert_equal "$(docker_stub_calls)" ""
}

@test "-h stops the resolution with status 0" {
  local vault
  for vault in "$SOURCE_VAULT" "$BUNDLE_VAULT"; do
    run --separate-stderr resolve "$vault" up -h

    assert_success
    assert_output ""
  done
  assert_equal "$(docker_stub_calls)" ""
}
