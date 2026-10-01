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

- Base: pinned `docker:<version>-dind` (Alpine), which ships `dockerd`, the docker CLI and the compose / buildx plugins.
- `bash` added via `apk`.
- `source/lib/` installed to `/usr/local/lib/vault/`, `source/bin/entrypoint.sh` to `/usr/local/bin/vault-entrypoint`.
- `ENV DOCKER_TLS_CERTDIR=""` — the inner daemon is only reached through its unix socket.
- `VOLUME /var/lib/docker` (required: overlay2 cannot run on top of the container's overlay filesystem).
- `WORKDIR /vault`, `EXPOSE 80` (convention only).
- Built for `linux/amd64` and `linux/arm64`.

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
| `dockerd.sh` | Start `dockerd` (via the base image's `dockerd-entrypoint.sh`), wait for it with a timeout, stop it. |
| `images.sh` | `docker load` every tarball in a given directory. |
| `compose.sh` | Build and run the `docker compose` command (default `up` + extra args, or passthrough args); `down` on shutdown. |
| `signals.sh` | Trap SIGTERM / SIGINT and run the shutdown sequence. |

## Configuration

| Variable | Owner | Default | Purpose |
|----------|-------|---------|---------|
| `COMPOSE_FILE` | compose | `docker-compose.yml` in `/vault` | Compose file(s), `:`-separated. |
| `COMPOSE_PROJECT_NAME` | compose | `vault` (dir name) | Project name. |
| `COMPOSE_UP_ARGS` | Vault | empty | Extra args for the default `up` (e.g. `--abort-on-container-exit`, `--pull never`). |
| `VAULT_DOCKERD_TIMEOUT` | Vault | `30` | Seconds to wait for `dockerd`. |

## Runtime requirements

Run with `--privileged`, or with the Sysbox runtime (`--runtime=sysbox-runc`).
See the README Security section for the risks of `--privileged`.
