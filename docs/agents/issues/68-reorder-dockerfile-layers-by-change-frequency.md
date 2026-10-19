# Issue: Reorder Dockerfile layers by change frequency

## Description
Part of epic #65 — reuse unchanged image layers across builds and releases. This is approach **D** of the image-cache spec; the target order is fixed in [docs/agents/specs/image-cache-dockerfile.md](../specs/image-cache-dockerfile.md) (depth: final).

Sequencing: after #66 (spec + scripts agent, done), before #69 (reproducible layers).

## Problem
The current `Dockerfile` copies `build/vault` (the CLI bundle, which embeds the version and changes on every release) before `source/bin/install.sh`, the `mkdir` of `/usr/local/share/vault` and the completion files. Any CLI change therefore invalidates every layer after it, so those layers are rebuilt and re-pushed even when their content is unchanged.

## Expected Behavior
- Layers go from least to most frequently changing; `COPY build/vault` is the last content layer.
- The image's contents, owners, permissions (`755` binaries, `644` completions, `0755` share directories, `source/lib/` as today) and runtime behaviour are unchanged.
- `make test-image` and `make test-cli-e2e` stay green.
- With a warm local cache, a change limited to the CLI bundle (`cli/bin`, `cli/lib`, or `VERSION`) rebuilds only the `COPY build/vault` layer; every earlier layer is reported `CACHED`. This is verified manually: the PR includes the build output of a rebuild after a `cli/lib` change showing the earlier layers as `CACHED` (no new automated test).

## Solution
Reorder the `Dockerfile` to the spec's target order:

1. `ARG DOCKER_VERSION` / `FROM docker:${DOCKER_VERSION}-dind`
2. `RUN apk add --no-cache bash`
3. `RUN mkdir -p -m 0755 /usr/local/share/vault /usr/local/share/vault/completion` (keeping its comment on why it comes before the `COPY --chmod=644`)
4. `COPY --chmod=644 cli/completion/vault.bash cli/completion/_vault /usr/local/share/vault/completion/`
5. `COPY source/lib/ /usr/local/lib/vault/`
6. `COPY --chmod=755 source/bin/entrypoint.sh /usr/local/bin/vault-entrypoint`
7. `COPY --chmod=755 source/bin/install.sh /usr/local/bin/vault-install`
8. `COPY --chmod=755 build/vault /usr/local/bin/vault` — last content layer
9. `ENV`, `VOLUME`, `WORKDIR`, `EXPOSE`, `ENTRYPOINT` — unchanged

Edge cases (from the spec): the `mkdir` must still precede the completion copy; a `DOCKER_VERSION` bump rebuilds everything, as expected; the reorder itself changes every layer digest after the base once.

Responsible agent: `dev`.

## Benefits
Releases that only change the CLI rebuild and push a single small layer instead of five, which is a prerequisite for #69 and #70 to deliver stable digests and useful registry cache hits.
