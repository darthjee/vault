# Docker Hub description
Write `DOCKERHUB_DESCRIPTION.md`, the Docker Hub page. Keep it short:

- **What Vault is:** a Docker-in-Docker image that runs a `docker compose` stack inside one container, so an app and its dependencies ship as one image exposing one port.
- **How to run it:**
  - The Sysbox example, which is recommended: `--runtime=sysbox-runc`.
  - The `--privileged` fallback.
  - Mounting the compose project at `/vault`, the optional `images/` preload folder, and the port mapping.
  - Base these on `docs/agents/architecture.md` and `docs/agents/flow.md`.
- **Vault env vars:** `VAULT_DOCKERD_TIMEOUT`, plus any other `VAULT_*` var defined in `source/`. Check with `grep -rn VAULT_ source/`.
- **Security pointer:** a link to the README Security section on GitHub (`https://github.com/darthjee/vault#security`), which #10 writes. Include a one-line warning about `--privileged`.
- **Supported platforms:** `linux/amd64` and `linux/arm64`.

## Files to Change
- `DOCKERHUB_DESCRIPTION.md` — new: the Docker Hub page.
