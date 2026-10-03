# Cli Plan: CLI scaffolding and tooling: skeleton, bundle, lint/test, bash 3.2

Main plan: [plan.md](plan.md)

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

## Steps

- [01 — Add the output and usage libraries](cli/01-add-libraries.md)
- [02 — Add the cli/bin/vault skeleton](cli/02-add-vault-skeleton.md)
- [03 — Add bats tests for the skeleton](cli/03-add-skeleton-tests.md)

## CI Checks
- `cli/`, `test/cli/`: `make lint`, `make test`, `make bundle-cli` (CI job: `build-and-test`)

## Notes
- bash 3.2 only: no associative arrays, `mapfile`, `${var,,}`, `declare -n`, `[[ -v ]]`.
  Do not use `readlink -f` (missing on macOS) to locate `cli/lib/`.
- Messages must match [cli-commands.md → Messages](../../specs/cli-commands.md#messages)
  and [Diagnostics and exit codes](../../specs/cli-commands.md#diagnostics-and-exit-codes) exactly; tests assert the wording.
- The `build/vault` tests depend on `automation`'s `scripts/test.sh` building the bundle first.
