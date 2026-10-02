# Plan: Release pipeline to Docker Hub and Docker Hub description

Issue: [9-release-pipeline-to-docker-hub-and-docker-hub-description.md](../../issues/9-release-pipeline-to-docker-hub-and-docker-hub-description.md)

## Overview
Replace the `release` and `update-description` Makefile stubs with real implementations, backed by `scripts/release.sh` and `scripts/ci/*.sh` wrappers. Add a tag-only `release` workflow to `.circleci/config.yml` and write `DOCKERHUB_DESCRIPTION.md`. Record the credentials context and the `docker_hub.sh` source in the CI spec. No tag is pushed.

## Agents involved

- [automation](automation.md)
- [product-owner](product-owner.md)

## Shared contracts

| Item | Value |
|------|-------|
| CircleCI context | `docker-hub` (restricted), holding `DOCKER_HUB_USERNAME` and `DOCKER_HUB_PASSWORD`. Attached only to `build-and-release` and `update-description`. |
| `docker_hub.sh` source | `https://raw.githubusercontent.com/darthjee/docker/91b11fb949bb0f71670e390fdc97df831c46af70/scripts/0.9.0/home/sbin/docker_hub.sh`. It ships in the `darthjee/scripts` image but lives in the `darthjee/docker` repo. |
| `docker_hub.sh` sha256 | `cd0cb716f77443a2a806a85599adf270e4ab3e60a74411bafe023f6b3fd1c66a` |
| Release tag filter | `/^[0-9]+\.[0-9]+\.[0-9]+$/`, with `branches: ignore: /.*/` |
| Pushed tags | `darthjee/vault:X.Y.Z` and `darthjee/vault:latest`, for `linux/amd64,linux/arm64` |
| CI-only make target | `ci-release-setup`: QEMU/binfmt plus a buildx builder, then `docker login`. |
