# Automation Plan: Docker image: Dockerfile, dockerd start/wait and image preload

Main plan: [plan.md](plan.md)

## Shared contracts

- `dev` provides `./Dockerfile` at the repo root, with `ARG DOCKER_VERSION=29.8.2` before `FROM`.
- `automation` provides `make build-image`, tagged `$(IMAGE)` (`?= darthjee/vault:dev`), passing `--build-arg DOCKER_VERSION=$(DOCKER_VERSION)` only when `DOCKER_VERSION` is set (so the Dockerfile default applies otherwise).

## Implementation Steps

### Step 1 — Real `build-image` target
Replace the #4 stub in `Makefile`:

- Add `IMAGE ?= darthjee/vault:dev` next to the other variables.
- Recipe (one line, so it stays in the Makefile per tooling.md → Scripts vs Makefile):
  `docker build $(if $(DOCKER_VERSION),--build-arg DOCKER_VERSION=$(DOCKER_VERSION)) -t $(IMAGE) .`
- `build-image` fails non-zero when the build fails (plain `docker build` already does).

### Step 2 — Record the new variable in the spec
Add `IMAGE` to the Makefile variable tables in `docs/agents/specs/docker-image/overview.md` (Shared contracts → Makefile targets) and `tooling.md` (Makefile), and drop `build-image` from the list of #4 no-op stubs in both files (`test-image`, `update-description` and `release` remain stubs).

## Files to Change
- `Makefile` — `IMAGE` variable; real `build-image` recipe.
- `docs/agents/specs/docker-image/overview.md` — `IMAGE` variable; `build-image` no longer a stub.
- `docs/agents/specs/docker-image/tooling.md` — same.

## CI Checks
- `Makefile`: `make lint`; also `make build-image` and `make build-image DOCKER_VERSION=29.8.2` (needs `dev`'s Dockerfile).

## Notes
- No `.circleci/` exists yet (#8), so there is no CI job to run.
- A `.dockerignore` is not needed: the Dockerfile only copies `source/`. If the build context turns out slow (e.g. `.git`), adding one is a root-level file for `architect`.
