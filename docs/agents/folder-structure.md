# Folder Structure

> The layout below is the planned one; folders are created by the issues that first need them.

## Project Root

| Directory / File | Description |
|-----------------|-------------|
| `Dockerfile` | Builds the Vault image (`FROM docker:<version>-dind`, adds bash, installs `source/`, `EXPOSE 80`, `VOLUME /var/lib/docker`, `WORKDIR /vault`). |
| `source/` | Files installed into the image: `bin/entrypoint.sh` (the only script) and `lib/*.sh` (function libraries). |
| `test/` | Smoke-test fixture (a tiny compose stack) and bats unit tests for `source/lib`. |
| `scripts/` | Repo scripts for development and CI: `bump_version.sh`, `check_tag_version.sh`, `ci/*`. |
| `.circleci/` | CI and release pipeline. |
| `Makefile` | `build-image`, `lint`, `test`, `test-image`, `release`, `update-description`. |
| `VERSION` | Current version; checked against the release tag. |
| `DOCKERHUB_DESCRIPTION.md` | Docker Hub page content. |
| `docs/agents/` | Agent documentation, issue specs and implementation plans. |
| `.github/` | PR template, commit message template, Copilot pointer. |
| `.claude/` | Claude agents, check scripts and configuration. |

## source/

| Subdirectory | Description |
|--------------|-------------|
| `bin/` | `entrypoint.sh` — the container entrypoint; the only file that executes logic and reads environment variables. |
| `lib/` | Function libraries sourced by the entrypoint (`dockerd.sh`, `images.sh`, `compose.sh`, `signals.sh`). |
