# Dev Plan: Docker image: Dockerfile, dockerd start/wait and image preload

Main plan: [plan.md](plan.md)

## Shared contracts

- Provide `./Dockerfile` at the repo root, starting with `ARG DOCKER_VERSION=29.8.2` and `FROM docker:${DOCKER_VERSION}-dind`, buildable with context `.`.
- `automation`'s `make build-image` builds it as `$(IMAGE)` (`darthjee/vault:dev` by default).
- Every Vault-side failure in #5 exits **1**.

## Steps

- [01 — Dockerfile](dev/01-dockerfile.md)
- [02 — preflight.sh](dev/02-preflight-lib.md)
- [03 — dockerd.sh](dev/03-dockerd-lib.md)
- [04 — images.sh](dev/04-images-lib.md)
- [05 — Entrypoint skeleton](dev/05-entrypoint-skeleton.md)
- [06 — Verify the image and update the spec](dev/06-verify-and-update-spec.md)

## CI Checks
- `Dockerfile`, `source/`, `test/`: `make lint`, `make test`, `make build-image`. `make test-image` is still a stub until #7; the manual check in step 06 covers the runtime instead.

## Notes
- Follow `docs/agents/contributing.md`: libraries only define functions, take every input as an argument, put public functions before `_`-prefixed helpers, and use the module-name prefix (`preflight_`, `dockerd_`, `images_`). Scripts use `#!/usr/bin/env bash` + `set -euo pipefail`.
- Unit tests run on the bats image's bash, not Alpine's (known gap, tooling.md); step 06 covers the real runtime manually.
- Function names and signatures below are suggestions; the spec leaves them to this issue.
