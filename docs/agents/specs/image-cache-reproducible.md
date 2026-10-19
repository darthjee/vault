# Image Cache Spec: Reproducible Layers

Part of the image-cache spec; start with [the overview](image-cache-overview.md).
Read by #69. Depth: **final** — #69 closed the [decisions](#decisions).

## Goal

Unchanged content keeps the same layer digest across builds. This is approach C of the
[decision](image-cache-overview.md#decision).

- `SOURCE_DATE_EPOCH` = `0` (the Unix epoch), fixed, as set in the
  [shared contracts](image-cache-overview.md#shared-contracts). Every entry point defaults it to
  `0` and allows an env override. A per-commit epoch is not used: on a cache miss it would change
  every clamped layer, even when its content did not change.
- Both `scripts/release.sh` and `make build-image` build with `SOURCE_DATE_EPOCH` set and
  `rewrite-timestamp=true`, so file timestamps inside the layers no longer depend on the
  checkout.
- Every build runs on the same `docker-container` builder, `vault-builder`, with BuildKit
  pinned to `moby/buildkit:v0.33.1` (see [Decisions](#decisions)). The default `docker` driver
  is not used: on the classic image store it ignores `rewrite-timestamp`.
- A cache-bust build arg, `APK_REFRESH`, lets the `apk add` layer pick up security fixes
  (see [Security](image-cache-overview.md#security)).

## Edge cases

- **`DOCKER_VERSION` bump.** Changes the base image, so every layer is rebuilt and gets new
  digests. Expected; not a failure of reproducibility.
- **`apk` layer.** `apk add --no-cache --no-logfile bash` downloads whatever the index serves at build time;
  a new `bash` package or index changes the layer even with a fixed `SOURCE_DATE_EPOCH`. Within
  a month the cache keeps the layer; when `APK_REFRESH` moves to the next month the layer is
  rebuilt and picks up the current index.
- **`apk` log file.** Without `--no-logfile`, `apk add` writes the current time into
  `/var/log/apk.log`, so the layer differs on every build. The `Dockerfile` passes
  `--no-logfile` to keep the layer reproducible.
- **Default `docker` driver.** On the classic image store the default buildx driver ignores
  `rewrite-timestamp` (seen on Docker 29.3.0 / buildx v0.32.1 / embedded BuildKit v0.28.0:
  layers differed). A build that bypasses `vault-builder` is not reproducible.
- **Cache-bust use.** A new `APK_REFRESH` value (the monthly change, or a manual override)
  rebuilds the `apk` layer and every later layer; their digests change. Expect one such
  rebuild per month.
- **Constant `Created` date.** With the epoch fixed at `0`, the image `Created` date is always
  1970-01-01. It no longer tells when an image was built; use the tag or the registry push date.

## Acceptance criteria

- Two builds of the same commit produce identical layer digests.
- After a `cli/`-only change, only the last layer (`COPY build/vault`) differs.
- `make test-image` and `make test-cli-e2e` stay green.
- The cache-bust knob is documented where it is used.

## Decisions

| Decision | Outcome |
|----------|---------|
| Minimum buildx / BuildKit version | BuildKit v0.13+ (first release with `rewrite-timestamp`); buildx v0.10+ (forwards `SOURCE_DATE_EPOCH` from the environment to BuildKit). Both minimums come from release history and were not checked against the release notes. Tested and pinned: BuildKit v0.33.1. |
| Builder | One `docker-container` builder, `vault-builder` (override: `BUILDER`), running BuildKit pinned to `moby/buildkit:v0.33.1` (override: `BUILDKIT_IMAGE`). Used by `make build-image` (and so the tests), releases (created by `scripts/ci/setup_buildx.sh`) and `scripts/check_reproducible.sh`. The Makefile target `buildx-builder` creates it when missing. The default `docker` driver is rejected: on the classic image store it ignores `rewrite-timestamp` (the containerd image store would also work, but is not required of contributors). |
| Loading local builds | `make build-image` uses `--output type=docker,rewrite-timestamp=true`, so the image built on `vault-builder` is still loaded into the local image store for `make test-image` / `make test-cli-e2e`. |
| Deterministic `apk` layer | Accept index drift; the `bash` version is not pinned. The monthly `APK_REFRESH` bounds how stale the layer can get. |
| Form of the cache-bust knob | Build arg `APK_REFRESH=YYYY-MM`, declared in the `Dockerfile` right before `RUN apk add --no-cache --no-logfile bash` and referenced in it. `scripts/release.sh` and the `Makefile` default it to the UTC month (`date -u +%Y-%m`); both accept an override. |
| Digest check in CI | Manual only. `scripts/check_reproducible.sh` builds twice with `--no-cache` (same flags and `APK_REFRESH`) and compares `.RootFS.Layers`; exit 0 if identical, 1 otherwise, printing the differing layer indexes. Not run in CI. |
