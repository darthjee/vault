# Plan: Reorder Dockerfile layers by change frequency

Issue: [68-reorder-dockerfile-layers-by-change-frequency.md](../../issues/68-reorder-dockerfile-layers-by-change-frequency.md)

## Overview
Reorder the `Dockerfile` instructions to the spec's target order so that a release that only changes the CLI bundle rebuilds only the `COPY build/vault` layer. Contents, modes, owners and runtime behaviour stay identical.

## Context
Today `COPY --chmod=755 build/vault` (changes every release, since the bundle embeds the version) sits before `vault-install`, the share-directory `mkdir` and the completion copy, so those layers are invalidated on every CLI change. The target order is fixed in [image-cache-dockerfile.md](../../specs/image-cache-dockerfile.md) (approach D of epic #65); #69 and #70 build on it.

## Implementation Steps

### Step 1 — Reorder the Dockerfile
Rewrite the instruction order to exactly:

1. `ARG DOCKER_VERSION=...` / `FROM docker:${DOCKER_VERSION}-dind`
2. `RUN apk add --no-cache bash`
3. The existing comment (`# Created first: COPY --chmod would also apply 644 to the directories it creates.`) followed by `RUN mkdir -p -m 0755 /usr/local/share/vault /usr/local/share/vault/completion`
4. `COPY --chmod=644 cli/completion/vault.bash cli/completion/_vault /usr/local/share/vault/completion/`
5. `COPY source/lib/ /usr/local/lib/vault/`
6. `COPY --chmod=755 source/bin/entrypoint.sh /usr/local/bin/vault-entrypoint`
7. `COPY --chmod=755 source/bin/install.sh /usr/local/bin/vault-install`
8. `COPY --chmod=755 build/vault /usr/local/bin/vault`
9. `ENV DOCKER_TLS_CERTDIR=""`, `VOLUME /var/lib/docker`, `WORKDIR /vault`, `EXPOSE 80`, `ENTRYPOINT ["/usr/local/bin/vault-entrypoint"]` — unchanged

Do not change any instruction's arguments, `--chmod` value, source or destination — only their order. The `mkdir` must stay before the completion `COPY --chmod=644`.

### Step 2 — Verify
- Run `make test-image` and `make test-cli-e2e`; both must pass (they check the installed files, modes and runtime behaviour).
- Manual cache check (no new automated test): with a warm cache, touch a file under `cli/lib/` (or `cli/bin/vault`), run `make build-image` again, and confirm only the `COPY build/vault` step is rebuilt while every earlier step is reported `CACHED`. Revert the touch and include the relevant build output in the PR description.

## Files to Change
- `Dockerfile` — reorder instructions as above; no other change.

## CI Checks
- `Dockerfile`: `make test-image` and `make test-cli-e2e` (CI job: `build-and-test`)

## Notes
- The reorder changes every layer digest after the base once; this is expected (see the spec's backward-compatibility section).
- A `DOCKER_VERSION` bump still rebuilds every layer; out of scope.
- Changes under `cli/completion/` rebuild from step 4 onwards; that is accepted, since completions change rarely.
