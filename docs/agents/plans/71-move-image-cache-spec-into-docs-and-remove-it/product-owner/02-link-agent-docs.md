# Link release.md from the agent docs
Point the existing agent docs at `release.md` instead of restating its rules, and fill the small gaps in the reference tables.

- `docs/agents/architecture.md`:
  - `## Image`: after "Built for `linux/amd64` and `linux/arm64` by the release.", add a bullet: layers are ordered by change frequency, reproducible and cached in `darthjee/vault:buildcache`; see `[Release](release.md)`.
  - `## Security`: one bullet on the build cache (only release builds write `:buildcache`; `APK_REFRESH` bounds stale `apk` packages), linking to `release.md#security`.
- `docs/agents/folder-structure.md`:
  - `## Project Root` / `docs/agents/` row: nothing to change unless it lists the agent docs.
  - `## scripts/`: add `check_reproducible.sh` (manual reproducibility check, see `release.md`) to the scripts list.
  - `## Makefile` targets table: add `buildx-builder` (creates the `vault-builder` `docker-container` builder from `BUILDKIT_IMAGE` when missing); in `build-image`, mention `rewrite-timestamp=true`, `SOURCE_DATE_EPOCH` and `--build-arg APK_REFRESH`, linking to `release.md`; in `release`, mention the cache import / export.
  - Variables table: add `BUILDER` (`vault-builder`), `BUILDKIT_IMAGE` (`moby/buildkit:v0.33.1`), `APK_REFRESH` (UTC month, `date -u +%Y-%m`) and `SOURCE_DATE_EPOCH` (env, default `0`) if the Makefile treats it as a variable; check defaults in the `Makefile`.
- `docs/agents/flow.md`: no change (runtime flow only).

## Files to Change
- `docs/agents/architecture.md` — link from `## Image` and `## Security`.
- `docs/agents/folder-structure.md` — `check_reproducible.sh`, `buildx-builder`, build variables, links to `release.md`.
