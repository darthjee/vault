# Plan: CLI scaffolding and tooling: skeleton, bundle, lint/test, bash 3.2

Issue: [22-cli-scaffolding-and-tooling-skeleton-bundle-lint-test-bash-3-2.md](../../issues/22-cli-scaffolding-and-tooling-skeleton-bundle-lint-test-bash-3-2.md)

## Overview
Add the first `vault` CLI code (a `cli/bin/vault` skeleton with `version`, `help` and the
unknown-command error, plus two libraries) and the tooling every later CLI sub-issue relies on:
a bundle step producing `build/vault`, lint and bats coverage of the CLI paths, a bash 3.2 test
run, `VAULT_VERSION` stamping, and a `make bundle-cli` CI step. The spec under
`docs/agents/specs/` is updated in the same PR with the decisions taken in the issue.

## Agents involved

- [cli](cli.md)
- [automation](automation.md)
- [product-owner](product-owner.md)

## Shared contracts

- **Version line:** exactly one line in `cli/bin/vault` matching
  `^VAULT_VERSION="[0-9]+\.[0-9]+\.[0-9]+"$` (column 0, double quotes), set to the current
  `VERSION`.
- **Lib block markers:** two lines, exactly `# BEGIN LIBS` and `# END LIBS`, at column 0, once
  each, in that order. Between them, only the `source` lines for the libraries.
- **Library list and bundle order:** `cli/lib/output.sh`, then `cli/lib/usage.sh`. Both only
  define functions, prefixed by module (`output_*`, `usage_*`).
- **Bundle path:** `build/vault`, mode `0755`, built by `scripts/bundle_cli.sh` (`make bundle-cli`).
- **Tests against the bundle:** `scripts/test.sh` runs `scripts/bundle_cli.sh` before any bats
  run, so `build/vault` exists when `test/cli/` runs. Tests reach it at
  `$BATS_TEST_DIRNAME/../../build/vault` and the source at `$BATS_TEST_DIRNAME/../../cli/bin/vault`.
- **bats helpers:** both `BATS_IMAGE` and `BASH32_TEST_IMAGE` provide `bats-support` and
  `bats-assert` through `bats_load_library`, as `test/lib/*.bats` already uses.
- **bash 3.2 suites:** `BASH32_TEST_IMAGE` runs `test/cli/` and `test/install/` (whichever have
  `.bats` files); `test/lib/` runs on `BATS_IMAGE` only.
