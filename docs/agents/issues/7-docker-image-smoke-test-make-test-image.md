# Issue: Docker image smoke test (make test-image)

## Description
Part of epic #2. Implement `make test-image`, an end-to-end smoke test of the Vault image under the real runtime (`--privileged`, amd64), following [tooling.md → Smoke test](docs/agents/specs/docker-image/tooling.md#smoke-test). Today `test-image` is a no-op stub left by #4. Depends on #5 and #6, both merged.

## Problem
`make lint` and `make test` exercise `source/lib` with stubbed `docker` / `dockerd` on the bats image's bash. Nothing checks the built image itself: dockerd startup under `--privileged`, compose bringing up a stack, the published port, the absence of an inner TCP listener on 2375, and a clean `docker stop`.

## Expected Behavior
### Fixture
- A tiny compose file under `test/` (e.g. `test/fixture/docker-compose.yml`) with one service, `nginx:<version>-alpine` pinned by tag (e.g. `nginx:1.29-alpine`), publishing `80:80` inside Vault.
- No `images/` tarballs: preload is skipped (edge case 4) and the inner dockerd pulls nginx from the network on every run.

### Make target
- `test-image: build-image` — the build is a Make prerequisite; the target then runs the smoke-test script under `scripts/` with `IMAGE`. Make is only the entry point; the script passes shellcheck (`make lint`).
- New overridable variable: `SMOKE_TIMEOUT ?= 120` (seconds to wait for the published port).

### Script steps
1. Run Vault detached, `--privileged`, with a unique container name, the fixture mounted at `/vault`, and `-p 127.0.0.1::80` (Docker picks a free host port).
2. Read the host port back with `docker port`.
3. Poll `curl` on `127.0.0.1:<port>` every 2s, up to `SMOKE_TIMEOUT`; it must return HTTP 200.
4. Assert nothing listens on port 2375 inside the container: `docker exec <c> netstat -ltn` (spec: image.md → Dockerd startup).
5. `docker stop -t 30 <c>` (headroom for `compose down`, see edge case 9), then assert `docker inspect` `.State.ExitCode` is `0`.
6. **Always** clean up via a trap, also when a check fails: `docker rm -fv <c>` (container and its anonymous `/var/lib/docker` volume) and any network created.

### Failure reporting
- Exits non-zero on any failed check, naming the check, and prints the container logs.
- Runs unchanged on a CircleCI `machine: true` executor (used by #8).

## Solution
- `dev` owns the fixture under `test/`.
- `automation` owns the `test-image` Make target (replacing the #4 stub), the `SMOKE_TIMEOUT` variable, and the smoke-test script under `scripts/`.
- Update [tooling.md → Makefile](docs/agents/specs/docker-image/tooling.md#makefile) variables table with `SMOKE_TIMEOUT`.

## Benefits
- Covers the real runtime that unit tests can't reach (Alpine bash, real dockerd, real compose).
- Gives #8 a single `make test-image` call for the CI smoke-test step.
- A random localhost port avoids clashes with parallel runs or services already on the host.
- Guards against regressions in the unix-socket-only dockerd setting when `DOCKER_VERSION` is bumped.
