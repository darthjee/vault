# Release script and Makefile targets
Add `scripts/release.sh TAG`, which runs `docker buildx build` with:

- `--platform linux/amd64,linux/arm64`;
- `-t darthjee/vault:$TAG -t darthjee/vault:latest`;
- `--build-arg DOCKER_VERSION` only when `DOCKER_VERSION` is set;
- `--push` when `PUSH` is `true`, which is the default. With `PUSH=false` it builds without pushing, for local validation. The multi-platform result then stays in the buildx cache, and is not loaded into the local image store.

The script fails with a usage message when `TAG` is empty.

Makefile changes:

- `release`:
  - With no `TAG`, it keeps failing fast through `$(error ...)` before anything runs.
  - Otherwise it runs `scripts/release.sh $(TAG)`.
  - Add `RELEASE_IMAGE ?= darthjee/vault` and `PUSH ?= true` to the exported variables, and have the script read them.
- `update-description`: runs `scripts/ci/update_description.sh`.
- `ci-release-setup`: new. It runs `scripts/ci/setup_buildx.sh`, then `scripts/ci/docker_login.sh`. Add it to `.PHONY`.
- Remove the stub notices that mention #9.

## Files to Change
- `scripts/release.sh` — new: multi-arch buildx build, with an optional push.
- `Makefile` — real `release` and `update-description` targets, the new `ci-release-setup` target, and the `RELEASE_IMAGE` and `PUSH` variables.
