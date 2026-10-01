# Issue: Repo scaffolding: VERSION, version scripts, Makefile, lint/test via Docker

## Description
Part of epic #2. Scaffold the repo tooling for the Vault image: versioning, the `Makefile`, and lint/unit-test running through pinned Docker tool images. Implements [tooling.md](../specs/docker-image/tooling.md) → Versioning, Scripts vs Makefile, Makefile, and Lint and unit test tool images.

Owner: `automation`. Depends on #3 (docker-image spec, merged).

## Problem
The repo has no versioning, no build entry point and no way to lint or test shell code. Later sub-issues (#5–#9) need these targets and scripts as a shared contract, and nothing should need installing on the host apart from Docker and make.

## Expected Behavior
### Versioning
- `VERSION` contains `0.1.0`; the README has a matching `**Current Version:** 0.1.0` line.
- `scripts/bump_version.sh X.Y.Z` updates `VERSION` and the README line together.
- `scripts/check_tag_version.sh X.Y.Z` takes the tag as an argument and fails unless it equals both `VERSION` and the README line.
- Both scripts are exposed through make, since Make is the only entry point:
  - `make bump-version VERSION=X.Y.Z`
  - `make check-version-tag TAG=X.Y.Z` (used by the CI `check-version-tag` job in #9)
  - Each fails fast when its variable is missing.

### Lint and unit tests
- `make lint` runs shellcheck in `SHELLCHECK_IMAGE` (default `koalaman/shellcheck:v0.11.0`) over `source/`, `scripts/` (incl. `scripts/ci/`) and `test/`, repo mounted read-only. Non-zero on any finding.
- `make test` runs bats in `BATS_IMAGE` (default `bats/bats:1.14.0`) over `test/lib/`, repo mounted read-only. Non-zero on any failing test.
- Missing folders are skipped: `make lint` checks only the folders that exist. `make test` prints a "no tests found" notice and exits 0 when `test/lib/` is missing or has no `.bats` files.
- The version scripts are covered by lint only, with no bats tests. `make test` stays scoped to `test/lib/`.

### Placeholder targets
- `build-image`, `test-image`, `update-description` and `release TAG=x` are no-op stubs. They print a notice naming the sub-issue that implements them (#5, #7, #9) and exit 0, so the CI wiring (#8) can call them right away.
- `release` still fails fast with a non-zero exit when `TAG` is missing, before anything else.

### Out of scope
- The Dockerfile, the entrypoint and CircleCI.

### Done when
- `make lint` passes on `scripts/`.
- `make test` runs cleanly with no tests yet.
- `make release` without `TAG` errors out, and so do `make bump-version` without `VERSION` and `make check-version-tag` without `TAG`.
- `make check-version-tag TAG=0.1.0` passes and `TAG=0.1.1` fails.

## Solution
- Recipes longer than one line move to `scripts/*.sh`.
- Scripts follow [contributing.md → Bash style](../../contributing.md#bash-style): `#!/usr/bin/env bash`, `set -euo pipefail`, shellcheck-clean.
- Check whether `bats-support`, `bats-assert` and `bats-file` ship with the bats image, and record the load path in `tooling.md`. If they don't, vendor them under `test/helpers/`.
- Update the spec in the same PR:
  - add the `bump-version` and `check-version-tag` targets to the Makefile tables in `tooling.md` and `overview.md`;
  - point the `check-version-tag` job in `ci.md` at the make target;
  - note the skip-missing-folders and no-op stub behaviour.

## Benefits
- Gives #5–#9 a stable, shared set of make targets and variables.
- Contributors and CI only need Docker and make.
