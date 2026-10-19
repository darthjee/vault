# Image Cache Spec: Dockerfile Layer Order

Part of the image-cache spec; start with [the overview](image-cache-overview.md).
Read by #68. Depth: **final**.

## Goal

Order the `Dockerfile` from least to most frequently changing, so a release that only changes
the CLI rebuilds only the last content layer. This is approach D of the
[decision](image-cache-overview.md#decision).

## Current order

1. `ARG DOCKER_VERSION` / `FROM docker:${DOCKER_VERSION}-dind`
2. `RUN apk add --no-cache bash`
3. `COPY source/lib/`
4. `COPY --chmod=755 source/bin/entrypoint.sh`
5. `COPY --chmod=755 build/vault` — changes every release
6. `COPY --chmod=755 source/bin/install.sh`
7. `RUN mkdir -p -m 0755` of the share directories
8. `COPY --chmod=644` of the completion files
9. Metadata: `ENV`, `VOLUME`, `WORKDIR`, `EXPOSE`, `ENTRYPOINT`

## Target order

| # | Instruction | Installed as |
|---|-------------|--------------|
| 1 | `ARG DOCKER_VERSION` / `FROM docker:${DOCKER_VERSION}-dind` | base |
| 2 | `RUN apk add --no-cache bash` | `bash` |
| 3 | `RUN mkdir -p -m 0755 /usr/local/share/vault /usr/local/share/vault/completion` | share directories |
| 4 | `COPY --chmod=644 cli/completion/vault.bash cli/completion/_vault /usr/local/share/vault/completion/` | completion files |
| 5 | `COPY source/lib/ /usr/local/lib/vault/` | entrypoint libraries |
| 6 | `COPY --chmod=755 source/bin/entrypoint.sh /usr/local/bin/vault-entrypoint` | `vault-entrypoint` |
| 7 | `COPY --chmod=755 source/bin/install.sh /usr/local/bin/vault-install` | `vault-install` |
| 8 | `COPY --chmod=755 build/vault /usr/local/bin/vault` | `vault` — **last content layer** |
| 9 | `ENV`, `VOLUME`, `WORKDIR`, `EXPOSE`, `ENTRYPOINT` | metadata, unchanged in effect |

The comment above the `mkdir` (why the directories are created first) stays with it.

## Permissions that must not change

| Path | Mode |
|------|------|
| `/usr/local/bin/vault`, `/usr/local/bin/vault-entrypoint`, `/usr/local/bin/vault-install` | `755` |
| `/usr/local/share/vault/completion/vault.bash`, `/usr/local/share/vault/completion/_vault` | `644` |
| `/usr/local/share/vault`, `/usr/local/share/vault/completion` | `0755` |
| `/usr/local/lib/vault/` and its files | as today (no `--chmod`) |

## Edge cases

- **`mkdir` before the completion copy.** The `mkdir -p -m 0755` must still precede
  `COPY --chmod=644` into that directory; otherwise `COPY --chmod` would create the directories
  with `644`.
- **`DOCKER_VERSION` bump.** Changes the base, so every layer is rebuilt; the order does not
  help there and does not need to.
- **Digests change once.** The reorder itself changes every layer digest after the base; this is
  expected (see [Backward compatibility](image-cache-overview.md#backward-compatibility)).

## Acceptance criteria

- Image contents (files, modes, owners) and runtime behaviour are unchanged.
- `make test-image` and `make test-cli-e2e` stay green.
- With a warm cache, a `cli/`-only change rebuilds only the `COPY build/vault` layer; every
  earlier layer is reported `CACHED`.
