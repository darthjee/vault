# Product-owner Plan: Repo scaffolding: VERSION, version scripts, Makefile, lint/test via Docker

Main plan: [plan.md](plan.md)

## Shared contracts

The spec must reflect every target, variable and behaviour listed in [plan.md](plan.md#shared-contracts).

## Implementation Steps

### Step 1 — Update tooling.md
- Versioning: `check_tag_version.sh` takes the tag as an argument. Both scripts are exposed as `make bump-version VERSION=X.Y.Z` and `make check-version-tag TAG=X.Y.Z`.
- Makefile table:
  - Add the `bump-version` and `check-version-tag` rows. Each fails fast without its variable.
  - Note that `build-image`, `test-image`, `update-description` and `release` start as no-op stubs naming #5, #7 and #9. `release` still fails fast without `TAG`.
- Lint and test:
  - Missing folders are skipped. Lint files are collected on the host because the shellcheck image has no shell.
  - `make test` prints "no tests found" and exits 0 when `test/lib/` is missing or empty.
  - The version scripts are covered by lint only.
  - Record the mount points: `/mnt:ro` for shellcheck and `/code:ro` for bats.
- Helper libraries: replace "To be verified" with the result. They ship in `bats/bats:1.14.0` under `/usr/lib/bats` (`BATS_LIB_PATH`), are loaded with `bats_load_library`, and nothing is vendored.

### Step 2 — Update overview.md and ci.md
- `overview.md`: add the `bump-version` and `check-version-tag` rows to the Makefile targets table, plus a one-line note about the stubs.
- `ci.md`: point the release pipeline's `check-version-tag` job at `make check-version-tag TAG=$CIRCLE_TAG`.

## Files to Change
- `docs/agents/specs/docker-image/tooling.md`
- `docs/agents/specs/docker-image/overview.md`
- `docs/agents/specs/docker-image/ci.md`
