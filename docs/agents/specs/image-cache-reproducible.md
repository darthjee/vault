# Image Cache Spec: Reproducible Layers

Part of the image-cache spec; start with [the overview](image-cache-overview.md).
Read by #69. Depth: **goals + acceptance + open decisions** — #69 closes the
[open decisions](#open-decisions) and updates this file in its own PR.

## Goal

Unchanged content keeps the same layer digest across builds. This is approach C of the
[decision](image-cache-overview.md#decision).

- `SOURCE_DATE_EPOCH` = timestamp of the last commit (`git log -1 --format=%ct`), as fixed in
  the [shared contracts](image-cache-overview.md#shared-contracts).
- Both `scripts/release.sh` and `make build-image` build with `SOURCE_DATE_EPOCH` set and
  `rewrite-timestamp=true`, so file timestamps inside the layers no longer depend on the
  checkout.
- A cache-bust knob exists so the `apk add` layer can pick up security fixes
  (see [Security](image-cache-overview.md#security)).

## Edge cases

- **`DOCKER_VERSION` bump.** Changes the base image, so every layer is rebuilt and gets new
  digests. Expected; not a failure of reproducibility.
- **`apk` layer.** `apk add --no-cache bash` downloads whatever the index serves at build time;
  a new `bash` package or index changes the layer even with a fixed `SOURCE_DATE_EPOCH`.
- **Cache-bust use.** Using the knob rebuilds the `apk` layer and every later layer; their
  digests change.
- **Shallow or detached checkout.** `git log -1` works on CircleCI's checkout of a tag; the
  script fails clearly if `git` metadata is missing rather than building with a random epoch.

## Acceptance criteria

- Two builds of the same commit produce identical layer digests.
- After a `cli/`-only change, only the last layer (`COPY build/vault`) differs.
- `make test-image` and `make test-cli-e2e` stay green.
- The cache-bust knob is documented where it is used.

## Open decisions

| Decision | Options / notes |
|----------|-----------------|
| Minimum buildx / BuildKit version | `rewrite-timestamp` needs a recent BuildKit; check whether the CircleCI `machine` image (`ubuntu-2404:current`) and the `docker-container` builder have it, or pin one. |
| Deterministic `apk` layer | Pin the `bash` version, accept index drift, or another approach found while prototyping. |
| Form of the cache-bust knob | A build arg (e.g. a date or counter) vs a periodic no-cache rebuild. |
| Digest check in CI | Whether comparing the digests of two builds becomes a script run in CI, or stays a manual check. |
