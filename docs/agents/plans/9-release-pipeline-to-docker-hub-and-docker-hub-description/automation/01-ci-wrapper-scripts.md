# CI wrapper scripts
Add the CI-only steps under `scripts/ci/`. Follow the Bash style of the existing scripts: `#!/usr/bin/env bash`, a usage comment, `set -euo pipefail`, and `ROOT` resolved from `BASH_SOURCE`. `make lint` already shellchecks `scripts/ci/`.

- `scripts/ci/setup_buildx.sh`
  - Registers QEMU binfmt handlers with a pinned `tonistiigi/binfmt` image tag (`docker run --privileged --rm tonistiigi/binfmt:<tag> --install arm64`).
  - Creates and selects a `docker-container` buildx builder (`docker buildx create --name vault-builder --use`). It reuses the builder when it already exists.
  - Bootstraps the builder.
- `scripts/ci/docker_login.sh`
  - Fails with a clear message when `DOCKER_HUB_USERNAME` or `DOCKER_HUB_PASSWORD` is unset.
  - Then runs `docker login -u "$DOCKER_HUB_USERNAME" --password-stdin`, piping in the password.
- `scripts/ci/update_description.sh`
  - Fails with a clear message when either credential is unset.
  - Downloads `docker_hub.sh` from the pinned commit URL into a `mktemp` file, removed by an `EXIT` trap, using `curl -fsSL`.
  - Verifies the file's sha256 against the pinned value, with `sha256sum -c`. It fails on a mismatch.
  - Runs `bash "$tmp" login_and_push_description darthjee/vault "$ROOT/DOCKERHUB_DESCRIPTION.md"`.
  - The URL, sha256 and repository are variables at the top of the script, so a later bump changes one place.

## Files to Change
- `scripts/ci/setup_buildx.sh` — new: QEMU and buildx builder setup.
- `scripts/ci/docker_login.sh` — new: Docker Hub login from env vars.
- `scripts/ci/update_description.sh` — new: fetch the pinned `docker_hub.sh`, verify it, and push the description.
