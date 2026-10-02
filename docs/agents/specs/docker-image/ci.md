# Docker Image Spec: CI and Release

Part of the [Docker image spec](overview.md). Implemented by #8 (PR pipeline) and #9 (release pipeline, credentials, Docker Hub description).

## Baseline

See [`AGENTS.md` → Release (CircleCI)](../../../../AGENTS.md#release-circleci). Everything there still applies, except the credentials ([Credentials](#credentials)); this file adds the decisions below.

## CircleCI principles

- The YAML only sets up executors, contexts and filters, and **calls make targets**. Any logic lives in `scripts/*.sh` or `scripts/ci/*.sh` ([tooling.md → Scripts vs Makefile](tooling.md#scripts-vs-makefile)).
- Jobs that run Docker use a named machine image: `machine: image: ubuntu-2404:current`. The `machine: true` form is deprecated and is not used.
- The PR-side job name (`build-and-test`) and executor are decided by #8 ([PR pipeline](#pr-pipeline)). The remaining YAML (release job details, caching) is left to #9.

## PR pipeline

Runs on every branch and PR (#8).

| Check | Make target |
|-------|-------------|
| Lint | `make lint` |
| Unit tests | `make test` |
| Image build | `make build-image` |
| Smoke test | `make test-image` (`--privileged`, amd64 only) |

#8 implements these checks in `.circleci/config.yml` as a **single `build-and-test` job**, running them in table order: `make lint` → `make test` → `make test-image` (`test-image` depends on `build-image`, so the image build happens there). One workflow runs this job on every branch and PR, with no filters.

The release pipeline's `build-and-test` job (#9) is this same job, reused unchanged.

No credentials are available to these jobs: no `context:` is attached.

## Release pipeline

Runs only on `X.Y.Z` tags (`branches: ignore: /.*/`), implemented by #9.

| Job | Depends on | Does |
|-----|------------|------|
| `check-version-tag` | — | `make check-version-tag TAG=$CIRCLE_TAG`: the tag equals `VERSION` and the README `**Current Version:**` line ([tooling.md → Versioning](tooling.md#versioning)). |
| `build-and-test` | — | The same checks as the [PR pipeline](#pr-pipeline). |
| `build-and-release` | `check-version-tag`, `build-and-test` | `make release TAG=$CIRCLE_TAG`: `docker buildx` with QEMU on a **single machine** for `linux/amd64` and `linux/arm64`; pushes `darthjee/vault:X.Y.Z` and `darthjee/vault:latest`. |
| `update-description` | `build-and-release` | `make update-description` ([Docker Hub description](#docker-hub-description)). |

- buildx / QEMU setup and `docker login` are CI-only steps in `scripts/ci/*.sh`.
- **No tag is pushed during epic #2.** The first release happens after the epic is done.

## Credentials

**Instead of** CircleCI project env vars ([`AGENTS.md`](../../../../AGENTS.md#release-circleci)):

| Item | Decision |
|------|----------|
| Variables | `DOCKER_HUB_USERNAME`, `DOCKER_HUB_PASSWORD` |
| Storage | A **restricted CircleCI context**, not project env vars. |
| Used by | `build-and-release` and `update-description` only. PR jobs never receive them. |
| Context name | Chosen when the context is created; #9 records it here. |

## Docker Hub description

- `DOCKERHUB_DESCRIPTION.md` is the Docker Hub page: what Vault is, how to run it (Sysbox recommended, `--privileged` fallback), the Vault env vars, and a pointer to the README Security section. Exact prose is left to #9.
- `make update-description` calls a `scripts/ci/` wrapper that fetches `darthjee/scripts`' `docker_hub.sh` at a **pinned tag or commit** and runs it. Nothing is vendored into this repo.

## Manual prerequisites

Done by a maintainer, outside any PR, before the first release:

| Prerequisite | Needed by |
|--------------|-----------|
| Docker Hub repository `darthjee/vault` | `build-and-release`, `update-description` |
| CircleCI project for this repo | #8 |
| Restricted CircleCI context holding the [credentials](#credentials) | #9 |
