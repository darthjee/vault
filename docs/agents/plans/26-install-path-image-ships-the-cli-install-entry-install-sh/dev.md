# Dev Plan: Install path: image ships the CLI, install entry, install.sh

Main plan: [plan.md](plan.md)

## Shared contracts

- **Produces** the in-image paths and the `vault-install` contract from [plan.md](plan.md#shared-contracts).
- **Relies on** `automation` making `build-image` / `test-image` / `release` run `bundle-cli`
  first, so `build/vault` exists in the build context.

## Steps

- [01 — Install library and its bats tests](dev/01-install-library.md)
- [02 — Install entry `vault-install`](dev/02-install-entry.md)
- [03 — Ship the CLI in the Dockerfile](dev/03-dockerfile.md)

## CI Checks
- `source/`, `test/lib/`: `make lint`, `make test` (CI job: `build-and-test`)
- `Dockerfile`: `make test-image` (CI job: `build-and-test`)

## Notes
- The image check that the CLI is present goes into `scripts/test_image.sh`, which `automation`
  owns (see [automation.md](automation.md)). `dev` must not edit `scripts/`.
- `test/lib/` runs on `BATS_IMAGE` only, not on bash 3.2. The image's bash is current, so that is fine.
