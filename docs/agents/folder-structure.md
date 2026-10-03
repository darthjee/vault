# Folder Structure

## Project Root

| Directory / File | Description |
|-----------------|-------------|
| `Dockerfile` | Builds the Vault image (`FROM docker:${DOCKER_VERSION}-dind`, adds bash, installs `source/`, `EXPOSE 80`, `VOLUME /var/lib/docker`, `WORKDIR /vault`). |
| `source/` | Files installed into the image: `bin/entrypoint.sh` (the only script) and `lib/*.sh` (function libraries). |
| `test/` | `lib/*.bats` (bats unit tests for `source/lib`) and `fixture/docker-compose.yml` (smoke-test stack). |
| `scripts/` | Repo scripts for development and CI: `bump_version.sh`, `check_tag_version.sh`, `lint.sh`, `test.sh`, `test_image.sh`, `release.sh`, `ci/`. See [scripts/](#scripts). |
| `.circleci/` | CI and release pipeline. |
| `Makefile` | The only entry point for developers and CI. See [Makefile](#makefile). |
| `VERSION` | Current version; checked against the release tag. |
| `DOCKERHUB_DESCRIPTION.md` | Docker Hub page content. |
| `docs/agents/` | Agent documentation, issues (`issues/`), implementation plans (`plans/`) and, temporarily during epic #20, the CLI spec (`specs/`, which overrides the other docs where they conflict; removed by #30). |
| `.github/` | PR template, commit message template, Copilot pointer. |
| `.claude/` | Claude agents, check scripts and configuration. |

## source/

| Subdirectory | Description |
|--------------|-------------|
| `bin/` | `entrypoint.sh` — the container entrypoint; the only file that executes logic and reads environment variables. |
| `lib/` | Function libraries sourced by the entrypoint (`preflight.sh`, `dockerd.sh`, `images.sh`, `compose.sh`, `signals.sh`). |

## scripts/

- **Make is the only entry point.** Developers and CI call make targets, never scripts directly.
- A recipe longer than one line moves to `scripts/*.sh`.
- CI-only steps live in `scripts/ci/`:
  - `docker_login.sh` — `docker login` to Docker Hub.
  - `setup_buildx.sh` — QEMU / buildx setup for multi-platform builds.
  - `update_description.sh` — fetches `docker_hub.sh` (pinned) and pushes `DOCKERHUB_DESCRIPTION.md`.
- Everything under `scripts/` is shellchecked by `make lint`.

## Makefile

| Target | Behaviour |
|--------|-----------|
| `build-image` | `docker build` the image as `IMAGE`, passing `--build-arg DOCKER_VERSION` when set. |
| `lint` | shellcheck over `source/`, `scripts/` and `test/` (`scripts/lint.sh`). |
| `test` | bats over `test/lib/` (`scripts/test.sh`). |
| `test-image` | Depends on `build-image`, then runs the smoke test (`scripts/test_image.sh`). |
| `bump-version VERSION=X.Y.Z` | Updates `VERSION` and the README version line (`scripts/bump_version.sh`). |
| `check-version-tag TAG=X.Y.Z` | Fails unless the tag matches `VERSION` and the README (`scripts/check_tag_version.sh`). |
| `release TAG=x` | Multi-arch build and push (`scripts/release.sh`). |
| `update-description` | Pushes `DOCKERHUB_DESCRIPTION.md` to Docker Hub (`scripts/ci/update_description.sh`). |
| `ci-release-setup` | CI-only: buildx setup and Docker Hub login. |

| Variable | Default | Purpose |
|----------|---------|---------|
| `SHELLCHECK_IMAGE` | `koalaman/shellcheck:v0.11.0` | Image used by `make lint`. |
| `BATS_IMAGE` | `bats/bats:1.14.0` | Image used by `make test`. |
| `IMAGE` | `darthjee/vault:dev` | Tag built by `build-image` and tested by `test-image`. |
| `DOCKER_VERSION` | unset (Dockerfile default) | Base image version passed as a build arg. |
