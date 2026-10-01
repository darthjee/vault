# Plan: Docker image: Dockerfile, dockerd start/wait and image preload

Issue: [5-docker-image-dockerfile-dockerd-start-wait-and-image-preload.md](../../issues/5-docker-image-dockerfile-dockerd-start-wait-and-image-preload.md)

## Overview
Build the Vault image and the first half of the entrypoint: pre-checks (timeout validation and a tmpfs privilege probe), starting dockerd on the unix socket only, waiting for it, and preloading `/vault/images/*.tar`. `dev` writes the Dockerfile, three libraries (`preflight.sh`, `dockerd.sh`, `images.sh`), a skeleton entrypoint and their bats tests. `automation` replaces the `make build-image` stub with a real build. Compose, signals and exit-code passthrough stay with #6.

## Agents involved

- [dev](dev.md)
- [automation](automation.md)

## Shared contracts

| Item | Value |
|------|-------|
| Dockerfile location | Repo root (`./Dockerfile`); build context `.` |
| Base image build arg | `ARG DOCKER_VERSION=29.8.2` declared before `FROM docker:${DOCKER_VERSION}-dind` |
| `make build-image` | `docker build`, adding `--build-arg DOCKER_VERSION=$(DOCKER_VERSION)` only when `DOCKER_VERSION` is set, tagged `$(IMAGE)` |
| `IMAGE` (new Makefile variable) | `?= darthjee/vault:dev`; local tag reused by #7's smoke test. Record it in the spec (overview.md and tooling.md variable tables). |
| Exit code | Every Vault-side failure in #5 exits **1**. |
