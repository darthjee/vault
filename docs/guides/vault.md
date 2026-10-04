# Vault

> Copy the whole `docs/guides/` tree (`vault.md` and `vault/`) into your repository, not
> single pages: the pages link to each other with relative links.
> The originals live in the
> [Vault repository](https://github.com/darthjee/vault/tree/main/docs/guides).

**Vault version:** 0.0.1

## What Vault is

Vault is a Docker-in-Docker image that runs a `docker compose` stack inside a single
container. An application and its dependencies (database, cache, ...) ship as one stand-alone
image that exposes one port.

```
host --(-p 8080:80)--> Vault container (dockerd + compose)
                         |-- app  (ports: ["80:3000"])
                         `-- db   (no published ports)
```

On boot, Vault starts its own Docker daemon, optionally preloads image tarballs, runs
`docker compose` from `/vault`, and exits with compose's exit code. Images are published on
Docker Hub as [`darthjee/vault`](https://hub.docker.com/r/darthjee/vault).

## When to use it

| Use Vault when | Do not use Vault when |
|----------------|-----------------------|
| You want to ship an app and its dependencies as **one image** exposing **one port**. | The target platform refuses privileged containers (ECS Fargate, Cloud Run, Kubernetes without privileged pods); see [security.md](vault/security.md). |
| The host runs Docker with the Sysbox runtime, or accepts `--privileged`. | You only have rootless Docker, or can only grant hand-picked capabilities (`--cap-add`). |
| You want the stack to behave the same on every host, with no compose install on the host. | You want to drive the host's Docker daemon (mounting the host's `docker.sock` is unsupported). |

## Choosing a path

### Image directly or the `vault` CLI

| Path | When | Guide |
|------|------|-------|
| The image directly (`docker run`) | You want full control of the `docker run` flags, or run Vault from another tool. | [docker-run.md](vault/docker-run.md) |
| The `vault` CLI | You want named instances, runtime auto-detection (Sysbox, else `--privileged`), `.vaultrc` and guardrails. | `vault/cli.md` (not written yet) |

### Image as is or as a base image

| Path | How | Guide |
|------|-----|-------|
| Image as is | Mount your compose project at `/vault`. | [docker-run.md](vault/docker-run.md) |
| Base image | `FROM darthjee/vault:<version>` + `COPY . /vault`, then ship the derived image. | [base-image.md](vault/base-image.md) |

Read [concepts.md](vault/concepts.md) first either way: it explains `/vault`, ports, bind
mounts and persistence.

## Page index

| Page | Contents |
|------|----------|
| [concepts.md](vault/concepts.md) | Docker-in-Docker, `/vault`, port flow, bind mounts, persistence, startup sequence. |
| [security.md](vault/security.md) | `--privileged` risks, Sysbox, root, Docker sockets, secrets, supported runtimes and platforms. |
| [docker-run.md](vault/docker-run.md) | Running the image directly: runtime, `/vault` mount, data volume, ports, env vars, compose arguments, stopping. |
| [base-image.md](vault/base-image.md) | Shipping a stack as its own image: Dockerfile, offline preload, running the baked image, secrets. |
