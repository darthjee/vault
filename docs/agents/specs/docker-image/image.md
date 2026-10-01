# Docker Image Spec: Image and Entrypoint

Part of the [Docker image spec](overview.md). Implemented by #5 and #6; edge cases 9–10 documented by #10.

## Baseline

See [architecture.md → Image](../../architecture.md#image) for the image layout and [flow.md](../../flow.md) for the runtime flow. Everything there still applies, except where this file says otherwise.

## Dockerfile

See [architecture.md → Image](../../architecture.md#image); in addition:

- The base image comes from a build arg (see [Base image](#base-image)):

  ```dockerfile
  ARG DOCKER_VERSION=29.8.2
  FROM docker:${DOCKER_VERSION}-dind
  ```

- Install paths are a shared contract ([overview.md → Image paths](overview.md#image-paths)): libraries in `/usr/local/lib/vault/`, the entrypoint at `/usr/local/bin/vault-entrypoint` (the image `ENTRYPOINT`), `WORKDIR /vault`, preload directory `/vault/images`.
- `ENV DOCKER_TLS_CERTDIR=""`, `VOLUME /var/lib/docker` and `EXPOSE 80` are unchanged.

## Base image

| Item | Decision |
|------|----------|
| Pin | `docker:29.8.2-dind`, latest stable as of 2026-10-01. Pinned by tag, no digest. |
| Override | `ARG DOCKER_VERSION` so the Makefile and CI can pass `--build-arg DOCKER_VERSION=…`. |
| Rejected | `-dind-rootless` variant; an `-alpine3.x` suffix; a minor-line tag (e.g. `29.8-dind`); Renovate / Dependabot (future work). |

**Bump procedure** (manual):

1. Change the `ARG DOCKER_VERSION` default in the `Dockerfile`.
2. Run `make lint`, `make test` and `make test-image`.
3. Re-check the dind TCP-host behaviour (see [Dockerd startup](#dockerd-startup)); the smoke test's port 2375 assertion must still pass.
4. Release a new version ([ci.md → Release pipeline](ci.md#release-pipeline)).

## Dockerd startup

See [flow.md](../../flow.md) step 1; **instead:**

- `dockerd` is always started with an explicit `--host=unix:///var/run/docker.sock`. It never listens on TCP.
- Reason: with an empty `DOCKER_TLS_CERTDIR`, the dind `dockerd-entrypoint.sh` is believed to add an unauthenticated `tcp://0.0.0.0:2375` host. **To be verified** by #5 against the pinned version; #7 asserts that nothing listens on 2375.

## Entrypoint flow

Changes compared with [flow.md](../../flow.md). The SIGTERM / SIGINT trap is installed before step 1, so a signal at any point is handled (see [Edge cases](#edge-cases) 7–8).

| Step | Behaviour | Change vs flow.md | Issue |
|------|-----------|-------------------|-------|
| 1. Pre-checks | Validate `VAULT_DOCKERD_TIMEOUT` (positive integer). Run a fast privilege probe: a harmless privileged operation (e.g. mounting a tmpfs) that succeeds under both `--privileged` and Sysbox. The exact probe is **to be decided** by #5. | New | #5 |
| 2. Start dockerd | Background, with explicit unix `--host` ([Dockerd startup](#dockerd-startup)). | Changed | #5 |
| 3. Wait for dockerd | Poll `docker info` up to `VAULT_DOCKERD_TIMEOUT` seconds. | Unchanged | #5 |
| 4. Preload images | `docker load -i` each `/vault/images/*.tar`. | Unchanged | #5 |
| 5. Run compose | No args → `docker compose up "${COMPOSE_UP_ARGS[@]}"`; args → `docker compose "$@"`. `COMPOSE_UP_ARGS` is split on whitespace with `read -ra`, **no quoting support** (documented in the README). | Clarified | #6 |
| 6a. Compose exits on its own (`up` or passthrough) | Stop dockerd only. **No `compose down`.** | Changed | #6 |
| 6b. SIGTERM / SIGINT | `docker compose down`, then stop dockerd and wait for it. | Unchanged | #6 |
| 7. Exit | With compose's exit code, on both 6a and 6b. | Clarified for 6b | #6 |

## Exit codes and messages

| Situation | Exit code | Message |
|-----------|-----------|---------|
| Compose exits on its own | compose's exit code | compose's own output |
| SIGTERM / SIGINT after compose started | compose's exit code (0 on a clean `docker stop`, asserted by #7) | — |
| Privilege probe fails | non-zero | Hint naming `--privileged` and the sysbox runtime (same hint as the dockerd timeout). |
| Invalid `VAULT_DOCKERD_TIMEOUT` | non-zero | States the variable, the bad value and that a positive integer is expected. |
| dockerd timeout | non-zero | `dockerd failed to start; are you running with --privileged (or the sysbox runtime)?` |
| Tarball load fails | non-zero | Names the failing file. |
| Signal before compose started | #6 decides and records it here | — |

Exact non-zero values are left to #5 / #6.

## Edge cases

| # | Case | Behaviour | Implemented in | Covered by |
|---|------|-----------|----------------|------------|
| 1 | Not enough privileges | Fast pre-check before dockerd fails; exit immediately with the `--privileged` / sysbox hint. The probe must succeed under both `--privileged` and Sysbox. | #5 | bats (#5), probe stubbed; smoke test (#7) covers the `--privileged` success path |
| 2 | `VAULT_DOCKERD_TIMEOUT` is not a positive integer | Fail fast before starting dockerd, with a clear message. | #5 | bats (#5) |
| 3 | `dockerd` not ready within the timeout | Print `dockerd failed to start; are you running with --privileged (or the sysbox runtime)?` and exit non-zero. | #5 | bats (#5), `docker info` stubbed |
| 4 | `/vault/images` missing or has no `*.tar` | Skip silently. | #5 | bats (#5); smoke test (#7) runs without tarballs |
| 5 | A tarball fails to load | Stop dockerd and exit non-zero; the message names the file. | #5 | bats (#5) |
| 6 | No compose file in `/vault` | No pre-check: compose prints its own error, then Vault stops dockerd and exits with compose's exit code. | #6 | bats (#6) |
| 7 | A signal arrives before compose has started | Stop dockerd and exit. | #6 | bats (#6) |
| 8 | A second signal arrives during shutdown | Ignored; the shutdown already in progress continues. | #6 | bats (#6) |
| 9 | `compose down` takes longer than `docker stop`'s 10s grace period | Documentation only: recommend `docker stop -t` / `--stop-timeout`. | #10 | documentation only |
| 10 | Two containers share one `/var/lib/docker` volume | Documentation only: not detected. | #10 | documentation only |

## Runtime privileges

See [architecture.md → Runtime requirements](../../architecture.md#runtime-requirements); in addition:

| Topic | Decision |
|-------|----------|
| Supported runtimes | `--runtime=sysbox-runc` (recommended) and `--privileged` (fallback). |
| Unsupported | Rootless; hand-picked capabilities (`--cap-add`); mounting the host's `docker.sock`. |
| Host must provide | cgroup nesting; a volume on `/var/lib/docker` (guaranteed by `VOLUME`); one published port. |
| Where it runs | Docker Desktop and Linux hosts. **Not** most managed platforms (ECS Fargate, Cloud Run, Kubernetes without privileged pods). |
| Sysbox | Supported, checked manually. CI smoke-tests only `--privileged`; Sysbox in CI is future work. |

## Security and performance

| Topic | Decision |
|-------|----------|
| Inner daemon | Unix socket only ([Dockerd startup](#dockerd-startup)); #7 asserts nothing listens on 2375. |
| Root inside the container | Documented in the README Security section. Vulnerability scanning is future work. |
| Pinning | All images pinned by tag, no digest. |
| Startup time | Mitigated by a named volume on `/var/lib/docker` (image cache survives restarts) or by preloading tarballs into `/vault/images`. |
| Storage driver | overlay2, on the declared `/var/lib/docker` volume. |
