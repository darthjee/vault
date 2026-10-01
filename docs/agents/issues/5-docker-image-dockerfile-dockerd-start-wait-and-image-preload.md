# Issue: Docker image: Dockerfile, dockerd start/wait and image preload

## Description
Part of epic #2. Build the Vault image and the first half of the entrypoint flow: pre-checks, starting and waiting for the inner `dockerd`, and preloading images. Implements [image.md](../specs/docker-image/image.md): Dockerfile, Base image, Dockerd startup, Entrypoint flow steps 1–4, Exit codes for those steps, and Edge cases 1–5. The spec wins over `AGENTS.md` / `flow.md` where they conflict.

Depends on #4 (scaffolding, merged): `make lint` / `make test` already exist; `make build-image` is still a stub.

## Problem
The image, the entrypoint and their tests do not exist yet (`source/` and `test/` are absent), and the GitHub issue body predates the spec merged in #3, so it misses several decisions (build arg, unix-only host, pre-checks, load-failure cleanup).

## Expected Behavior
- `make build-image` builds the image (passing `--build-arg DOCKER_VERSION` when set).
- Running the image `--privileged` starts dockerd on the unix socket only, waits for it, and preloads `/vault/images/*.tar`; the compose step is a placeholder for #6.
- Fails fast with clear messages on: insufficient privileges, an invalid `VAULT_DOCKERD_TIMEOUT`, a dockerd timeout, or a tarball that fails to load (see image.md → Exit codes and messages).
- `make lint`, `make test` and `make build-image` pass.

## Solution
### Dockerfile
- `ARG DOCKER_VERSION=29.8.2` + `FROM docker:${DOCKER_VERSION}-dind`; `apk add bash`.
- `source/lib/` → `/usr/local/lib/vault/`; `source/bin/entrypoint.sh` → `/usr/local/bin/vault-entrypoint` (the `ENTRYPOINT`).
- `ENV DOCKER_TLS_CERTDIR=""`, `VOLUME /var/lib/docker`, `WORKDIR /vault`, `EXPOSE 80`.

### `source/lib/dockerd.sh`
- Start dockerd in the background through the base image's `dockerd-entrypoint.sh`, **always with `--host=unix:///var/run/docker.sock`** (never TCP).
- Wait for `docker info` with the timeout passed as an argument; on timeout print `dockerd failed to start; are you running with --privileged (or the sysbox runtime)?` and return non-zero.
- Stop dockerd and wait for it to exit.
- **Verify** against `docker:29.8.2-dind` whether an empty `DOCKER_TLS_CERTDIR` makes `dockerd-entrypoint.sh` add `tcp://0.0.0.0:2375`, and record the finding in image.md → Dockerd startup.

### `source/lib/preflight.sh` (flow step 1)
- Validate the timeout (passed as an argument): it must be a positive integer; otherwise fail before starting dockerd with a message naming `VAULT_DOCKERD_TIMEOUT`, the bad value and that a positive integer is expected.
- Privilege probe: `mount -t tmpfs none` on a `mktemp -d` directory, then `umount` it and remove the directory. This works under both `--privileged` and Sysbox. On failure, return non-zero with the `--privileged` / sysbox hint; the entrypoint exits 1 before starting dockerd. Record the chosen probe in image.md.

### `source/lib/images.sh`
- `docker load -i` every `*.tar` in a directory passed as an argument.
- Missing directory or no tarballs → skip silently.
- A load error → return non-zero with a message naming the file; the entrypoint then stops dockerd and exits non-zero.

### `source/bin/entrypoint.sh` (skeleton)
- The only place that reads the environment: `VAULT_DOCKERD_TIMEOUT` (default `30`).
- Sources the libraries, runs pre-checks → start dockerd → wait → preload `/vault/images`. Compose run and exit-code passthrough are placeholders for #6.
- **No signal trap in #5**: #6 installs the SIGTERM / SIGINT trap before the pre-checks (edge cases 7–8).
- Every Vault-side failure in #5 exits with **1**; the message tells the failures apart. Record this in image.md → Exit codes and messages.

### Tests and tooling
- bats: `test/lib/preflight.bats`, `test/lib/dockerd.bats`, `test/lib/images.bats`, with `docker` / `dockerd` / `mount` stubbed; covering edge cases 1–5.
- `make build-image`: replace the #4 stub with a real `docker build`.

### Conventions
Libraries only define functions (no side effects when sourced); only the entrypoint reads the environment; functions are prefixed with their module name. See `docs/agents/contributing.md`. Any deviation from the spec updates the spec in the same PR.

### Owner
`dev` (Dockerfile, `source/`, `test/`); the `build-image` Makefile recipe is in `automation`'s scope.

## Benefits
- A buildable image and a tested startup path that #6 (compose run / signals) and #7 (smoke test) build on.
- The security-relevant unix-only daemon decision is implemented and verified early.
