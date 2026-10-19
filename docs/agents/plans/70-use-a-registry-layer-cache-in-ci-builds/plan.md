# Plan: Use a registry layer cache in CI builds

Issue: [70-use-a-registry-layer-cache-in-ci-builds.md](../../issues/70-use-a-registry-layer-cache-in-ci-builds.md)

## Overview
Store the BuildKit layer cache on Docker Hub as `darthjee/vault:buildcache` (approach A of epic #65). `scripts/release.sh` imports it on every run and exports it (`mode=max`, best-effort) only when it pushes. `make build-image` imports it, through an overridable `BUILD_CACHE` variable, and never exports. No CircleCI change is expected, because both jobs already go through `make`.

## Agents involved

- [scripts](scripts.md)
- [automation](automation.md)
- [product-owner](product-owner.md)

## Shared contracts

- **Cache tag:** `darthjee/vault:buildcache` (the default for both entry points).
- **`release.sh` cache ref:** `CACHE_REF="$RELEASE_IMAGE:buildcache"`. It is derived and is not a separate env var.
- **`release.sh` flags**, appended after the existing `--output` argument and before the optional `DOCKER_VERSION` build arg:
  - always: `--cache-from type=registry,ref=$CACHE_REF`
  - only when `PUSH=true`: `--cache-to type=registry,ref=$CACHE_REF,mode=max,ignore-error=true`
- **`Makefile` variable:** `BUILD_CACHE ?= darthjee/vault:buildcache`, exported like the other variables. When it is non-empty, `build-image` adds `--cache-from type=registry,ref=$(BUILD_CACHE)`. When it is empty (`make build-image BUILD_CACHE=`), no cache flag is passed. `build-image` never passes `--cache-to`.
- **Failure semantics:** a missing or unreachable cache on import is only a BuildKit warning. A failed export is ignored (`ignore-error=true`). Neither fails the build.
- **`DOCKERHUB_DESCRIPTION.md`** note: one line saying `:buildcache` is a build cache used by CI, not a runnable image.
