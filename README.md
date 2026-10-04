# vault

[![Build Status](https://circleci.com/gh/darthjee/vault.svg?style=shield)](https://circleci.com/gh/darthjee/vault)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/02d1416cf9bf43478c2b66d09361158a)](https://app.codacy.com/gh/darthjee/vault/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)

**Current Version:** 0.0.1

Vault is a Docker-in-Docker image that runs a `docker compose` stack inside a
single container. An application and its dependencies (database, cache, ...)
ship as one stand-alone image that exposes one port.

```
host --(-p 8080:80)--> Vault container (dockerd + compose)
                         |-- app  (ports: ["80:3000"])
                         `-- db   (no published ports)
```

On boot, Vault starts its own Docker daemon, optionally preloads image tarballs,
runs `docker compose` from `/vault`, and exits with compose's exit code.

Images are published on Docker Hub as
[`darthjee/vault`](https://hub.docker.com/r/darthjee/vault).

## Install

The `vault` CLI is installed with a one-liner:

```bash
curl -fsSL https://github.com/darthjee/vault/releases/latest/download/install.sh | bash
```

> The release URL works once `install.sh` is published as a release asset
> (#28). Until then, run `install.sh` from a checkout of this repository.

The installer needs Docker and never runs `sudo`. It pulls
`darthjee/vault:<version>` and copies the CLI out of that image, so the CLI
always matches the image version. By default it installs:

- the CLI into `~/.local/bin/vault`;
- the shell completions into `~/.local/share/vault/completion/`.

Running it again upgrades the CLI in place.

### Installer variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `VAULT_VERSION` | the release's version | Version of the CLI (and image) to install. |
| `VAULT_INSTALL_DIR` | `$HOME/.local/bin` | Where the `vault` CLI is installed. |
| `VAULT_IMAGE` | `darthjee/vault:$VAULT_VERSION` | Image the CLI is copied from. |

Pin a version:

```bash
curl -fsSL https://github.com/darthjee/vault/releases/latest/download/install.sh \
  | VAULT_VERSION=0.0.1 bash
```

### Completion and PATH

Enable completion in your shell:

```bash
# bash (~/.bashrc)
source ~/.local/share/vault/completion/vault.bash

# zsh (~/.zshrc, before compinit)
fpath=(~/.local/share/vault/completion $fpath)
```

If the install dir is not in `PATH`, the installer warns and prints the line
to add, e.g. `export PATH="$HOME/.local/bin:$PATH"`. The install still
succeeds.

### Integrity

Release tags are not immutable, and `curl | bash` runs whatever the URL
serves. To verify the download, fetch `install.sh` first and check it
against the release's `SHA256SUMS` (#28) before running it.

## Usage

### Running

Mount your compose project at `/vault` and publish the port your app binds
inside the container.

Recommended, with the [Sysbox](https://github.com/nestybox/sysbox) runtime:

```bash
docker run --runtime=sysbox-runc \
  -v "$PWD/my-stack:/vault" \
  -v vault-data:/var/lib/docker \
  -p 8080:80 \
  darthjee/vault
```

Fallback, with `--privileged` (read [Security](#security) first):

```bash
docker run --privileged \
  -v "$PWD/my-stack:/vault" \
  -v vault-data:/var/lib/docker \
  -p 8080:80 \
  darthjee/vault
```

### Shipping a stack as its own image

Instead of mounting the project, bake it into a derived image:

```dockerfile
FROM darthjee/vault
COPY . /vault
```

```bash
docker build -t my-app .
docker run --runtime=sysbox-runc -p 8080:80 my-app
```

### Arguments

With no arguments the container runs `docker compose up` (plus
`COMPOSE_UP_ARGS`). Any arguments are passed to `docker compose` instead:

```bash
docker run --privileged -v "$PWD/my-stack:/vault" darthjee/vault config
docker run --privileged -v "$PWD/my-stack:/vault" darthjee/vault ps
docker run --privileged -v "$PWD/my-stack:/vault" -p 8080:80 darthjee/vault up --build
```

### Ports

An inner service publishes its port inside the Vault container, and you map
that port to the host with `-p`:

```yaml
# /vault/docker-compose.yml
services:
  app:
    image: my-app
    ports: ["80:3000"]   # inner port 3000 -> Vault port 80
  db:
    image: postgres:17   # no published ports
```

```bash
docker run ... -p 8080:80 darthjee/vault   # host 8080 -> Vault 80 -> app 3000
```

The image declares `EXPOSE 80` as a convention only. Databases and other
internal services should not publish ports. Vault has no built-in reverse
proxy.

### Persistence

The image declares `VOLUME /var/lib/docker`. Mount a named volume there to
keep pulled images and inner named volumes (e.g. database data) across
restarts:

```bash
docker run ... -v vault-data:/var/lib/docker darthjee/vault
```

Without it, every start pulls the images again and inner data is lost with
the container.

### Offline preload

Every `/vault/images/*.tar` is loaded with `docker load` before compose
starts, so the stack can run without pulling. Create them with
`docker save -o images/my-app.tar my-app`. A missing `/vault/images` folder
is skipped. To prevent pulls entirely, set `COMPOSE_UP_ARGS="--pull never"`
or use `pull_policy:` in the compose file.

### Bind mounts

Bind mounts in the inner compose file refer to the **Vault container's**
filesystem, not the host's. Anything the inner stack needs must first be
mounted (or copied) into the Vault container, usually under `/vault`.
Relative paths resolve against `/vault`.

## Environment variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `COMPOSE_FILE` | compose default | Compose file(s) to use; a `:`-separated list is allowed. |
| `COMPOSE_PROJECT_NAME` | compose default | Compose project name. |
| `COMPOSE_UP_ARGS` | empty | Extra arguments for the default `up`, e.g. `--abort-on-container-exit` or `--pull never`. Split on whitespace, with **no quoting support**. |
| `VAULT_DOCKERD_TIMEOUT` | `30` | Seconds to wait for the inner `dockerd` to start. Must be a positive integer. |

Any other `COMPOSE_*` variable understood by `docker compose` works as usual.

## Behaviour

- **Exit code:** the container exits with compose's exit code.
- **Service failures:** the container only exits when compose exits.
  Individual service crashes are handled by compose `restart:` policies. To
  fail fast, set `COMPOSE_UP_ARGS="--abort-on-container-exit"`.
- **Shutdown:** SIGTERM / SIGINT (e.g. `docker stop`, Ctrl+C) run
  `docker compose down`, then stop the inner daemon. This can take longer than
  `docker stop`'s default 10s grace period, after which Docker kills the
  container. Give it more time with `docker stop -t 60 <container>`, or
  `docker run --stop-timeout 60 ...`.
- **Do not share `/var/lib/docker`:** never mount the same `/var/lib/docker`
  volume into two running Vault containers. Vault does not detect it, and
  both daemons will corrupt each other's state.
- **Startup errors** (exit code `1`, message on stderr):
  - `dockerd failed to start; are you running with --privileged (or the sysbox runtime)?`
    — the container lacks the privileges Docker-in-Docker needs, or `dockerd`
    did not become ready within `VAULT_DOCKERD_TIMEOUT` seconds.
  - `VAULT_DOCKERD_TIMEOUT must be a positive integer, got: '<value>'`
  - `failed to load image tarball: <file>` — a preload tarball could not be
    loaded.

## Supported runtimes and platforms

- **Supported:** the Sysbox runtime (`--runtime=sysbox-runc`, recommended)
  and `--privileged` (fallback), on Docker Desktop and Linux hosts.
- **Unsupported:** rootless Docker, hand-picked capabilities (`--cap-add`),
  and mounting the host's `docker.sock` instead of running an inner daemon.
- **Managed platforms:** Vault does not run on most of them (ECS Fargate,
  Cloud Run, Kubernetes without privileged pods), since they refuse
  privileged containers.
- **Architectures:** images are published for `linux/amd64` and
  `linux/arm64`.

## Security

Running a Docker daemon inside a container needs elevated privileges. Know
the trade-offs before you deploy Vault.

- **`--privileged` is dangerous.** It disables most of the isolation between
  the container and the host:
  - a process that escapes the container is effectively root on the host;
  - the container gets access to all host devices;
  - seccomp and AppArmor profiles are disabled;
  - most managed platforms refuse privileged containers.
- **Processes run as root** inside the Vault container (the inner daemon
  needs it), and inner containers run under that daemon.
- **Prefer Sysbox.** With `--runtime=sysbox-runc`, the container runs in its
  own user namespace: root inside the container is not root on the host, and
  no `--privileged` flag is needed.
- **The inner Docker socket is never exposed over TCP.** Vault starts
  `dockerd` with an explicit unix `--host` only. Never add a TCP listener or
  publish port 2375: anyone reaching it controls the daemon.
- **Do not mount the host's `docker.sock`** into Vault: it is unsupported and
  hands the host's Docker daemon to the inner stack.

## Development

Requirements: Docker and Make. Lint and unit tests run in pinned tool images.

```bash
make build-image   # build darthjee/vault:dev
make lint          # shellcheck
make test          # bats unit tests
make test-image    # build, then smoke-test the image (needs Docker with --privileged)
```

Contributor and agent documentation lives in [AGENTS.md](AGENTS.md) and
[`docs/agents/`](docs/agents/).

## License

See [LICENSE](LICENSE).
