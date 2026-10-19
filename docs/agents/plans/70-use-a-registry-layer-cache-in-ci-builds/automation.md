# Automation Plan: Use a registry layer cache in CI builds

Main plan: [plan.md](plan.md)

## Shared contracts

- `BUILD_CACHE ?= darthjee/vault:buildcache`, added to the `export` line.
- When `BUILD_CACHE` is non-empty, `build-image` passes `--cache-from type=registry,ref=$(BUILD_CACHE)`. When it is empty, it passes nothing. It never passes `--cache-to`.
- `release.sh` (owned by `scripts`) handles the release side. `make release` needs no change.
- `DOCKERHUB_DESCRIPTION.md` gets one line saying `:buildcache` is a build cache used by CI, not a runnable image.

## Implementation Steps

### Step 1 — Registry cache import in `make build-image`
- Add `BUILD_CACHE ?= darthjee/vault:buildcache` near `BUILDER` / `BUILDKIT_IMAGE`, with a short comment:
  - the build imports the release cache anonymously, since the repository is public;
  - it never exports it;
  - set it empty to disable the import.
- Add `BUILD_CACHE` to the `export` line.
- In the `build-image` recipe, add `$(if $(BUILD_CACHE),--cache-from type=registry,ref=$(BUILD_CACHE))`, matching the existing `DOCKER_VERSION` idiom.
- Leave `.circleci/config.yml` untouched. `build-and-test` gets the import through `make test-image` / `make test-cli-e2e`, and `build-and-release` through `make release`. Verify this by reading the config, and only change it if something is actually missing.
- Sanity-check with `make -n build-image`, both with the default and with `BUILD_CACHE=`.

### Step 2 — `:buildcache` note in `DOCKERHUB_DESCRIPTION.md`
- Add one line near the tags / how-to-run area saying `darthjee/vault:buildcache` is a BuildKit layer cache used by CI builds, not an image to run.

## Files to Change
- `Makefile` — `BUILD_CACHE` variable, export, `--cache-from` in `build-image`.
- `DOCKERHUB_DESCRIPTION.md` — `:buildcache` note.

## CI Checks
- `Makefile`: `make test-image` and `make test-cli-e2e` (CI job: `build-and-test`). They must stay green with the import enabled, both before the first release has written `:buildcache` and after.

## Notes
- Manual acceptance after merge:
  - the first `build-and-test` run after a release shows `CACHED` layers (except `COPY build/vault`, which changes per commit);
  - a second release shows `CACHED` layers.
- Cache hits require matching build args. `APK_REFRESH` (monthly) and `DOCKER_VERSION` are the same in both entry points, so a month rollover or a `DOCKER_VERSION` bump causes one expected uncached build.
- The PR build is amd64 only. With `mode=max` the cache holds both platforms, and BuildKit only pulls the amd64 records.
