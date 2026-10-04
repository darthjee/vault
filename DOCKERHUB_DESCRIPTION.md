# Vault

Vault is a Docker-in-Docker image that runs a `docker compose` stack inside a
single container. An application and its dependencies (database, cache, ...)
ship as one stand-alone image that exposes one port.

```
host --(-p 8080:80)--> Vault container (dockerd + compose)
                         |-- app  (ports: ["80:3000"])
                         `-- db   (no published ports)
```

Source and documentation: https://github.com/darthjee/vault

## How to run

Mount your compose project at `/vault` and publish the port your app binds
inside the container.

Recommended, with the [Sysbox](https://github.com/nestybox/sysbox) runtime:

```bash
docker run --runtime=sysbox-runc \
  -v "$PWD/my-stack:/vault" \
  -p 8080:80 \
  darthjee/vault
```

Fallback, with `--privileged`:

```bash
docker run --privileged \
  -v "$PWD/my-stack:/vault" \
  -p 8080:80 \
  darthjee/vault
```

- `/vault` holds `docker-compose.yml` (and anything it builds from).
- `/vault/images/*.tar` (optional) are loaded with `docker load` before
  compose starts, so the stack can run without pulling.
- With no arguments the container runs `docker compose up`. Any arguments
  are passed to `docker compose` instead, e.g. `darthjee/vault ps`.
- Mount a named volume at `/var/lib/docker` to keep pulled images and inner
  volumes across restarts.
- The container exits with compose's exit code. SIGTERM / SIGINT run
  `docker compose down` and stop the inner daemon cleanly.

## CLI

The `vault` CLI runs Vault containers for you: it sets up the mounts, the
data volume and the port, and uses Sysbox when it is detected (otherwise it
falls back to `--privileged` with a warning).

Install it (needs Docker, never `sudo`):

```bash
curl -fsSL https://github.com/darthjee/vault/releases/latest/download/install.sh | bash
```

It installs into `~/.local/bin` and uses the image of the same version;
`VAULT_VERSION=X.Y.Z` pins one.

Quick start:

```bash
vault up       # detached, default port 3000:80
vault status
vault down
```

The CLI supports Linux and macOS (bash 3.2+), not Windows. Full docs:
https://github.com/darthjee/vault#cli

## Environment variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `VAULT_DOCKERD_TIMEOUT` | `30` | Seconds to wait for the inner `dockerd` to start. |
| `COMPOSE_UP_ARGS` | empty | Extra args for the default `up`, e.g. `--abort-on-container-exit`. |

Standard compose variables such as `COMPOSE_FILE` and `COMPOSE_PROJECT_NAME`
work as usual.

## Security

Warning: `--privileged` gives the container full access to the host; prefer
the Sysbox runtime. See the
[Security section of the README](https://github.com/darthjee/vault#security).

## Supported platforms

- `linux/amd64`
- `linux/arm64`
