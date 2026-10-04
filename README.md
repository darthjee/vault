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

## Quick start

The examples use the published `darthjee/vault` image.

Run a compose project directly, with the [Sysbox](https://github.com/nestybox/sysbox)
runtime:

```bash
docker run --runtime=sysbox-runc \
  -v "$PWD/my-stack:/vault" \
  -v vault-data:/var/lib/docker \
  -p 8080:80 \
  darthjee/vault
```

Or let the `vault` CLI build that command for you
([install it](docs/guides/vault/cli.md#install) first):

```bash
cd my-stack
vault up
```

## Documentation

Detailed usage lives in the [Vault guides](docs/guides/vault.md): running the image
directly or as a base image, the `vault` CLI, configuration, operations,
troubleshooting and examples. The guides are self-contained, so they can be copied
into other repositories.

## Security

Running a Docker daemon inside a container needs elevated privileges.

- **Prefer Sysbox** (`--runtime=sysbox-runc`): root inside the container is not
  root on the host.
- **`--privileged` is the fallback, and it is dangerous:** it disables most of the
  isolation between the container and the host.
- **Unsupported:** rootless Docker, hand-picked capabilities (`--cap-add`) and
  mounting the host's `docker.sock`.
- **The inner Docker socket is never exposed over TCP.**

Read [Security](docs/guides/vault/security.md) for the details and the supported
runtimes and platforms.

## Development

Requirements: Docker and Make. Lint and unit tests run in pinned tool images.

```bash
make bundle-cli    # bundle cli/ into build/vault
make build-image   # bundle the CLI, then build darthjee/vault:dev
make lint          # shellcheck
make test          # bats unit tests (CLI tests also run under bash 3.2)
make test-docs     # check links in docs/guides/
make test-image    # build, then smoke-test the image (needs Docker with --privileged)
make test-cli-e2e  # build, then drive a real instance with build/vault and test install.sh
```

Contributor and agent documentation lives in [AGENTS.md](AGENTS.md) and
[`docs/agents/`](docs/agents/).

## License

See [LICENSE](LICENSE).
