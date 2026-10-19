# Release

How the image is built and released so that unchanged layers are reused (epic #65).

## Overview

Goal: an unchanged layer is not rebuilt in CI, keeps its digest on Docker Hub and is not
downloaded again by users. Three mechanisms, combined:

| Mechanism | Effect |
|-----------|--------|
| [Layer order](#layer-order) | A frequent change (the CLI) rebuilds only the last content layer. |
| [Reproducible layers](#reproducible-layers) | Unchanged content gives the same layer digest. |
| [Registry cache](#registry-cache) | The build cache is available on fresh CI executors. |

## Layer order

The `Dockerfile` goes from least to most frequently changing:

| # | Instruction | Installed as |
|---|-------------|--------------|
| 1 | `ARG DOCKER_VERSION` / `FROM docker:${DOCKER_VERSION}-dind` | base |
| 2 | `ARG APK_REFRESH` / `RUN ... apk add --no-cache --no-logfile bash` | `bash` |
| 3 | `RUN mkdir -p -m 0755 /usr/local/share/vault /usr/local/share/vault/completion` | share directories |
| 4 | `COPY --chmod=644 cli/completion/vault.bash cli/completion/_vault ...` | completion files |
| 5 | `COPY source/lib/ /usr/local/lib/vault/` | entrypoint libraries |
| 6 | `COPY --chmod=755 source/bin/entrypoint.sh /usr/local/bin/vault-entrypoint` | `vault-entrypoint` |
| 7 | `COPY --chmod=755 source/bin/install.sh /usr/local/bin/vault-install` | `vault-install` |
| 8 | `COPY --chmod=755 build/vault /usr/local/bin/vault` | `vault` — **last content layer** |
| 9 | `ENV`, `VOLUME`, `WORKDIR`, `EXPOSE`, `ENTRYPOINT` | metadata |

Rules:

- A new layer goes where its change frequency puts it.
- The `mkdir -p -m 0755` stays before the `COPY --chmod=644` into that directory; otherwise
  `COPY --chmod` creates the directories with `644`.
- A `DOCKER_VERSION` bump changes the base, so every layer is rebuilt. Expected.

Modes that must not change:

| Path | Mode |
|------|------|
| `/usr/local/bin/vault`, `/usr/local/bin/vault-entrypoint`, `/usr/local/bin/vault-install` | `755` |
| `/usr/local/share/vault/completion/vault.bash`, `/usr/local/share/vault/completion/_vault` | `644` |
| `/usr/local/share/vault`, `/usr/local/share/vault/completion` | `0755` |
| `/usr/local/lib/vault/` and its files | as copied (no `--chmod`) |

## Reproducible layers

- **`SOURCE_DATE_EPOCH`** is fixed at `0` (the Unix epoch). Every build entry point
  (`make build-image`, `scripts/release.sh`, `scripts/check_reproducible.sh`) sets it with an
  env override: `SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-0}"`. Builds need no git metadata.
- **`rewrite-timestamp=true`** on the build output rewrites every layer timestamp to the epoch,
  so file times from the checkout do not reach the digests.
- **`apk add --no-cache --no-logfile`.** Without `--no-logfile`, `apk` writes the current time
  to `/var/log/apk.log` and the layer differs on every build.
- **`Created` date.** The image `Created` date is always 1970-01-01. To know when an image was
  built, use the tag or the registry push date.
- **Accepted drift.** `apk` installs whatever the index serves; `bash` is not pinned. A new
  index changes the `apk` layer; [`APK_REFRESH`](#cache-bust-knob) bounds how stale it gets.

## Builder

| Item | Value |
|------|-------|
| Builder | `docker-container` builder `vault-builder` (override: `BUILDER`) |
| BuildKit | `moby/buildkit:v0.33.1` (override: `BUILDKIT_IMAGE`) |
| Created by | `make buildx-builder` locally; `scripts/ci/setup_buildx.sh` in releases (also registers QEMU for arm64); `scripts/check_reproducible.sh` when missing |
| Used by | `make build-image` (and so `make test-image` / `make test-cli-e2e`), releases, `scripts/check_reproducible.sh` |
| Minimums | BuildKit v0.13+ (`rewrite-timestamp`), buildx v0.10+ (forwards `SOURCE_DATE_EPOCH`) |

- `make build-image` uses `--output type=docker,rewrite-timestamp=true`, so the image is still
  loaded into the local image store as `$(IMAGE)`.
- Releases use `--output type=image,push=$PUSH,rewrite-timestamp=true` for `linux/amd64` and
  `linux/arm64`.
- The default `docker` driver is not used: on the classic image store it ignores
  `rewrite-timestamp`, so a build that bypasses `vault-builder` is not reproducible.

## Registry cache

The BuildKit cache lives on Docker Hub as `darthjee/vault:buildcache`.

| CI job | Context | Imports | Exports |
|--------|---------|---------|---------|
| `build-and-test` | none (anonymous pull, public repo) | yes, via `make build-image` | no |
| `build-and-release` | `docker-hub` | yes, via `scripts/release.sh` | yes, `mode=max` |

| Entry point | Flags |
|-------------|-------|
| `scripts/release.sh` | `CACHE_REF="$RELEASE_IMAGE:buildcache"`. Always `--cache-from type=registry,ref=$CACHE_REF`; only when `PUSH=true`, also `--cache-to type=registry,ref=$CACHE_REF,mode=max,ignore-error=true`. |
| `make build-image` | `--cache-from type=registry,ref=$(BUILD_CACHE)` when `BUILD_CACHE` is non-empty (default `darthjee/vault:buildcache`; `BUILD_CACHE=` disables it). Never `--cache-to`. |

- **Failure semantics.** A missing or unreachable cache on import is only a BuildKit warning; a
  failed export is ignored (`ignore-error=true`). Neither fails the build.
- **Multi-arch.** The cache written by the multi-arch release is reused by the amd64-only PR
  build.
- **Docker Hub.** `DOCKERHUB_DESCRIPTION.md` notes that `:buildcache` is a build cache, not an
  image to run.

## Cache-bust knob

- Build arg `APK_REFRESH=YYYY-MM`, declared in the `Dockerfile` right before `RUN apk add` and
  referenced in it (default `unset`, so a plain `docker build` works).
- The `Makefile` and `scripts/release.sh` default it to the UTC month (`date -u +%Y-%m`); both
  accept an override (`APK_REFRESH=...`).
- A new value rebuilds the `apk` layer and every later one; their digests change. Expect this
  once a month. Set a new value to pick up an urgent security fix sooner.

## Security

- **Stale `apk` packages.** A cached `apk` layer would never get security fixes;
  `APK_REFRESH` rebuilds it at least once a month.
- **No cache poisoning.** PR builds never write the cache. Only `build-and-release` (context
  `docker-hub`, release tags) pushes `:buildcache`.
- **Runtime privileges.** Unaffected: the image still needs `--privileged` or Sysbox.

## Checking reproducibility

`scripts/check_reproducible.sh` (manual only, not run in CI):

- builds the image twice with `--no-cache`, the same `SOURCE_DATE_EPOCH`, `APK_REFRESH` and
  `rewrite-timestamp=true`, on `vault-builder`;
- compares `.RootFS.Layers` of both images;
- exits `0` if identical (`reproducible: N layers identical`), `1` otherwise, printing the
  differing layer indexes.

Expected results:

| Change between the two builds compared | Differing layers |
|--------|------------------|
| None (two builds of one commit) | none |
| `cli/` only | the `build/vault` layer only |
| New `APK_REFRESH` | the `apk` layer and every later one |
| `DOCKER_VERSION` bump | all |

## Why

- **Combined approaches.** Layer order makes the cache hit more layers, reproducible layers make
  the hits give the same digests, the registry cache makes them available on fresh executors.
- **Fixed epoch, not per-commit.** A per-commit epoch (`git log -1 --format=%ct`) changes every
  clamped layer on a cache miss, so unchanged content would still get new digests.

Rejected alternatives:

| Alternative | Why rejected |
|-------------|--------------|
| Inline cache from `:latest` | `mode=min` only (no intermediate layers); weak for multi-arch. |
| CircleCI Docker Layer Caching | Paid; speeds up CI only, no effect on Docker Hub digests or pulls. |
| Shared builder image in another project | Cross-repo releases and a pin bump here for every build fix. |
