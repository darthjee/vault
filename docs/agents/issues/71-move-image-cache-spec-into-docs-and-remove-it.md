# Issue: Move image-cache spec into docs and remove it

## Description
Last sub-issue of epic #65 (reuse unchanged image layers across builds and releases). Every other sub-issue (#66, #68, #69, #70) is merged. Per `docs/agents/specs.md`, a spec lives only while its epic is open: this issue moves what stays relevant from `docs/agents/specs/image-cache-*.md` into the permanent agent docs — mainly a new `docs/agents/release.md` — then deletes the spec files and their row in the *Active specs* table.

Owner: `product-owner`.

## Problem
The rules introduced by the epic are written down mostly in the spec. Some already reached the permanent docs (`Makefile` comments, `docs/agents/folder-structure.md` for `build-image` and `BUILD_CACHE`, `DOCKERHUB_DESCRIPTION.md` for the `:buildcache` note), but the rest would be lost when the spec is deleted:

- the `Dockerfile` layer-order rule (least to most frequently changing, `COPY build/vault` last, `mkdir -p -m 0755` before the `COPY --chmod=644` of the completion files);
- the reproducible-build settings (`SOURCE_DATE_EPOCH=0` with env override, `rewrite-timestamp=true`, the `vault-builder` `docker-container` builder with BuildKit pinned via `BUILDKIT_IMAGE`, why the default `docker` driver is not used, `--no-logfile` on `apk add`, the constant 1970-01-01 `Created` date);
- the `:buildcache` registry cache: who imports / exports it (`build-and-test` imports anonymously, `build-and-release` imports and exports `mode=max` with `ignore-error=true`, PR builds never write it) and its failure semantics;
- the `APK_REFRESH` cache-bust knob (`YYYY-MM`, UTC month by default, overridable) and why it exists (stale `apk` packages);
- the manual digest check `scripts/check_reproducible.sh` (not run in CI).

Agent files also still point at the spec (e.g. `.claude/agents/scripts.md`: "as fixed by the spec"), which becomes a dangling reference once it is gone.

## Expected Behavior
- A new `docs/agents/release.md` is the single home of the image build / release rules listed above, plus a short rationale.
- Other docs and agent files link to `release.md` instead of restating its rules.
- `docs/agents/specs/image-cache-*.md` are deleted; `docs/agents/specs/.gitkeep` stays.
- The `image-cache-` row is removed from the *Active specs* table of `docs/agents/specs.md`; the table itself (header only, no rows) stays for future specs.
- No doc or agent file references the image-cache spec any more.
- The README is not changed.
- `make test-docs` (link check) stays green.

## Solution
### New `docs/agents/release.md`
Owned by `product-owner` (it lives under `docs/agents/`). Sections:

- **Layer order** — least to most frequently changing; `COPY build/vault` is the last content layer; the share-directory `mkdir -p -m 0755` stays before the `COPY --chmod=644` of the completion files; modes that must not change.
- **Reproducible layers** — `SOURCE_DATE_EPOCH` (default `0`, env override), `rewrite-timestamp=true`, `--no-logfile` on `apk add`, the constant `Created` date; `DOCKER_VERSION` bumps rebuild every layer.
- **Builder** — the `docker-container` builder `vault-builder` (override `BUILDER`), BuildKit pinned via `BUILDKIT_IMAGE`, created by `make buildx-builder` / `scripts/ci/setup_buildx.sh`; minimum BuildKit / buildx versions; why the default `docker` driver is not used.
- **Registry cache** — `darthjee/vault:buildcache`: import/export table per CI job, `mode=max`, `ignore-error=true`, missing / unreachable cache only warns, multi-arch cache reused by the amd64 PR build, `BUILD_CACHE=` disables the import.
- **Cache-bust knob** — `APK_REFRESH` (`YYYY-MM`, UTC month by default, overridable in `make` and `scripts/release.sh`); one rebuild of the `apk` layer and later layers per month.
- **Security** — stale `apk` packages (bounded by `APK_REFRESH`); no cache poisoning (only `build-and-release` with the `docker-hub` context writes `:buildcache`).
- **Digest check** — `scripts/check_reproducible.sh`, manual only, not in CI.
- **Why** — short rationale: rejected alternatives (inline cache from `:latest`, CircleCI Docker Layer Caching, shared builder image in another project) and why the epoch is fixed instead of per-commit.

### Other docs
| File | Change |
|------|--------|
| `AGENTS.md`, `.claude/agents/architect.md` | Add `release.md` to the documentation tables. |
| `docs/agents/architecture.md` | Link to `release.md` from the image / release parts instead of restating it. |
| `docs/agents/flow.md` | Link the build / release steps to `release.md` (cache import / export). |
| `docs/agents/folder-structure.md` | Add what is missing (`scripts/check_reproducible.sh`, `APK_REFRESH` / `BUILDER` / `BUILDKIT_IMAGE`, `buildx-builder`), linking to `release.md`. |
| `.claude/agents/dev.md` | Layer-order rule as a convention, linking to `release.md`. |
| `.claude/agents/scripts.md`, `.claude/agents/automation.md` | Replace "as fixed by the spec" with a link to `release.md`. |
| `.claude/agents/product-owner.md` | Add `release.md` to the owned docs. |
| `docs/agents/specs.md` | Remove the `image-cache-` row; keep the empty table. |

The `scripts` agent ownership (`image-cache-agents.md`) was already applied by #66; only verify nothing is missing. Sequencing, sub-issue tables, "Open decisions" and depth markers are spec-only and dropped.

## Benefits
- The epic's build rules survive the spec's removal in one dedicated doc, so future `Dockerfile` / CI changes keep the cache and reproducibility working.
- Closes epic #65 and leaves `docs/agents/specs/` empty for the next epic.
