# Docker Image Spec: Overview

Temporary spec for epic #2 (the Vault Docker image). Written by #3.

| File | Contents |
|------|----------|
| [overview.md](overview.md) | Purpose, scope, shared contracts, sub-issue map, conflicts, alternatives, future work. |
| [image.md](image.md) | Dockerfile, entrypoint behaviour, edge cases, runtime privileges, security, base image. |
| [tooling.md](tooling.md) | Versioning, Makefile targets, tool images, testing strategy, scripts vs Makefile. |
| [ci.md](ci.md) | CircleCI PR pipeline, release pipeline, credentials, Docker Hub description. |

## Purpose and lifecycle

- One agreed reference for sub-issues #4–#10, so each can be planned and implemented without diverging.
- **Precedence:** during epic #2, this spec overrides [`AGENTS.md`](../../../../AGENTS.md) and `docs/agents/*.md` where they conflict (see [Conflicts with the existing docs](#conflicts-with-the-existing-docs)).
- **Working document:** a sub-issue PR that deviates from the spec updates the spec in the same PR.
- **Removal:** #10 folds the spec into the permanent docs, then deletes `docs/agents/specs/docker-image/`, the `specs/` row and the override note in `AGENTS.md`.
- **Writing rule:** each section links to the existing doc for anything unchanged ("see `<doc>`; in addition / instead:"). Only new or changed content is written out in full.

## Scope

| The spec decides | Left to each sub-issue |
|------------------|------------------------|
| Shared contracts (below): Makefile targets and variables, image paths, env vars, credentials, version rule | Library function names and signatures |
| Open points: base image pin, tool images, script locations, privileges, security | The list of test cases |
| Entrypoint **behaviour**: flow, user-facing messages, exit codes, edge cases | The exact CircleCI YAML and Makefile recipes |
| Testing strategy (which layer covers what) | README and Docker Hub prose |

## Shared contracts

These are relied on by more than one sub-issue. Changing one requires updating this spec and every sub-issue that uses it.

### Makefile targets

| Target | Behaviour | Details |
|--------|-----------|---------|
| `build-image` | Build the Vault image locally. | [tooling.md](tooling.md#makefile) |
| `lint` | Run shellcheck over `source/`, `scripts/` and `test/` via `SHELLCHECK_IMAGE`. | [tooling.md](tooling.md#lint-and-unit-test-tool-images) |
| `test` | Run the bats unit tests via `BATS_IMAGE`. | [tooling.md](tooling.md#lint-and-unit-test-tool-images) |
| `test-image` | Smoke test: build, run `--privileged` with the fixture, check, clean up. | [tooling.md](tooling.md#smoke-test) |
| `release TAG=x` | Multi-arch build and push of `darthjee/vault:x` and `:latest`. **Fails fast without `TAG`.** | [ci.md](ci.md#release-pipeline) |
| `update-description` | Push `DOCKERHUB_DESCRIPTION.md` to Docker Hub. | [ci.md](ci.md#docker-hub-description) |
| `bump-version VERSION=X.Y.Z` | Update `VERSION` and the README line. **Fails fast without `VERSION`.** | [tooling.md](tooling.md#versioning) |
| `check-version-tag TAG=X.Y.Z` | Check the tag against `VERSION` and the README line. **Fails fast without `TAG`.** | [tooling.md](tooling.md#versioning) |

`build-image`, `test-image`, `update-description` and `release` start as no-op stubs in #4 ([tooling.md → Makefile](tooling.md#makefile)).

| Variable | Purpose |
|----------|---------|
| `SHELLCHECK_IMAGE ?= koalaman/shellcheck:v0.11.0` | Lint tool image. |
| `BATS_IMAGE ?= bats/bats:1.14.0` | Unit test tool image. |
| `DOCKER_VERSION` | Passed as `--build-arg DOCKER_VERSION=…`; default comes from the Dockerfile `ARG` (`29.8.2`). |

### Image paths

| Path | Contents |
|------|----------|
| `/usr/local/lib/vault/` | Libraries from `source/lib/`. |
| `/usr/local/bin/vault-entrypoint` | `source/bin/entrypoint.sh`; the image `ENTRYPOINT`. |
| `/vault` | `WORKDIR`; compose file(s) and their files. |
| `/vault/images` | Optional `*.tar` images preloaded before compose starts. |

### Environment variables

Vault adds only two variables. Compose's own variables (`COMPOSE_FILE`, `COMPOSE_PROJECT_NAME`) are described in [architecture.md → Configuration](../../architecture.md#configuration).

| Variable | Default | Rule |
|----------|---------|------|
| `COMPOSE_UP_ARGS` | empty | Extra args for the default `up`. Split on whitespace (`read -ra`), **no quoting support** (documented). |
| `VAULT_DOCKERD_TIMEOUT` | `30` | Seconds to wait for `dockerd`. Must be a positive integer, otherwise Vault fails fast ([image.md → Edge cases](image.md#edge-cases)). |

### Credentials

`DOCKER_HUB_USERNAME` / `DOCKER_HUB_PASSWORD`, stored in a **restricted CircleCI context** used only by the release jobs. See [ci.md → Credentials](ci.md#credentials).

### Version rule

- The release tag (`X.Y.Z`) must equal the `VERSION` file **and** the README `**Current Version:**` line.
- The initial `VERSION` is `0.1.0`.
- See [tooling.md → Versioning](tooling.md#versioning).

## Sub-issue map

| Sub-issue | Owner | Topic | Implements |
|-----------|-------|-------|------------|
| #4 | `automation` | Repo scaffolding: `VERSION`, version scripts, Makefile, lint/test via Docker | [tooling.md](tooling.md): Versioning, Makefile, Lint and unit test tool images, Scripts vs Makefile |
| #5 | `dev` | Dockerfile, dockerd start/wait, image preload | [image.md](image.md): Dockerfile, Entrypoint flow (steps 1–4), Edge cases 1–5, Security, Base image |
| #6 | `dev` | Compose run, signal handling, exit code | [image.md](image.md): Entrypoint flow (steps 5–7), Edge cases 6–8, Exit codes |
| #7 | `dev` / `automation` | Smoke test (`make test-image`) | [tooling.md](tooling.md#smoke-test), [image.md → Security](image.md#security-and-performance) (port 2375 assertion) |
| #8 | `automation` | CircleCI PR pipeline | [ci.md → PR pipeline](ci.md#pr-pipeline) |
| #9 | `automation` | Release pipeline and Docker Hub description | [ci.md](ci.md): Release pipeline, Credentials, Docker Hub description |
| #10 | `product-owner` / `architect` | README, agent docs sync, spec removal | [image.md](image.md): Edge cases 9–10, Runtime privileges; this file: [Conflicts](#conflicts-with-the-existing-docs) |

## Conflicts with the existing docs

Where the spec and the permanent docs disagree, the spec wins until #10 reconciles them.

| Topic | Existing docs say | Spec says |
|-------|-------------------|-----------|
| Credentials | CircleCI **project env vars** ([`AGENTS.md`](../../../../AGENTS.md) → Release) | A **restricted CircleCI context**, used only by the release jobs ([ci.md](ci.md#credentials)). |
| dockerd host | Started through `dockerd-entrypoint.sh` with `DOCKER_TLS_CERTDIR=""` ([flow.md](../../flow.md)) | Always passed an explicit `--host=unix:///var/run/docker.sock`, so no TCP listener ([image.md](image.md#security-and-performance)). |
| Compose exits on its own | Implied `down` on shutdown ([flow.md](../../flow.md)) | No `compose down`; only dockerd is stopped. `down` runs only on the signal path ([image.md](image.md#entrypoint-flow)). |
| Makefile variables | Targets only ([folder-structure.md](../../folder-structure.md)) | Adds `SHELLCHECK_IMAGE`, `BATS_IMAGE` and the `DOCKER_VERSION` build arg ([tooling.md](tooling.md#makefile)). |
| `scripts/ci/` | Listed as `ci/*` without a rule ([folder-structure.md](../../folder-structure.md)) | Holds every CI-only wrapper (`docker login`, buildx/QEMU setup, fetching `docker_hub.sh`) ([tooling.md](tooling.md#scripts-vs-makefile)). |

## Alternatives considered

| Alternative | Why rejected |
|-------------|--------------|
| A single spec file | Too long to review and to link from sub-issues. |
| Editing `docs/agents/*.md` directly | Mixes temporary content into the permanent docs. |
| Spec only in issue bodies | Not versioned with the code. |

## Future work

Recorded explicitly; none of it is in epic #2.

- **Vulnerability scanning** of the published image.
- **Sysbox in CI:** CI smoke-tests only `--privileged` today.
- **Renovate / Dependabot** for the pinned images (`docker:*-dind`, shellcheck, bats).
- **CLI** to run Vault containers (see [`AGENTS.md`](../../../../AGENTS.md) → Future work); unchanged by this spec.
