# Project Instructions

**Vault** is a Docker image that runs a Docker daemon inside itself (Docker-in-Docker)
and starts a `docker compose` stack on boot. Other projects use it to ship a
stand-alone application: the application, its database and any other dependency
run inside a single Vault container that exposes one port.

## Stack

- Docker-in-Docker, based on a pinned `docker:<version>-dind` image (Alpine)
- `docker compose` (plugin bundled in the base image)
- Bash for the entrypoint and scripts (`bash` is installed via `apk`); linted with `shellcheck`, unit-tested with `bats-core`
- Make for build / lint / test / release targets
- CircleCI for CI and releases; images published to Docker Hub as `darthjee/vault`

## Design

### Runtime flow (entrypoint)

1. Start `dockerd` in the background (reusing the base image's `dockerd-entrypoint.sh`,
   with `DOCKER_TLS_CERTDIR=""` since the inner daemon is only reached via its unix socket).
2. Wait until `docker info` succeeds, up to `VAULT_DOCKERD_TIMEOUT` seconds (default 30).
   On timeout, fail with a hint: `dockerd failed to start; are you running with --privileged (or the sysbox runtime)?`
3. `docker load` every `/vault/images/*.tar` (optional offline preload).
4. Run `docker compose` in the foreground from `/vault`:
   - no arguments → `docker compose up ${COMPOSE_UP_ARGS}`
   - with arguments → `docker compose "$@"` (e.g. `docker run vault up --build`, `docker run vault config`)
5. On SIGTERM / SIGINT: `docker compose down`, then stop `dockerd` cleanly.
6. Exit with compose's exit code.

### Conventions

- **`/vault` is the working directory.** The user mounts (or a derived image `COPY`s)
  the `docker-compose.yml` and any files it needs there. Relative paths resolve against `/vault`.
- **Bind mounts in the inner compose file refer to the outer container's filesystem**,
  not the host's — anything the inner stack needs must be mounted into the outer container first.
- **Compose's own env vars are the configuration surface:** `COMPOSE_FILE`
  (`:`-separated list allowed), `COMPOSE_PROJECT_NAME`. Vault adds only
  `COMPOSE_UP_ARGS` (parsed into a bash array) and `VAULT_DOCKERD_TIMEOUT`.
- **Service failures:** the container only exits when compose exits. Individual service
  crashes are handled by compose `restart:` policies; users wanting fail-fast set
  `COMPOSE_UP_ARGS="--abort-on-container-exit"`.
- **Images:** pulled at startup by compose by default; pull behaviour is controlled by
  compose (`pull_policy:` / `COMPOSE_UP_ARGS="--pull never"`), not by Vault.
- **Persistence:** the image only declares `VOLUME /var/lib/docker` (required by DinD).
  Mounting volumes is the responsibility of whoever runs the image. A named volume on
  `/var/lib/docker` persists both the image cache and inner named volumes (e.g. database data).
  Never share one `/var/lib/docker` volume between two running Vault containers.
- **Ports:** an inner service publishes its port inside the Vault container
  (e.g. `ports: ["80:3000"]`), and the user maps it with `-p`. The Dockerfile has
  `EXPOSE 80` as a convention only. Databases / internal services should not publish ports.
  No built-in reverse proxy.
- **Privileges:** Vault must run with `--privileged`, or with the Sysbox runtime
  (`--runtime=sysbox-runc`, safer). The README must keep a Security section explaining the
  risks of `--privileged` (host escape, device access, no seccomp/AppArmor, unusable on
  most managed platforms). Never expose the inner Docker socket over TCP.

### Release (CircleCI)

Modelled after the `navi` project:

- Release jobs only run on `X.Y.Z` tags (`branches: ignore: /.*/`).
- Chain: `check-version-tag` + `build-and-test` → `build-and-release` → `update-description`.
- `check-version-tag`: tag must match the `VERSION` file and the README `**Current Version:**`
  line; `scripts/bump_version.sh X.Y.Z` updates both.
- `build-and-release`: `make release TAG=$CIRCLE_TAG` — multi-arch (`linux/amd64`,
  `linux/arm64`) with `docker buildx`, pushes `darthjee/vault:<version>` and `:latest`.
- `update-description`: pushes `DOCKERHUB_DESCRIPTION.md` via `darthjee/scripts`' `docker_hub.sh`.
- On PRs / branches: build the image, run `shellcheck`, and a smoke test (start Vault
  `--privileged` with a tiny compose file, `curl` the exposed port, stop it). Docker jobs use
  `machine: true`.
- Credentials: `DOCKER_HUB_USERNAME`, `DOCKER_HUB_PASSWORD` (CircleCI project env vars).
- Makefile targets: `build-image`, `lint` (shellcheck), `test` (bats), `test-image`, `release TAG=x` (fails fast without `TAG`),
  `update-description`.

### Future work

- **CLI** to run Vault containers: handles volume mounting, and detects Sysbox
  (`docker info --format '{{json .Runtimes}}'` lists `sysbox-runc`) — uses
  `--runtime=sysbox-runc` when available, otherwise falls back to `--privileged` with a
  visible warning; a flag (e.g. `--runtime=sysbox|privileged`) forces either mode.

## Documentation

All project documentation lives under [`docs/agents/`](docs/agents/):

| File | Contents |
|------|----------|
| [Folder Structure](docs/agents/folder-structure.md) | Top-level directory layout and the role of each folder. |
| [Architecture](docs/agents/architecture.md) | Source layout, modules, code style, and implementation guidelines. |
| [Flow](docs/agents/flow.md) | Main runtime flow of the application. |
| [Contributing](docs/agents/contributing.md) | Commit guidelines, PR standards, code organization, and refactoring rules. |
| [Plans](docs/agents/plans/) | Implementation plans for ongoing or upcoming features. |
| [Issues](docs/agents/issues/) | Detailed specs for open issues. |

### Issues (`docs/agents/issues/`)

Each file documents an issue in detail. Naming convention:

```
docs/agents/issues/<issue_id>_<issue_name>.md
```

Example: `docs/agents/issues/5_release_docker_image.md` for issue #5.

### Plans (`docs/agents/plans/`)

Each plan is a directory named after the issue ID and topic, containing one or more related files:

```
docs/agents/plans/<issue_id>_<topic>/<related_files>.md
```

Example: `docs/agents/plans/12_add-auth/plan.md` for issue #12.

## Agents

Specialist sub-agents live in [`.claude/agents/`](.claude/agents/):

| Agent | Scope |
|-------|-------|
| `architect` | Coordinator: root-level files, `.github/`, `.claude/`, cross-cutting decisions; fallback for `docs/agents/` |
| `product-owner` | `docs/agents/` — issue specs, plans, project documentation |
| `dev` | `Dockerfile`, `source/`, `test/` — the image, the entrypoint and its tests |
| `automation` | `.circleci/`, `Makefile`, `scripts/`, `VERSION`, `DOCKERHUB_DESCRIPTION.md` — build, release, publishing |
