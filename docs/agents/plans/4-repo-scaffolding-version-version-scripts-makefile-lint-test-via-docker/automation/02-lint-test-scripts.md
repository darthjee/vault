# Lint and test scripts
- `scripts/lint.sh`:
  - Collect `*.sh` and `*.bats` files from whichever of `source/`, `scripts/` and `test/` exist.
  - If no files are found, print a notice and exit 0.
  - Otherwise run `docker run --rm -v "$PWD:/mnt:ro" -w /mnt "$SHELLCHECK_IMAGE" <files>` and propagate its exit code.
- `scripts/test.sh`:
  - If `test/lib/` is missing or has no `.bats` files, print "no tests found in test/lib/" and exit 0.
  - Otherwise run `docker run --rm -v "$PWD:/code:ro" -w /code "$BATS_IMAGE" test/lib`.
- Both scripts default to the pinned image when the variable is unset.

## Files to Change
- `scripts/lint.sh`: new file.
- `scripts/test.sh`: new file.
