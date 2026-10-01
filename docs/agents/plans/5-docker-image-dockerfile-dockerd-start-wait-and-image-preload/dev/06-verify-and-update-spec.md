# Verify the image and update the spec

Manual runtime check against `docker:29.8.2-dind` (once `automation`'s `make build-image` exists):

- `make build-image`, then `docker run -d --privileged darthjee/vault:dev`. The logs show dockerd ready and the #6 placeholder notice. `docker exec <c> docker info` succeeds.
- **TCP check:** confirm nothing listens on 2375 (`docker exec <c> netstat -ltn`). Also confirm whether the bare dind entrypoint, with `DOCKER_TLS_CERTDIR=""` and no explicit `dockerd` args, would add `tcp://0.0.0.0:2375` (read `/usr/local/bin/dockerd-entrypoint.sh` in the base image).
- Without `--privileged` (`docker run --rm darthjee/vault:dev`), it exits 1 at once with the hint.
- `-e VAULT_DOCKERD_TIMEOUT=abc` exits 1 with the validation message.
- Mount a dir holding a non-image `bad.tar` on `/vault/images`: exits 1 naming the file.

Then update `docs/agents/specs/docker-image/image.md` (working-document rule in overview.md):
- Dockerd startup: replace "**To be verified** by #5" with the finding.
- Entrypoint flow step 1: the probe is a tmpfs mount on a temp dir.
- Exit codes and messages: Vault-side failures in #5 exit `1`. Tarball load failure and dockerd timeout both stop dockerd first.
- Note that the signal trap is installed by #6 (no trap in #5).

## Files to Change
- `docs/agents/specs/docker-image/image.md` — record the probe, the TCP finding, and the exit code.
