# Write README.md

Replace the stub `README.md` with the user-facing documentation. Keep `# vault` and the `**Current Version:** 0.1.0` line at the top. Sections:

1. **What Vault is:** one paragraph plus the host → Vault container → services diagram (same as `DOCKERHUB_DESCRIPTION.md`).
2. **Usage:**
   - `docker run --runtime=sysbox-runc` (recommended) and `docker run --privileged` (fallback) examples, with `-v "$PWD/my-stack:/vault"` and `-p 8080:80`.
   - A derived image `FROM darthjee/vault` + `COPY . /vault`.
   - Arguments are passed to `docker compose` (e.g. `ps`, `config`, `up --build`).
   - Ports: the inner `ports: ["80:3000"]` plus outer `-p`. `EXPOSE 80` is only a convention. Databases should not publish ports. There is no reverse proxy.
   - A named volume on `/var/lib/docker` keeps images and inner volumes.
   - Offline preload with `/vault/images/*.tar`.
   - Bind mounts in the inner compose file refer to the outer container's filesystem.
3. **Environment variables:** a table with `COMPOSE_FILE`, `COMPOSE_PROJECT_NAME`, `COMPOSE_UP_ARGS` (whitespace split, **no quoting support**; e.g. `--abort-on-container-exit`, `--pull never`) and `VAULT_DOCKERD_TIMEOUT` (positive integer, default 30).
4. **Behaviour:**
   - The exit code is compose's exit code.
   - Service crashes are handled by `restart:` policies; fail fast with `--abort-on-container-exit`.
   - Shutdown: SIGTERM / SIGINT run `compose down` and stop dockerd. If that takes longer than `docker stop`'s 10s, use `docker stop -t <s>` / `--stop-timeout`.
   - Never share one `/var/lib/docker` volume between two running Vault containers (not detected).
   - Startup errors: the privilege hint, the invalid timeout message and the tarball failure.
5. **Supported runtimes and platforms:**
   - Sysbox and `--privileged` are supported.
   - Unsupported: rootless, `--cap-add`, mounting the host `docker.sock`.
   - Not on most managed platforms (ECS Fargate, Cloud Run, Kubernetes without privileged pods).
   - Images are published for `linux/amd64` and `linux/arm64`.
6. **`## Security`** (required heading):
   - `--privileged` risks: host escape, full device access, seccomp/AppArmor disabled, and refused by most managed platforms.
   - Processes run as root inside the container.
   - Why Sysbox is safer: user-namespace isolation, so container root is not host root, with no `--privileged`.
   - Vault never exposes the inner Docker socket over TCP (explicit unix `--host`); never add a TCP listener or publish port 2375.
   - Don't mount the host `docker.sock`.
7. **Development:** short; `make build-image`, `make lint`, `make test`, `make test-image` (needs Docker with `--privileged`). Link to `AGENTS.md` / `docs/agents/` for contributors.

## Files to Change
- `README.md` — full user-facing documentation.
