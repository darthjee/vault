# Issue: Docker image spec (docs/agents/specs/docker-image)

## Description
Part of epic #2, and its first sub-issue: it depends on nothing. Owner: `product-owner`.

Write a temporary spec for the Vault Docker image under `docs/agents/specs/docker-image/`. It records every decision the later sub-issues of #2 need:

| Sub-issue | Topic |
|-----------|-------|
| #4 | Repo scaffolding: `VERSION`, version scripts, Makefile, lint/test via Docker |
| #5 | Dockerfile, dockerd start/wait, image preload |
| #6 | Compose run, signal handling, exit code |
| #7 | Smoke test (`make test-image`) |
| #8 | CircleCI PR pipeline |
| #9 | Release pipeline and Docker Hub description |
| #10 | README, agent docs sync, spec removal |

Only documentation changes: no code, Makefile or CI.

## Problem
The design is spread across `AGENTS.md` and `docs/agents/*.md`, and it describes the target state only. Several decisions that more than one sub-issue depends on are still open: the base image pin, the tool images, where scripts live, edge-case behaviour, how credentials are handled, the privilege checks. Without one agreed reference, sub-issues #4–#10 would each decide these on their own, and their decisions would diverge.

## Expected Behavior
- `docs/agents/specs/docker-image/` exists, with:
  - `overview.md`: scope, shared contracts, and the sub-issue map (#4–#10 → spec sections);
  - `image.md`: the Dockerfile, the entrypoint behaviour, the edge cases, runtime privileges, and the base image bump procedure;
  - `tooling.md`: versioning, the Makefile targets, the lint/unit tool images, the smoke test, and scripts vs Makefile;
  - `ci.md`: the CircleCI PR pipeline, the release pipeline, credentials, and the Docker Hub description.
- Every decision listed under Solution is in the spec. The spec links to the existing docs for anything that doesn't change, and states in full only what is new or changed.
- `AGENTS.md` gets a `specs/` row in its documentation table, plus this note: "During epic #2, `docs/agents/specs/docker-image/` overrides these docs where they conflict."
- The spec is a working document: a later PR that deviates from it updates it in the same PR. #10 deletes it.
- No tests are needed (documentation only).

## Solution

### Scope of the spec
**It decides:**
- Shared contracts:
  - Makefile target names and their behaviour: `build-image`, `lint`, `test`, `test-image`, `release TAG=x` (fails fast without `TAG`), `update-description`;
  - image paths: `/usr/local/lib/vault/`, `/usr/local/bin/vault-entrypoint`, `/vault`, `/vault/images`;
  - Vault env vars: `COMPOSE_UP_ARGS`, and `VAULT_DOCKERD_TIMEOUT` (default 30);
  - CI credential names;
  - the version-check rule: the tag must equal `VERSION` and the README `**Current Version:**` line. The initial `VERSION` is `0.1.0`.
- Entrypoint **behaviour**: the flow, the user-facing messages and the exit codes.

**It leaves to each sub-issue:** library function names and signatures, the list of test cases, the exact CircleCI YAML and Makefile recipes, and README prose.

### Edge cases (`image.md`)
| # | Case | Behaviour | Implemented in |
|---|------|-----------|----------------|
| 1 | Not enough privileges | Fast pre-check before dockerd (a harmless privileged operation, e.g. mounting a tmpfs) fails and exits immediately with the `--privileged` / sysbox hint. The probe must succeed under both `--privileged` and Sysbox. | #5 |
| 2 | `VAULT_DOCKERD_TIMEOUT` is not a positive integer | Fail fast before starting dockerd, with a clear message. | #5 |
| 3 | `dockerd` not ready within the timeout | Print `dockerd failed to start; are you running with --privileged (or the sysbox runtime)?` and exit non-zero. | #5 |
| 4 | `/vault/images` missing or has no `*.tar` | Skip silently. | #5 |
| 5 | A tarball fails to load | Stop dockerd and exit non-zero; the message names the file. | #5 |
| 6 | No compose file in `/vault` | No pre-check: compose prints its own error, then Vault stops dockerd and exits with compose's exit code. | #6 |
| 7 | A signal arrives before compose has started | Stop dockerd and exit. | #6 |
| 8 | A second signal arrives during shutdown | Ignored; the shutdown already in progress continues. | #6 |
| 9 | `compose down` takes longer than `docker stop`'s 10s grace period | Documentation only: recommend `docker stop -t` / `--stop-timeout`. | #10 |
| 10 | Two containers share one `/var/lib/docker` volume | Documentation only: not detected. | #10 |

Decisions:
- **Exit code after SIGTERM/SIGINT:** compose's exit code.
- **`COMPOSE_UP_ARGS`:** split on whitespace (`read -ra`), with no quoting support (documented).
- **Compose exits on its own** (`up` or passthrough): stop dockerd only, with no `compose down`. `down` runs only on the signal path.

### Runtime privileges & host impact
- **Supported runtimes:** `--runtime=sysbox-runc` (recommended) and `--privileged` (fallback).
  - **Unsupported:** rootless, hand-picked capabilities, and mounting the host's `docker.sock`.
- **What the host must provide:** cgroup nesting, a volume on `/var/lib/docker` (guaranteed by `VOLUME`), and one published port.
- **Where it runs:** Docker Desktop and Linux hosts. It does not run on most managed platforms (ECS Fargate, Cloud Run, Kubernetes without privileged pods).
- **Sysbox:** supported, but checked manually. CI smoke-tests only `--privileged`; Sysbox in CI is future work.

### Security & performance
- **Inner daemon on the unix socket only.** dockerd is always started with an explicit `--host=unix:///var/run/docker.sock`. With an empty `DOCKER_TLS_CERTDIR`, the dind `dockerd-entrypoint.sh` is believed to add an unauthenticated `tcp://0.0.0.0:2375`. #5 confirms this against the pinned version, and #7 asserts that nothing listens on 2375.
- **Credentials:** `DOCKER_HUB_USERNAME` / `DOCKER_HUB_PASSWORD` live in a **restricted CircleCI context** used only by the release jobs, not in project env vars.
- **Pinning:** all images are pinned by tag (no digest).
- **Root inside the container:** documented. Vulnerability scanning is future work.
- **Startup time:** mitigated by a named volume on `/var/lib/docker` or by preloading tarballs.
- **Storage driver:** overlay2, on the declared volume.
- **Release:** a single machine runs `docker buildx` with QEMU for `linux/amd64` and `linux/arm64`.

### Base image
- **Pin:** `docker:29.8.2-dind`, the latest stable as of 2026-10-01, set via `ARG DOCKER_VERSION=29.8.2` and `FROM docker:${DOCKER_VERSION}-dind` so the Makefile and CI can override it.
- **Bump procedure (manual, documented):**
  1. change the `ARG` default;
  2. run `make lint`, `make test` and `make test-image`;
  3. re-check the dind TCP-host behaviour;
  4. release a new version.
- **Rejected:** the `-dind-rootless` variant, an `-alpine3.x` suffix, a minor-line tag, and Renovate/Dependabot (possible future work).

### Tool images
- **Images:** `koalaman/shellcheck:v0.11.0` and `bats/bats:1.14.0`, used directly with the repo mounted read-only. No custom test image is built.
- **Version variables:** `SHELLCHECK_IMAGE ?= …` and `BATS_IMAGE ?= …` in the Makefile.
- **Helper libraries:** `bats-support` / `bats-assert` / `bats-file` from the bats image. #4 verifies that they're bundled and records the load path; the fallback is to vendor them under `test/helpers/`.
- **Known gap:** unit tests run on the bats image's bash, not on the Alpine bash in the Vault image. The smoke test (#7) covers the real runtime.

### Scripts vs Makefile
- **Make is the only entry point.** Anything beyond a one-line recipe goes in `scripts/*.sh`; CI-only steps (`docker login`, buildx/QEMU setup, fetching external scripts) go in `scripts/ci/*.sh`. All of it is shellchecked.
- **CircleCI YAML** only sets up executors, contexts and filters, and calls make targets.
- **`docker_hub.sh`** (from `darthjee/scripts`): fetched at a pinned tag or commit by a `scripts/ci/` wrapper. Nothing is vendored.

### Testing strategy (defined by the spec)
- **Lint:** `make lint` runs shellcheck over `source/`, `scripts/` and `test/`.
- **Unit:** `make test` runs bats, one file per library, with `docker` / `dockerd` stubbed.
- **Smoke:** `make test-image` checks that the image builds, Vault runs `--privileged` with the fixture, `curl` against the port succeeds, nothing listens on 2375, `docker stop` exits cleanly with code 0, and cleanup always runs.
- Each edge case is mapped to a bats test or to the smoke test.
- **Not covered by CI:** Sysbox at runtime and arm64 at runtime.

### Relationship to existing docs
- The spec links to the existing docs for anything unchanged and spells out only the deltas.
- Known conflicts it must call out:
  - credentials come from a restricted context;
  - dockerd gets an explicit unix `--host`;
  - when compose exits on its own, there is no `down`;
  - the Makefile gets `SHELLCHECK_IMAGE` / `BATS_IMAGE` variables and a `DOCKER_VERSION` build arg;
  - `scripts/ci/` holds the CI-only wrappers.
- #10 folds these into the permanent docs and removes the note, the row and the spec.

### Alternatives considered
- **Single spec file:** rejected, because it would be too long to review and to link from sub-issues.
- **Editing `docs/agents/*.md` directly:** rejected, because it would mix temporary content into the permanent docs.
- **Spec only in issue bodies:** rejected, because it wouldn't be versioned with the code.

## Benefits
- One agreed reference for #4–#10, so the sub-issues can be planned and implemented independently without diverging.
- The open decisions are closed up front, so later PRs aren't held up by design debates.
- Temporary by design: #10 turns it into the permanent docs and deletes it.
