#!/usr/bin/env bats
# shellcheck disable=SC1091

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  source "$BATS_TEST_DIRNAME/../../source/lib/install.sh"

  SOURCE_DIR="$BATS_TEST_TMPDIR/source"
  BIN="$SOURCE_DIR/vault"
  COMPLETION_DIR="$SOURCE_DIR/completion"
  TARGET="$BATS_TEST_TMPDIR/install"

  mkdir -p "$COMPLETION_DIR"
  echo "new cli" > "$BIN"
  chmod 0600 "$BIN"
  echo "bash completion" > "$COMPLETION_DIR/vault.bash"
  echo "zsh completion" > "$COMPLETION_DIR/_vault"
  chmod 0600 "$COMPLETION_DIR/vault.bash" "$COMPLETION_DIR/_vault"
}

teardown() {
  [ -d "$TARGET" ] && chmod 0755 "$TARGET" || true
}

file_mode() {
  stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1"
}

@test "install_copy copies the CLI and the completions silently" {
  mkdir -p "$TARGET"

  run install_copy "$BIN" "$COMPLETION_DIR" "$TARGET"
  assert_success
  assert_output ""

  run cat "$TARGET/vault"
  assert_output "new cli"
  run cat "$TARGET/completion/vault.bash"
  assert_output "bash completion"
  run cat "$TARGET/completion/_vault"
  assert_output "zsh completion"
}

@test "install_copy sets the CLI mode to 0755 and the completions to 0644" {
  mkdir -p "$TARGET"

  run install_copy "$BIN" "$COMPLETION_DIR" "$TARGET"
  assert_success

  assert_equal "$(file_mode "$TARGET/vault")" 755
  assert_equal "$(file_mode "$TARGET/completion/vault.bash")" 644
  assert_equal "$(file_mode "$TARGET/completion/_vault")" 644
}

@test "install_copy overwrites an existing vault" {
  mkdir -p "$TARGET/completion"
  echo "old cli" > "$TARGET/vault"
  echo "old completion" > "$TARGET/completion/vault.bash"

  run install_copy "$BIN" "$COMPLETION_DIR" "$TARGET"
  assert_success
  assert_output ""

  run cat "$TARGET/vault"
  assert_output "new cli"
  run cat "$TARGET/completion/vault.bash"
  assert_output "bash completion"
}

@test "install_copy fails when the target is missing" {
  run install_copy "$BIN" "$COMPLETION_DIR" "$TARGET"
  assert_failure 1
  assert_output "vault-install: error: $TARGET is not writable"
}

@test "install_copy fails when the target is not a directory" {
  touch "$TARGET"

  run install_copy "$BIN" "$COMPLETION_DIR" "$TARGET"
  assert_failure 1
  assert_output "vault-install: error: $TARGET is not writable"
}

@test "install_copy fails when the target is read-only" {
  if [ "$(id -u)" -eq 0 ]; then
    skip "root ignores the mode bits"
  fi
  mkdir -p "$TARGET"
  chmod 0555 "$TARGET"

  run install_copy "$BIN" "$COMPLETION_DIR" "$TARGET"
  assert_failure 1
  assert_output "vault-install: error: $TARGET is not writable"
  [ ! -e "$TARGET/vault" ]
}

@test "install_copy fails when a completion is missing" {
  mkdir -p "$TARGET"
  rm "$COMPLETION_DIR/_vault"

  run install_copy "$BIN" "$COMPLETION_DIR" "$TARGET"
  assert_failure 1
}
