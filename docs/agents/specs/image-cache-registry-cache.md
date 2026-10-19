# Image Cache Spec: Registry Cache

Part of the image-cache spec; start with [the overview](image-cache-overview.md).
Read by #70. Depth: **goals + acceptance + contracts + open decisions** — #70 closes the
[open decisions](#open-decisions) and updates this file in its own PR.

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
  failure. A failed export in `build-and-release` is reported; whether it fails the job is part
  of the flag choice below.
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

## Open decisions

| Decision | Options / notes |
|----------|-----------------|
| Exact `--cache-from` / `--cache-to` flags | e.g. `type=registry,ref=darthjee/vault:buildcache` with `mode=max` on export; whether `ignore-error=true` is set on export. |
| Registry import in `make build-image` | `build-and-test` uses the default-builder `docker build`; decide how it imports a registry cache (cache-from support of the `docker` driver vs switching to a `docker-container` builder with `--load`). |
