# Issue: Make image layers reproducible

## Description
Part of epic #65 (reuse unchanged image layers across builds and releases). Make the image build reproducible, so the same layer content always gives the same layer digest, with or without a cache hit. The spec is [image-cache-reproducible.md](../specs/image-cache-reproducible.md); this issue closes its open decisions and updates that file in the same PR.

Sequencing: after #66 (spec + scripts agent) and #68 (Dockerfile reorder), both done. Before #70 (registry cache).

## Problem
A rebuild of unchanged content still gives new file timestamps (git checkout sets mtimes to checkout time), so the layer gets a new digest. Docker Hub stores a new blob and users download it again.

The shared contract `SOURCE_DATE_EPOCH = git log -1 --format=%ct` does not fix this on a cache miss: `rewrite-timestamp` clamps every newer mtime to the epoch, and the epoch changes with every commit, so a `cli/`-only commit would still change every layer.

## Expected Behavior
- Two builds of the same commit produce identical layer digests.
- After a `cli/`-only change, only the last layer (`COPY build/vault`) differs, even with no build cache (within the same cache-bust month).
- `make test-image` and `make test-cli-e2e` stay green.
- The cache-bust knob is documented where it is used.

## Solution
- **Fixed epoch.** Build with a constant `SOURCE_DATE_EPOCH` (e.g. `0`) and `rewrite-timestamp=true` on the image output, in both `scripts/release.sh` (multi-arch `buildx` release) and `make build-image` (local / `build-and-test` build). Layer digests then depend only on content. The image's `Created` date becomes constant; that is accepted. This replaces the `SOURCE_DATE_EPOCH` shared contract in `docs/agents/specs/image-cache-overview.md`, which is updated in the same PR (and the "shallow or detached checkout" edge case in the reproducible spec no longer applies).
- **apk layer + cache-bust knob.** Accept apk index drift. Add a build arg (e.g. `APK_REFRESH=YYYY-MM`) declared just before `RUN apk add --no-cache bash` and used in that `RUN`, so changing it rebuilds that layer. Both build entry points compute the current month by default and allow an override. The apk layer and every later layer rebuild at most once a month, which picks up `bash` security fixes without waiting for a `DOCKER_VERSION` bump. Document the knob in the `Dockerfile` and the spec.
- **Tooling versions.** Check the minimum buildx / BuildKit version `rewrite-timestamp` needs, and that both the CircleCI `ubuntu-2404:current` machine image (`docker-container` builder from `scripts/ci/setup_buildx.sh`) and the plain `docker build` path of `make build-image` support it. Switch `build-image` to `docker buildx build --load` (or pin a version) if needed.
- **Digest check.** Add a `scripts/` script (e.g. `scripts/check_reproducible.sh`), with bats tests under `test/scripts/`, that builds twice with no cache and compares layer digests. It is run by hand only, not in CI.
- **Docs.** Close the open decisions in `docs/agents/specs/image-cache-reproducible.md` and update the overview's shared contracts.

Responsible agents: `scripts` (`release.sh`, digest-check script and tests), `automation` (`Makefile`, CircleCI if needed), `dev` (`Dockerfile` build arg), `product-owner` (spec updates).

## Benefits
Unchanged layers keep their digests even without a cache, so releases push less, users download less, and the registry cache in #70 works on stable layers. `bash` still gets security fixes every month.
