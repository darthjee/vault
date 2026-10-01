# Makefile
- Create the `Makefile`:
  - Declare `.PHONY` for every target.
  - Define the `SHELLCHECK_IMAGE` and `BATS_IMAGE` defaults.
  - `lint` calls `scripts/lint.sh` and `test` calls `scripts/test.sh`.
  - `bump-version` checks that `VERSION` is set, then calls `scripts/bump_version.sh`.
  - `check-version-tag` checks that `TAG` is set, then calls `scripts/check_tag_version.sh`.
  - `release` checks that `TAG` is set first, then runs a stub naming #9.
  - `build-image` (#5), `test-image` (#7) and `update-description` (#9) are stubs that print a notice naming their sub-issue and exit 0.
- Keep each recipe to one line. Anything longer goes in `scripts/`.

## Files to Change
- `Makefile`: new file.
