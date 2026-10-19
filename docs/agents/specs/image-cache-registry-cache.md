# Image Cache Spec: Registry Cache

Part of the image-cache spec; start with [the overview](image-cache-overview.md).
Read by #70. Depth: **final** — #70 closed the [decisions](#decisions).

## Goal

Make the build cache available on fresh CircleCI executors by storing it on Docker Hub. This is
approach A of the [decision](image-cache-overview.md#decision).

## Contracts

Fixed by the [shared contracts](image-cache-overview.md#shared-contracts); restated here for #70.

- **Tag:** `darthjee/vault:buildcache`, exported with `mode=max` (intermediate layers included).
- **`build-and-test`** imports the cache anonymously: the repository is public, so no
  credentials and no new CircleCI context are needed. It never exports.
- **`build-and-release`** (context `docker-hub`) imports and exports the cache.
- **PR builds never export.** Only release builds write `:buildcache`.
- **`DOCKERHUB_DESCRIPTION.md`** gets a one-line note that `:buildcache` is a build cache, not a
  runnable image.

## Edge cases

- **Missing cache.** The first build (no `:buildcache` yet) succeeds, uncached.
- **Docker Hub unreachable or rate-limited.** Import degrades to an uncached build, not a
  failure (BuildKit only prints a warning). A failed export in `build-and-release` is reported
  as a warning and does not fail the release (`ignore-error=true`, see [Decisions](#decisions)).
- **Multi-arch cache, single-arch PR build.** The cache is written by the multi-arch
  (`linux/amd64`, `linux/arm64`) release build; the PR build is amd64 only and must reuse the
  amd64 layers without needing the arm64 ones.
- **`DOCKER_VERSION` bump.** Invalidates every cached layer; the next release rewrites the
  cache.

## Acceptance criteria

- A second release build of an unchanged tree shows `CACHED` layers.
- `build-and-test` reuses the layers of the last release.
- A build with no `:buildcache` on Docker Hub succeeds.
- `make test-image` and `make test-cli-e2e` stay green.
- `DOCKERHUB_DESCRIPTION.md` carries the `:buildcache` note.

## Decisions

| Decision | Outcome |
|----------|---------|
| `scripts/release.sh` flags | Cache ref `CACHE_REF="$RELEASE_IMAGE:buildcache"` (derived, not a separate env var). Always `--cache-from type=registry,ref=$CACHE_REF`; only when `PUSH=true`, also `--cache-to type=registry,ref=$CACHE_REF,mode=max,ignore-error=true`. Both come after `--output` and before the optional `DOCKER_VERSION` build arg. |
| Registry import in `make build-image` | Settled by #69: `build-image` already runs on the `docker-container` builder `vault-builder` with `--output type=docker,rewrite-timestamp=true`, so it can import a registry cache with no driver change. It adds `--cache-from type=registry,ref=$(BUILD_CACHE)` when `BUILD_CACHE` is non-empty (`BUILD_CACHE ?= darthjee/vault:buildcache`; `make build-image BUILD_CACHE=` disables the import). It never passes `--cache-to`. |
| Failure semantics | A missing or unreachable cache on import is only a BuildKit warning. A failed export is ignored (`ignore-error=true`). Neither fails the build. |
| CircleCI | No change: `build-and-test` and `build-and-release` both go through `make`. |
| Verification | bats argument tests for `scripts/release.sh` (cache flags with and without `PUSH=true`) plus a manual check that a second build of an unchanged tree shows `CACHED` layers. |
