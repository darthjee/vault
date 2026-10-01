#!/usr/bin/env bats
# The docker stub is invoked indirectly by the code under test.
# shellcheck disable=SC1091,SC2329

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  source "$BATS_TEST_DIRNAME/../../source/lib/images.sh"

  CALLS_FILE="$BATS_TEST_TMPDIR/calls"
  : > "$CALLS_FILE"
  IMAGES_DIR="$BATS_TEST_TMPDIR/images"

  docker() { echo "docker $*" >> "$CALLS_FILE"; }
}

@test "images_load_dir skips a missing directory" {
  run images_load_dir "$IMAGES_DIR"
  assert_success
  assert_output ""

  run cat "$CALLS_FILE"
  assert_output ""
}

@test "images_load_dir skips an empty directory" {
  mkdir -p "$IMAGES_DIR"

  run images_load_dir "$IMAGES_DIR"
  assert_success
  assert_output ""

  run cat "$CALLS_FILE"
  assert_output ""
}

@test "images_load_dir ignores files that are not tarballs" {
  mkdir -p "$IMAGES_DIR"
  touch "$IMAGES_DIR/readme.txt" "$IMAGES_DIR/app.tar.gz"

  run images_load_dir "$IMAGES_DIR"
  assert_success

  run cat "$CALLS_FILE"
  assert_output ""
}

@test "images_load_dir loads every tarball in order" {
  mkdir -p "$IMAGES_DIR"
  touch "$IMAGES_DIR/b.tar" "$IMAGES_DIR/a.tar"

  run images_load_dir "$IMAGES_DIR"
  assert_success

  run cat "$CALLS_FILE"
  assert_line --index 0 "docker load -i $IMAGES_DIR/a.tar"
  assert_line --index 1 "docker load -i $IMAGES_DIR/b.tar"
  assert_equal "${#lines[@]}" 2
}

@test "images_load_dir fails naming the tarball that did not load" {
  mkdir -p "$IMAGES_DIR"
  touch "$IMAGES_DIR/a.tar" "$IMAGES_DIR/b.tar" "$IMAGES_DIR/c.tar"
  docker() {
    echo "docker $*" >> "$CALLS_FILE"
    [[ "$*" != *b.tar ]]
  }

  run images_load_dir "$IMAGES_DIR"
  assert_failure 1
  assert_output "failed to load image tarball: $IMAGES_DIR/b.tar"

  run cat "$CALLS_FILE"
  assert_equal "${#lines[@]}" 2
  refute_output --partial "c.tar"
}
