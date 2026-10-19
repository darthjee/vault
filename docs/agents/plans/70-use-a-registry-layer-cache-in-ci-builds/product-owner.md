# Product Owner Plan: Use a registry layer cache in CI builds

Main plan: [plan.md](plan.md)

## Shared contracts

- Decisions to record, as fixed in the main plan:
  - `release.sh` cache ref `$RELEASE_IMAGE:buildcache`: `--cache-from` always, `--cache-to ...,mode=max,ignore-error=true` only when `PUSH=true`;
  - `make build-image` imports via `BUILD_CACHE ?= darthjee/vault:buildcache` (empty disables) and never exports;
  - verification: bats arg tests plus a manual `CACHED` check.

## Implementation Steps

### Step 1 — Close the spec's open decisions
In `docs/agents/specs/image-cache-registry-cache.md`:
- Replace the *Open decisions* table with a *Decisions* section recording the contracts above.
- Note that the "registry import in `make build-image`" question was settled by #69, which moved `build-image` onto the `vault-builder` docker-container builder with `--output type=docker`.
- Resolve the "whether it fails the job" phrasing in *Edge cases*: a failed export does not fail the release.
- Update this file's *Status* in the table of `image-cache-overview.md` to `Final`.

### Step 2 — Document `BUILD_CACHE`
In `docs/agents/folder-structure.md`:
- Add a `BUILD_CACHE` row (default `darthjee/vault:buildcache`, empty disables the import) to the Makefile variables table.
- Update the `build-image` row to mention the buildx `vault-builder` build and the registry cache import.

## Files to Change
- `docs/agents/specs/image-cache-registry-cache.md` — decisions recorded.
- `docs/agents/specs/image-cache-overview.md` — status of the registry-cache spec file.
- `docs/agents/folder-structure.md` — `BUILD_CACHE` variable and the `build-image` description.

## CI Checks
- `docs/`: `make test-docs` (CI job: `build-and-test`).

## Notes
- Moving the spec content into the permanent docs is #71's job. Keep this change limited to recording decisions.
