# Scripts Plan: Use a registry layer cache in CI builds

Main plan: [plan.md](plan.md)

## Shared contracts

- `CACHE_REF="$RELEASE_IMAGE:buildcache"` (derived, so it follows a `RELEASE_IMAGE` override).
- After the existing `--output type=image,push=$PUSH,rewrite-timestamp=true` argument, always append `--cache-from type=registry,ref=$CACHE_REF`.
- Only when `PUSH=true`, also append `--cache-to type=registry,ref=$CACHE_REF,mode=max,ignore-error=true`.
- The optional `--build-arg DOCKER_VERSION=...` stays last, as today.

## Implementation Steps

### Step 1 — Import / export the registry cache in `release.sh`
- After `PUSH` is validated, compute `CACHE_REF="$RELEASE_IMAGE:buildcache"`.
- Add `--cache-from type=registry,ref=$CACHE_REF` to `args`.
- When `PUSH` is `true`, also add `--cache-to type=registry,ref=$CACHE_REF,mode=max,ignore-error=true`.
- Extend the usage comment at the top of the script:
  - the cache is read from `$RELEASE_IMAGE:buildcache` on every run;
  - it is written (`mode=max`, intermediate layers for both platforms) only when `PUSH=true`;
  - a missing cache or a failed export never fails the build.
- Add the cache ref to the `release: building ...` echo line.

### Step 2 — Update `test/scripts/release.bats`
- Update the exact expected command lines in the default test and the overrides test:
  - default: `... --output type=image,push=true,rewrite-timestamp=true --cache-from type=registry,ref=darthjee/vault:buildcache --cache-to type=registry,ref=darthjee/vault:buildcache,mode=max,ignore-error=true .`
  - overrides: the `me/img:buildcache` ref, with `--build-arg DOCKER_VERSION=27.0.0` last.
- Extend the `PUSH=false` test: the log contains `--cache-from type=registry,ref=darthjee/vault:buildcache` exactly once and `--cache-to` zero times.

## Files to Change
- `scripts/release.sh` — cache import/export flags, usage comment, echo line.
- `test/scripts/release.bats` — expected command lines and the PUSH=false cache assertions.

## CI Checks
- `scripts/`, `test/scripts/`: `make lint` and `make test` (CI job: `build-and-test`).

## Notes
- `ignore-error=true` on `--cache-to` needs a recent BuildKit. The pinned `moby/buildkit:v0.33.1` supports it.
- With the `docker-container` driver, a missing `--cache-from` ref only produces a warning, so the first release (no `:buildcache` yet) still succeeds.
