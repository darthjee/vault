# Issue: Use a registry layer cache in CI builds

## Description
Part of epic #65: reuse unchanged image layers across builds and releases. This is approach **A** of the epic, a registry cache on the dedicated tag `darthjee/vault:buildcache`. It comes after #68 (layer reorder) and #69 (reproducible layers), which are both merged. Spec: `docs/agents/specs/image-cache-registry-cache.md`.

## Problem
CI builds run on fresh `machine` executors, so nothing is cached between builds: `apk add bash` and every `COPY` layer are rebuilt each time. A plain `docker pull` of `:latest` does not help, because the `vault-builder` buildx `docker-container` builder (used by both `make build-image` and `scripts/release.sh` since #69) keeps its own cache, separate from the local image store.

## Expected Behavior
- Release builds (`build-and-release`, `docker-hub` context) import and export the registry cache with `mode=max`, so the cache holds `linux/amd64` and `linux/arm64`.
- `build-and-test` (PRs / branches, `make build-image`) imports the cache anonymously. The repository is public, so it needs no credentials and no new context. PR builds never export, so PRs cannot poison the cache.
- A missing cache (first build), or Docker Hub being unreachable or rate-limited, never fails a build. It degrades to an uncached build.
- A failed cache export never fails a release whose image push succeeded. It is reported as a warning.

### Acceptance criteria
- A second release build of an unchanged tree shows `CACHED` layers (checked by hand on the first releases after merge).
- `build-and-test` reuses the layers of the last release (checked by hand in the CI output).
- A build with no `:buildcache` tag present still succeeds.
- `test/scripts/release.bats` asserts the new `--cache-from` / `--cache-to` arguments, including no `--cache-to` when `PUSH=false` and the ref following `RELEASE_IMAGE`.
- `make test-image` and `make test-cli-e2e` stay green.
- `DOCKERHUB_DESCRIPTION.md` carries the `:buildcache` note.

## Solution
Decisions (these close the open decisions in the spec):

- **`scripts/release.sh`** (`scripts` agent, with `release.bats`):
  - The cache ref is derived from the image: `CACHE_REF="$RELEASE_IMAGE:buildcache"`, so test or fork runs with another `RELEASE_IMAGE` never write `darthjee/vault:buildcache`.
  - It always passes `--cache-from type=registry,ref=$CACHE_REF`.
  - Only when `PUSH=true` does it also pass `--cache-to type=registry,ref=$CACHE_REF,mode=max,ignore-error=true`. A `PUSH=false` dry run imports but never exports.
  - Update the usage comment at the top of the script.
- **`Makefile` `build-image`** (`automation`):
  - Add an overridable variable, e.g. `BUILD_CACHE ?= darthjee/vault:buildcache`.
  - When it is non-empty, `build-image` passes `--cache-from type=registry,ref=$(BUILD_CACHE)`. `make build-image BUILD_CACHE=` disables the import.
  - It never passes `--cache-to`. Local and CI builds both import by default.
- **No registry-import change of driver needed**: #69 already moved `build-image` onto the `vault-builder` docker-container builder with `--output type=docker`, which supports registry cache import. This settles the second open decision in the spec.
- **`.circleci/config.yml`**: no change expected. `build-and-test` already calls `make test-image` / `make test-cli-e2e`, and `build-and-release` already calls `make release` with the `docker-hub` context.
- **`DOCKERHUB_DESCRIPTION.md`** (`automation`): add a one-line note that `:buildcache` is a build cache, not a runnable image.
- **Spec** (`product-owner`): move the two rows of *Open decisions* in `image-cache-registry-cache.md` into a *Decisions* section reflecting the above.

### Responsible agents
`scripts` (`scripts/release.sh`, `test/scripts/release.bats`), `automation` (`Makefile`, `DOCKERHUB_DESCRIPTION.md`, CircleCI if anything turns out to be needed), `product-owner` (spec update).

## Benefits
- Builds on fresh CI executors reuse the layers of the last release instead of rebuilding `apk add bash` and every `COPY`.
- Faster PR and release builds, with less re-uploading to Docker Hub (together with the reproducible digests from #69).
- No cache poisoning: only release builds with the `docker-hub` context write the cache.
