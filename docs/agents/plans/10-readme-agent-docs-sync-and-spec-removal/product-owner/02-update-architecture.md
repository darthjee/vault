# Update architecture.md

Bring `docs/agents/architecture.md` in line with the implementation. Sources: spec `overview.md` (Image paths, Environment variables), `image.md` (Base image, Runtime privileges, Security and performance), `tooling.md` (Testing strategy, Smoke test).

- **Image:** add the image paths table (`/usr/local/lib/vault/`, `/usr/local/bin/vault-entrypoint`, `/vault`, `/vault/images`). State the base pin (`docker:29.8.2-dind`, overridable with the `DOCKER_VERSION` build arg). Note that all images are pinned by tag, not digest.
- **`source/lib/` table:** add `preflight.sh` (timeout validation, tmpfs privilege probe). Fix `dockerd.sh` (explicit unix `--host`) and `compose.sh` (no `down` when compose exits on its own; `down` only on the signal path, which `signals.sh` drives). Keep the "sourcing has no side effects" rule.
- **Configuration:** `VAULT_DOCKERD_TIMEOUT` must be a positive integer (fail fast otherwise). `COMPOSE_UP_ARGS` is a whitespace split with no quoting support.
- **Runtime requirements:** supported runtimes are Sysbox (recommended) and `--privileged` (fallback). Unsupported: rootless, `--cap-add`, mounting the host `docker.sock`. The host must provide cgroup nesting. Not usable on most managed platforms (ECS Fargate, Cloud Run, Kubernetes without privileged pods). CI smoke-tests only `--privileged`. Link to `../../README.md#security`.
- **Security:** the inner daemon listens on the unix socket only (the smoke test asserts nothing listens on 2375). The container runs as root (see the README Security section).
- **New `## Testing` section** (short): bats unit tests over `source/lib` with external commands stubbed (`test/lib/*.bats`); shellcheck over `source/`, `scripts/`, `test/`; the smoke test (`make test-image`, `scripts/test_image.sh`, fixture `test/fixture/docker-compose.yml`) builds, runs `--privileged`, `curl`s the port, checks for no 2375 listener, stops the container and expects exit 0, then cleans up.

## Files to Change
- `docs/agents/architecture.md` — image paths, libraries, configuration rules, runtime requirements, security, testing.
