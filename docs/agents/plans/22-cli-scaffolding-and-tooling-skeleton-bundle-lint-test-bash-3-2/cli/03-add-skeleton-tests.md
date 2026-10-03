# Add bats tests for the skeleton
Add bats tests that run each case against both `cli/bin/vault` and `build/vault` (e.g. a
helper that sets the executable under test, with one test per case per target, or a loop over
both targets inside each test):

- `version` prints `vault <VERSION>` and exits 0 — read the expected value from `VERSION`;
- `help`, `-h`, `--help` print the usage to stdout and exit 0;
- no command prints the usage to stderr and exits 2;
- an unknown command prints the error and the hint to stderr and exits 2;
- `build/vault` sources nothing at run time (e.g. it runs from a copy in `$BATS_TEST_TMPDIR`,
  away from `cli/lib/`).

Tests use `bats_load_library bats-support` / `bats-assert` and must pass on both bats images.

## Files to Change
- `test/cli/vault.bats` — new; skeleton tests.
