#!/usr/bin/env bats
# Tests for scripts/check_guides_links.sh (make test-docs), against fixture
# guide trees written in $BATS_TEST_TMPDIR (the repo is mounted read-only).
# shellcheck disable=SC2154 # output/stderr/status are set by bats' run

bats_require_minimum_version 1.5.0

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert

  SCRIPT="$BATS_TEST_DIRNAME/../../scripts/check_guides_links.sh"
  GUIDES="$BATS_TEST_TMPDIR/guides"
  mkdir -p "$GUIDES/vault"
}

run_check() {
  run --separate-stderr bash "$SCRIPT" "$@"
}

# Writes a passing two-page tree.
write_valid_tree() {
  cat > "$GUIDES/vault.md" <<'EOF'
# Vault guides

**Vault version:** 0.0.1

Read the [CLI guide](vault/cli.md) and its [.vaultrc section](vault/cli.md#vaultrc-and-vaultenv).
Jump to [Getting started](#getting-started) or the [README](https://github.com/darthjee/vault).
A [titled link](vault/cli.md "CLI") also works.

## Getting started

Nothing here.
EOF
  cat > "$GUIDES/vault/cli.md" <<'EOF'
# CLI

Back to the [index](../vault.md), its [start](../vault.md#getting-started) and
[this page](./cli.md#cli).

## `.vaultrc` and `.vault.env`

See [CLI](#cli).
EOF
}

@test "a valid tree passes" {
  write_valid_tree
  run_check "$GUIDES"
  assert_success
  assert_equal "$output" "test-docs: OK (2 file(s))"
  assert_equal "$stderr" ""
}

@test "a missing root passes" {
  run_check "$BATS_TEST_TMPDIR/nope"
  assert_success
  assert_equal "$output" "test-docs: OK (0 file(s))"
}

@test "an empty root passes" {
  run_check "$GUIDES"
  assert_success
  assert_equal "$output" "test-docs: OK (0 file(s))"
}

@test "headings with punctuation get GitHub slugs" {
  cat > "$GUIDES/vault.md" <<'EOF'
## `.vaultrc` and `.vault.env`
## What's new? (v1.0)
## snake_case_name
See [a](#vaultrc-and-vaultenv), [b](#whats-new-v10) and [c](#snake_case_name).
EOF
  run_check "$GUIDES"
  assert_success
}

@test "duplicate headings get -1, -2 suffixes" {
  cat > "$GUIDES/vault.md" <<'EOF'
## Setup
## Setup
See [first](#setup) and [second](#setup-1) and [third](#setup-2).
EOF
  run_check "$GUIDES"
  assert_failure 1
  assert_equal "$stderr" "vault.md: missing anchor: #setup-2"
}

@test "a relative link leaving the tree fails" {
  echo 'See [README](../../README.md).' > "$GUIDES/vault/cli.md"
  run_check "$GUIDES"
  assert_failure 1
  assert_equal "$stderr" "vault/cli.md: relative link leaves the guides tree: ../../README.md"
}

@test "a relative link to a missing file fails" {
  echo 'See [x](vault/missing.md).' > "$GUIDES/vault.md"
  run_check "$GUIDES"
  assert_failure 1
  assert_equal "$stderr" "vault.md: missing file: vault/missing.md"
}

@test "a missing anchor in the same page fails" {
  printf '# Title\n\nSee [x](#nope).\n' > "$GUIDES/vault.md"
  run_check "$GUIDES"
  assert_failure 1
  assert_equal "$stderr" "vault.md: missing anchor: #nope"
}

@test "a missing anchor in another page fails" {
  write_valid_tree
  echo 'See [x](cli.md#nope).' >> "$GUIDES/vault/cli.md"
  run_check "$GUIDES"
  assert_failure 1
  assert_equal "$stderr" "vault/cli.md: missing anchor: cli.md#nope"
}

@test "an http:// link fails" {
  echo 'See [x](http://example.com).' > "$GUIDES/vault.md"
  run_check "$GUIDES"
  assert_failure 1
  assert_equal "$stderr" "vault.md: link must be relative inside the guides or absolute https://: http://example.com"
}

@test "an absolute path fails" {
  echo 'See [x](/etc/hosts).' > "$GUIDES/vault.md"
  run_check "$GUIDES"
  assert_failure 1
  assert_equal "$stderr" "vault.md: link must be relative inside the guides or absolute https://: /etc/hosts"
}

@test "a mailto: link fails" {
  echo 'Mail [me](mailto:someone@example.com).' > "$GUIDES/vault.md"
  run_check "$GUIDES"
  assert_failure 1
  assert_equal "$stderr" "vault.md: link must be relative inside the guides or absolute https://: mailto:someone@example.com"
}

@test "a reference-style definition fails" {
  printf 'See [x][ref].\n\n[ref]: https://example.com\n' > "$GUIDES/vault.md"
  run_check "$GUIDES"
  assert_failure 1
  assert_equal "$stderr" "vault.md: reference-style links are not allowed: https://example.com"
}

@test "an image link fails" {
  echo '![logo](logo.png)' > "$GUIDES/vault.md"
  run_check "$GUIDES"
  assert_failure 1
  assert_equal "$stderr" "vault.md: image links are not allowed (guides ship no assets): logo.png"
}

@test "every problem is reported in one run" {
  write_valid_tree
  cat >> "$GUIDES/vault/cli.md" <<'EOF'
[a](http://example.com) [b](missing.md) [c](#nope)
EOF
  echo '![logo](https://example.com/logo.png)' >> "$GUIDES/vault.md"
  run_check "$GUIDES"
  assert_failure 1
  assert_equal "$stderr" "vault.md: image links are not allowed (guides ship no assets): https://example.com/logo.png
vault/cli.md: link must be relative inside the guides or absolute https://: http://example.com
vault/cli.md: missing file: missing.md
vault/cli.md: missing anchor: #nope"
}

@test "links inside fenced code blocks and inline code are ignored" {
  cat > "$GUIDES/vault.md" <<'EOF'
# Code

```markdown
[a](http://example.com) ![b](b.png)
[ref]: http://example.com
```

~~~
[c](/etc/hosts)
~~~

Inline `[d](missing.md)` and ``[e](#nope)`` are fine.
EOF
  run_check "$GUIDES"
  assert_success
  assert_equal "$output" "test-docs: OK (1 file(s))"
}
