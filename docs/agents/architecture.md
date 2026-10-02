# Architecture

## Overview

Vault is a Docker-in-Docker image. Its container runs an inner `dockerd` and a
`docker compose` stack described by files mounted into (or copied to) `/vault`.
The outer container exposes one port; inside it, the application and its
dependencies (database, cache, ...) run as ordinary compose services.

```
host ──-p 8080:80──▶ Vault container (dockerd + compose)
                        ├── app   (ports: ["80:3000"])
                        └── db    (no published ports)
```

## Image

- Base: `docker:29.8.2-dind` (Alpine), which ships `dockerd`, the docker CLI and the compose / buildx plugins. Overridable with the `DOCKER_VERSION` build arg (`make build-image DOCKER_VERSION=X.Y.Z`).
- All images (base, shellcheck, bats, smoke-test fixture) are pinned by tag, not by digest.
- `bash` added via `apk`.
- `ENV DOCKER_TLS_CERTDIR=""`.
- `VOLUME /var/lib/docker` (required: overlay2 cannot run on top of the container's overlay filesystem).
- `WORKDIR /vault`, `EXPOSE 80` (convention only).
- Built for `linux/amd64` and `linux/arm64` by the release.

### Image paths

| Path | Contents |
|------|----------|
| `/usr/local/lib/vault/` | Libraries from `source/lib/`. |
| `/usr/local/bin/vault-entrypoint` | `source/bin/entrypoint.sh`; the image `ENTRYPOINT`. |
| `/vault` | `WORKDIR`; compose file(s) and their files. |
| `/vault/images` | Optional `*.tar` images preloaded before compose starts. |

## Source Code Layout

All code installed into the image lives under `source/`.

### `source/bin/`

`entrypoint.sh` — the only script. Reads the environment (`COMPOSE_UP_ARGS`,
`VAULT_DOCKERD_TIMEOUT`), sources the libraries and orchestrates the flow
described in [flow.md](flow.md).

### `source/lib/`

Function libraries; sourcing them has no side effects.

| File | Responsibility |
|------|----------------|
| `preflight.sh` | Fast checks before dockerd starts: validate the timeout (positive integer), tmpfs mount probe for privileges. |
| `dockerd.sh` | Start `dockerd` (via the base image's `dockerd-entrypoint.sh`) with an explicit `--host=unix:///var/run/docker.sock`, wait for it with a timeout, stop it. |
| `images.sh` | `docker load` every tarball in a given directory. |
| `compose.sh` | Run the `docker compose` command in the background (default `up` + extra args, or passthrough args), wait on it, and provide `down`. No `down` when compose exits on its own; `down` runs only on the signal path. |
| `signals.sh` | Trap SIGTERM / SIGINT and run the shutdown sequence (`compose down`, then stop dockerd). |

## Configuration

| Variable | Owner | Default | Purpose |
|----------|-------|---------|---------|
| `COMPOSE_FILE` | compose | `docker-compose.yml` in `/vault` | Compose file(s), `:`-separated. |
| `COMPOSE_PROJECT_NAME` | compose | `vault` (dir name) | Project name. |
| `COMPOSE_UP_ARGS` | Vault | empty | Extra args for the default `up` (e.g. `--abort-on-container-exit`, `--pull never`). Split on whitespace (`read -ra`), **no quoting support**. |
| `VAULT_DOCKERD_TIMEOUT` | Vault | `30` | Seconds to wait for `dockerd`. Must be a positive integer; otherwise Vault fails fast before starting dockerd. |

## Runtime requirements

| Topic | Decision |
|-------|----------|
| Supported runtimes | Sysbox, `--runtime=sysbox-runc` (recommended); `--privileged` (fallback). |
| Unsupported | Rootless; hand-picked capabilities (`--cap-add`); mounting the host's `docker.sock`. |
| Host must provide | cgroup nesting; a volume on `/var/lib/docker` (guaranteed by `VOLUME`); one published port. |
| Where it runs | Docker Desktop and Linux hosts. **Not** most managed platforms (ECS Fargate, Cloud Run, Kubernetes without privileged pods). |
| CI coverage | The smoke test runs only `--privileged`; Sysbox is checked manually. |

See the [README Security section](../../README.md#security) for the risks of `--privileged`.

## Security

- The inner daemon listens on the unix socket only; it never listens on TCP. The smoke test asserts that nothing listens on 2375.
- The container runs as root; see the [README Security section](../../README.md#security).

## Testing

| Layer | Command | Covers |
|-------|---------|--------|
| Lint | `make lint` | shellcheck over every `*.sh` / `*.bats` under `source/`, `scripts/` and `test/`. |
| Unit | `make test` | bats tests (`test/lib/*.bats`) over the `source/lib/` functions, with external commands (`docker`, `mount`, ...) stubbed. |
| Smoke | `make test-image` | `scripts/test_image.sh` with the fixture `test/fixture/docker-compose.yml`: build the image, run it `--privileged`, `curl` the published port, assert no listener on 2375, `docker stop` and expect exit 0, then always clean up. |

Not covered by CI: Sysbox at runtime and arm64 at runtime (built by the release, not run).
