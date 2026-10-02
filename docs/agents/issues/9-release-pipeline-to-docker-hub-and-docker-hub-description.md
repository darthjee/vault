# Issue: Release pipeline to Docker Hub and Docker Hub description

## Description
Part of epic #2. Implement the tag-triggered CircleCI release pipeline that publishes `darthjee/vault` to Docker Hub, plus the Docker Hub description page. It follows the `navi` project, with the changes recorded in [`docs/agents/specs/docker-image/ci.md`](../specs/docker-image/ci.md). **No tag is pushed as part of this work.** The first release is a separate follow-up, done after epic #2 is finished.

Owning agent: `automation`. Depends on #8 (PR pipeline), which is closed.

## Problem
`make release` and `make update-description` are still the no-op stubs added in #4. `.circleci/config.yml` only has the PR `build-and-test` workflow. Nothing can publish the image or its Docker Hub page yet.

## Expected Behavior
- A release workflow runs only on `X.Y.Z` tags (`branches: ignore: /.*/`), with this chain: `check-version-tag` + `build-and-test` → `build-and-release` → `update-description`.
  - `check-version-tag` runs `make check-version-tag TAG=$CIRCLE_TAG`, which uses `scripts/check_tag_version.sh`.
  - `build-and-test` is the existing PR job, reused unchanged.
  - `build-and-release` runs `make release TAG=$CIRCLE_TAG`. On a single machine, it runs a multi-arch `docker buildx` build with QEMU for `linux/amd64` and `linux/arm64`, and pushes `darthjee/vault:X.Y.Z` and `darthjee/vault:latest`.
  - `update-description` runs `make update-description`, which pushes `DOCKERHUB_DESCRIPTION.md`.
- The credentials `DOCKER_HUB_USERNAME` and `DOCKER_HUB_PASSWORD` come from a **restricted CircleCI context**, not from project env vars. Only `build-and-release` and `update-description` get it. PR jobs never do. The context is named `docker-hub`. This name is recorded in `ci.md → Credentials`.
- `make release` with no `TAG` fails fast, before any build.
- `DOCKERHUB_DESCRIPTION.md` covers four things:
  - what Vault is;
  - how to run it, with Sysbox recommended and `--privileged` as the fallback;
  - the Vault env vars;
  - a pointer to the README Security section, which #10 writes.

## Solution
- The CircleCI YAML only sets up executors, contexts and filters, and calls make targets. Docker jobs use `machine: image: ubuntu-2404:current`.
- CI-only steps live in `scripts/ci/*.sh`: buildx/QEMU setup, `docker login`, and fetching and running `docker_hub.sh`.
- `make update-description` calls a `scripts/ci/` wrapper. The wrapper fetches `darthjee/scripts`' `docker_hub.sh` at a pinned tag or commit and runs it. Nothing from `darthjee/scripts` is copied into this repo.
- Manual prerequisites, done by a maintainer outside any PR: the Docker Hub repo `darthjee/vault` exists, and the restricted CircleCI context `docker-hub` with the two credentials exists.

### Done when
- `circleci config validate` passes.
- `make release` without `TAG` fails fast.
- A local buildx build of both platforms works without pushing.

## Benefits
Tagging a version publishes a tested, multi-arch image and keeps the Docker Hub page in sync. The credentials are only exposed to the jobs that need them.
