# Write image.md
Create `docs/agents/specs/docker-image/image.md`. It links to `architecture.md` (Image) and `flow.md` for the baseline, then adds:
- **Base image:**
  - `ARG DOCKER_VERSION=29.8.2` and `FROM docker:${DOCKER_VERSION}-dind`, pinned by tag;
  - the manual bump procedure: change the ARG, run `make lint test test-image`, re-check the dind TCP-host behaviour, release;
  - the rejected options: rootless, an `-alpine3.x` suffix, a minor-line tag.
- **Dockerd startup:** always start with an explicit `--host=unix:///var/run/docker.sock`, never TCP. State that the dind entrypoint is believed to add `tcp://0.0.0.0:2375` when `DOCKER_TLS_CERTDIR` is empty, and that #5 verifies this.
- **Entrypoint flow changes** compared with `flow.md`:
  - a privilege pre-check runs before dockerd;
  - `VAULT_DOCKERD_TIMEOUT` is validated;
  - `COMPOSE_UP_ARGS` is split on whitespace with `read -ra`, with no quoting;
  - when compose exits on its own, only dockerd is stopped, with no `down`;
  - after a signal, Vault exits with compose's exit code.
- **Edge-case table:** all 10 cases from issue #3, each with its behaviour, the issue that implements it, and the test that covers it (a bats test in #5/#6, the smoke test in #7, or documentation only in #10).
- **Runtime privileges:**
  - supported runtimes: Sysbox (recommended) and `--privileged`;
  - unsupported: rootless, hand-picked capabilities, mounting the host `docker.sock`;
  - host requirements; managed platforms are not supported;
  - Sysbox is checked manually, not in CI.
- **Security & performance:** root inside the container is documented; startup-time mitigations (named volume, preload); overlay2 on the declared volume.

## Files to Change
- `docs/agents/specs/docker-image/image.md` — new.
