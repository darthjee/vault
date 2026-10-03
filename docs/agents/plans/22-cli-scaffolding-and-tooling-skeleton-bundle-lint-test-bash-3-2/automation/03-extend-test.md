# Extend make test
`scripts/test.sh`:

1. run `scripts/bundle_cli.sh` first (the CLI tests also check `build/vault`), when `cli/` exists;
2. run bats on `BATS_IMAGE` over `test/lib/`, `test/cli/`, `test/install/` — whichever contain
   `.bats` files;
3. build `BASH32_TEST_IMAGE` from `test/bash32/` (`docker build -t`), then run it over
   `test/cli/` and `test/install/` — whichever contain `.bats` files;
4. exit non-zero if any run fails. Keep the "no tests found" message when nothing exists.

## Files to Change
- `scripts/test.sh` — bundle, both bats runs, bash 3.2 image build.
