# Image Cache Spec: Overview

Spec for epic #65 (reuse unchanged image layers across builds and releases). Written by #66.
Every sub-issue of the epic reads this file first, then its own feature file (see [Files](#files)).

## Goal

Reuse the unchanged layers of `darthjee/vault`:

- in CI builds (`build-and-test` and `build-and-release`), so they do not rebuild what did not change;
- in what is pushed to Docker Hub, so an unchanged layer keeps its digest;
- in what users pull, so they only download the layers that really changed.

## Current state

- **No cache in CI.** Every job runs on a fresh `machine` executor, so every build starts from
  scratch.
- **New digests for identical content.** A rebuilt layer gets new file timestamps (the git
  checkout sets mtimes), so the same content yields a new digest on Docker Hub and a new
  download for users.
- **Bad layer order.** `COPY build/vault` — which changes every release — sits before layers
  that rarely change (`vault-install`, the completion files), so those are rebuilt too.
- **A pull does not help the release build.** A plain `docker pull` fills the local image
  store, which the `buildx` `docker-container` builder used by `scripts/release.sh` does not
  read.

## Decision

Three approaches, combined, one sub-issue each:

| Code | Approach | Sub-issue |
|------|----------|-----------|
| D | Reorder the `Dockerfile` so frequently-changing layers come last. | #68 |
| C | Reproducible layers: `SOURCE_DATE_EPOCH` + `rewrite-timestamp=true`, so unchanged content keeps the same digest. | #69 |
| A | A registry cache on a dedicated tag, `darthjee/vault:buildcache` (`mode=max`): every build imports it, only releases export it. | #70 |

D makes the cache hit more layers, C makes the hits produce the same digests, A makes the cache
available on fresh executors.

## Rejected alternatives

| Alternative | Why rejected |
|-------------|--------------|
| Inline cache from `:latest` | Weak for multi-arch images; inline cache only supports `mode=min`, so intermediate layers are not cached. |
| CircleCI Docker Layer Caching | Paid feature; it speeds up CI only, with no benefit on Docker Hub digests or user pulls. |
| Shared builder image in another project | Cross-repo releases, and a pin bump in this repo for every build fix. |

## Shared contracts

Later sub-issues rely on these and do not re-decide them. A PR that changes one updates this
file in the same PR.

- **Cache tag:** `darthjee/vault:buildcache`.

  | Job | Context | Imports | Exports |
  |-----|---------|---------|---------|
  | `build-and-test` | none (anonymous pull, public repo) | yes | no |
  | `build-and-release` | `docker-hub` | yes | yes, `mode=max` |

  PR builds never write the cache. No new CircleCI context is added.
- **`SOURCE_DATE_EPOCH`** = `0` (the Unix epoch), fixed. Every build entry point sets it,
  defaulting to `0` with an env override (`SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-0}"`). A
  per-commit epoch (`git log -1 --format=%ct`) was dropped: on a cache miss it changes every
  layer whose timestamps it clamps, so unchanged content would still get new digests. Builds no
  longer need git metadata.
- **Cache-bust build arg:** `APK_REFRESH`, format `YYYY-MM` (UTC month, `date -u +%Y-%m` by
  default, overridable). A new value rebuilds the `apk add` layer and every later layer.
- **Builder:** every build (`make build-image`, the tests, releases,
  `scripts/check_reproducible.sh`) uses the `docker-container` builder `vault-builder`
  (override: `BUILDER`), BuildKit pinned to `moby/buildkit:v0.33.1` (override:
  `BUILDKIT_IMAGE`). Details in
  [image-cache-reproducible.md → Decisions](image-cache-reproducible.md#decisions).
- **Scripts agent:** `scripts` owns every top-level `scripts/*.sh` and `test/scripts/`; the path
  decides the owner. Details in [image-cache-agents.md](image-cache-agents.md).
- **`Dockerfile` layer order:** least to most frequently changing; `COPY build/vault` is the last
  content layer. Details in [image-cache-dockerfile.md](image-cache-dockerfile.md).

## Sequencing

#66 → #68 → #69 → #70 → #71.

| Issue | Does |
|-------|------|
| #66 | Writes this spec and adds the `scripts` agent. |
| #68 | Reorders the `Dockerfile` (D). |
| #69 | Reproducible layers (C). |
| #70 | Registry cache (A). |
| #71 | Moves what stays relevant into the README and the agent docs, then deletes this spec. |

## Backward compatibility

- No change to the image contents (files, permissions, owners) or its runtime behaviour.
- A new `:buildcache` tag appears on Docker Hub; `DOCKERHUB_DESCRIPTION.md` notes that it is a
  build cache, not an image to run.
- Layer digests change **once**, with the reorder (#68). After that, unchanged layers keep their
  digests across releases.

## Security

- **Stale `apk` packages.** A cached `apk add` layer would never pick up security fixes. The
  `APK_REFRESH` build arg (UTC month by default) rebuilds it once a month; set it to a new value
  to pick up an urgent fix sooner
  (see [image-cache-reproducible.md → Decisions](image-cache-reproducible.md#decisions)).
- **No cache poisoning.** PR builds never write the cache. Only `build-and-release`, which runs
  with the `docker-hub` context on release tags, can push `:buildcache`.

## Runtime privileges

None change. The image still needs `--privileged` or Sysbox exactly as before; the epic only
touches how it is built.

## Files

| File | Covers | Read by | Depth |
|------|--------|---------|-------|
| [image-cache-overview.md](image-cache-overview.md) | This file: goal, decision, shared contracts, sequencing, compatibility, security. | every sub-issue | Final |
| [image-cache-agents.md](image-cache-agents.md) | The `scripts` agent, what `automation` keeps, docs to update. | #66 | Final |
| [image-cache-dockerfile.md](image-cache-dockerfile.md) | Target layer order, permissions that must not change. | #68 | Final |
| [image-cache-reproducible.md](image-cache-reproducible.md) | `SOURCE_DATE_EPOCH` / `rewrite-timestamp`, `apk` layer, cache-bust knob, digest check. | #69 | Final |
| [image-cache-registry-cache.md](image-cache-registry-cache.md) | Who imports / exports `:buildcache`, fallbacks, `DOCKERHUB_DESCRIPTION.md` note. | #70 | Goals + acceptance + contracts + open decisions |

The clean-up sub-issue (#71) has no file; it is driven by `docs/agents/specs.md`.

## Spec rules

- Each feature file has its own **Edge cases** and **Acceptance criteria**, so a sub-issue only
  needs this overview and its own file.
- Cross-cutting concerns (backward compatibility, cache poisoning) live only in this overview.
- A non-final file has an **Open decisions** section. The owning sub-issue closes each decision
  and updates the file in its own PR.
- Spec files link only to each other; repo paths and issue numbers are plain text or inline
  code.
