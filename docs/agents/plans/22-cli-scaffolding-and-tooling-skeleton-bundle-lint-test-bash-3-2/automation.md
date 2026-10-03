# Automation Plan: CLI scaffolding and tooling: skeleton, bundle, lint/test, bash 3.2

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

- [01 — Add the bundle script and make target](automation/01-add-bundle.md)
- [02 — Add the bash 3.2 test image](automation/02-add-bash32-image.md)
- [03 — Extend make test](automation/03-extend-test.md)
- [04 — Extend make lint](automation/04-extend-lint.md)
- [05 — Stamp and check VAULT_VERSION](automation/05-version-stamping.md)
- [06 — Add bundle-cli to CI](automation/06-ci-bundle-step.md)

## CI Checks
- `scripts/`, `Makefile`, `test/bash32/`: `make lint`, `make test`, `make bundle-cli` (CI job: `build-and-test`)
- `.circleci/`: `circleci config validate` (if the CLI is installed)
- Check the version scripts by hand: `make check-version-tag TAG=$(cat VERSION)` passes; a
  wrong tag and a missing/duplicated `VAULT_VERSION` line fail.

## Notes
- Do **not** make `build-image`, `test-image` or `release` depend on `bundle-cli`; #26 does that.
- `.gitignore` is a root-level file owned by the architect; the spec lets `automation` add the
  `build/` entry in this PR (report it in the PR summary).
- Keep each change in its own commit (bundle, bash 3.2 image, test, lint, version, CI).
