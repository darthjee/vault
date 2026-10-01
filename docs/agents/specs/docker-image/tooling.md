# Docker Image Spec: Tooling

Part of the [Docker image spec](overview.md). Implemented by #4 (versioning, Makefile, lint, unit tests) and #7 (smoke test).

## Baseline

See [contributing.md](../../contributing.md) for [Bash style](../../contributing.md#bash-style), [CI Checks](../../contributing.md#ci-checks) and [Dependency Injection](../../contributing.md#dependency-injection). Everything there still applies; this file adds the decisions below.

## Versioning

| Item | Decision |
|------|----------|
| `VERSION` | Single line, initial value `0.1.0`. |
| README | Carries a `**Current Version:** X.Y.Z` line, kept equal to `VERSION`. |
| `scripts/bump_version.sh X.Y.Z` | Updates `VERSION` and the README line together. Exposed as `make bump-version VERSION=X.Y.Z`. |
| `scripts/check_tag_version.sh X.Y.Z` | Takes the tag as an argument. Fails unless the tag equals both `VERSION` and the README line. Exposed as `make check-version-tag TAG=X.Y.Z`; used by the release pipeline ([ci.md](ci.md#release-pipeline)). |

## Scripts vs Makefile

- **Make is the only entry point.** Developers and CI call make targets, never scripts directly.
- A recipe longer than one line moves to `scripts/*.sh`.
- CI-only steps (`docker login`, buildx/QEMU setup, fetching external scripts such as `docker_hub.sh`) live in `scripts/ci/*.sh`.
- Everything under `scripts/` is shellchecked by `make lint`.
- CircleCI YAML only sets up executors, contexts and filters, and calls make targets ([ci.md](ci.md)).

## Makefile

Target names and behaviour are a shared contract ([overview.md](overview.md#makefile-targets)). Exact recipes are left to #4 (and #7, #9 for their targets).

| Target | Behaviour | Exit code |
|--------|-----------|-----------|
| `build-image` | `docker build` the image, passing `--build-arg DOCKER_VERSION` when set. | Non-zero if the build fails. |
| `lint` | Shellcheck over `source/`, `scripts/` and `test/` in `SHELLCHECK_IMAGE`. | Non-zero on any finding. |
| `test` | Bats over `test/lib/` in `BATS_IMAGE`. | Non-zero on any failing test; 0 with "no tests found" when there are none. |
| `bump-version VERSION=X.Y.Z` | Runs `scripts/bump_version.sh`. | Non-zero immediately when `VERSION` is missing. |
| `check-version-tag TAG=X.Y.Z` | Runs `scripts/check_tag_version.sh`. | Non-zero immediately when `TAG` is missing, or on a mismatch. |
| `test-image` | [Smoke test](#smoke-test). | Non-zero on any failed check; cleanup still runs. |
| `release TAG=x` | Multi-arch build and push ([ci.md](ci.md#release-pipeline)). | Non-zero immediately when `TAG` is missing, before any build. |
| `update-description` | Push `DOCKERHUB_DESCRIPTION.md` ([ci.md](ci.md#docker-hub-description)). | Non-zero if the push fails. |

| Variable | Default |
|----------|---------|
| `SHELLCHECK_IMAGE` | `?= koalaman/shellcheck:v0.11.0` |
| `BATS_IMAGE` | `?= bats/bats:1.14.0` |
| `IMAGE` | `?= darthjee/vault:dev`; tag applied by `build-image`. |
| `DOCKER_VERSION` | Unset; the Dockerfile `ARG` default (`29.8.2`) applies ([image.md](image.md#base-image)). |

**Stubs:** #4 adds `test-image`, `update-description` and `release` as no-op stubs. Each prints a notice naming the sub-issue that implements it (#7, #9 and #9) and exits 0. `build-image` is implemented in #5. `release` still fails fast without `TAG`, so the contract holds from the start.

## Lint and unit test tool images

- The tool images are used directly, with the repo mounted **read-only**. No custom test image is built.
- Both are pinned by tag; bump them by changing the Makefile defaults.
- **`make lint`:** shellcheck over `*.sh` and `*.bats` files in `source/`, `scripts/` (including `scripts/ci/`) and `test/`.
  - Missing folders are skipped.
  - Files are collected on the host, because the shellcheck image has no shell.
  - The repo is mounted read-only at `/mnt`.
- **`make test`:** bats over `test/lib/`, one file per library (`source/lib/compose.sh` → `test/lib/compose.bats`), with `docker` / `dockerd` stubbed (see [contributing.md → Refactoring Guidelines](../../contributing.md#refactoring-guidelines)).
  - The repo is mounted read-only at `/code`.
  - When `test/lib/` is missing or has no `.bats` files, it prints "no tests found" and exits 0.
- **Version scripts:** `scripts/bump_version.sh` and `scripts/check_tag_version.sh` are covered by `make lint` only; they have no bats tests.
- **Helper libraries:** `bats-support`, `bats-assert` and `bats-file` ship in `bats/bats:1.14.0` under `/usr/lib/bats` (`BATS_LIB_PATH`). Load them with `bats_load_library <name>`. Nothing is vendored.
- **Known gap:** unit tests run on the bats image's bash, not on the Alpine bash inside the Vault image. The smoke test covers the real runtime.

## Smoke test

`make test-image`, implemented by #7. Logic lives in a script under `scripts/` (Make is only the entry point); the fixture compose stack lives under `test/`.

1. Build the image.
2. Run Vault `--privileged` with the fixture compose file and a published port.
3. `curl` the published port; it must succeed.
4. Assert that nothing listens on port 2375 inside the container ([image.md → Dockerd startup](image.md#dockerd-startup)).
5. `docker stop` the container; it must exit cleanly with code 0.
6. Cleanup (container, volumes, network) **always** runs, also when a check fails.

## Testing strategy

| Layer | Command | Covers |
|-------|---------|--------|
| Lint | `make lint` | All shell code. |
| Unit | `make test` | `source/lib/` functions and edge cases 1–8 ([image.md → Edge cases](image.md#edge-cases)). |
| Smoke | `make test-image` | Real runtime under `--privileged` on amd64: build, startup, port, no TCP listener, clean stop. |

Each edge case maps to a bats test or to the smoke test; the mapping is in [image.md → Edge cases](image.md#edge-cases).

**Not covered by CI:** Sysbox at runtime (checked manually) and arm64 at runtime (built by the release, not run).
