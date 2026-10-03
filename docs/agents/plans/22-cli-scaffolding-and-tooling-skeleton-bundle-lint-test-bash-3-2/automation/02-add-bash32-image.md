# Add the bash 3.2 test image
`test/bash32/Dockerfile`: `FROM bash:3.2`, install bats-core, bats-support and bats-assert at
pinned tags (bats-core matching `BATS_IMAGE`'s version, `v1.14.0`), laid out so
`bats_load_library bats-support` / `bats-assert` work (e.g. under `/usr/lib/bats`, or with
`BATS_LIB_PATH` set). Entrypoint `bats`, like `bats/bats`, so `scripts/test.sh` calls both images
the same way.

Add `BASH32_TEST_IMAGE ?= vault-bash32-test:local` to the Makefile and export it.

## Files to Change
- `test/bash32/Dockerfile` — new; bash 3.2 bats image.
- `Makefile` — `BASH32_TEST_IMAGE` variable and export.
