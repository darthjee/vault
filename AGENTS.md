# Project Instructions

**Vault** is a Docker image that runs a Docker daemon inside itself (Docker-in-Docker)
and starts a `docker compose` stack on boot. Other projects use it to ship a
stand-alone application: the application, its database and any other dependency
run inside a single Vault container that exposes one port. A host-side `vault` CLI
(bash 3.2+, Linux and macOS) builds the `docker run` for the user.

## Stack

- Docker-in-Docker, based on a pinned `docker:<version>-dind` image (Alpine)
- `docker compose` (plugin bundled in the base image)
- Bash for the entrypoint and scripts (`bash` is installed via `apk`); linted with `shellcheck`, unit-tested with `bats-core`
- Bash 3.2+ for the `vault` CLI (`cli/`) and its installer (`install.sh`); their tests also run
  on a bash 3.2 test image (`test/bash32/`), and the zsh completion is syntax-checked with
  `zsh -n` on `ZSH_IMAGE`
- Make for build / lint / test / release targets
- CircleCI for CI and releases; images published to Docker Hub as `darthjee/vault`

## Design

### Runtime flow (entrypoint)

A SIGTERM / SIGINT trap is installed first, so a signal at any point runs the shutdown sequence.

0. Pre-checks, before `dockerd` is started: `VAULT_DOCKERD_TIMEOUT` must be a positive
   integer, and a tmpfs mount probe checks the container has the privileges `dockerd` needs
   (it succeeds under both `--privileged` and Sysbox). Either failure exits `1` with a message.
1. Start `dockerd` in the background (reusing the base image's `dockerd-entrypoint.sh`,
   with `DOCKER_TLS_CERTDIR=""`), passing an explicit `--host=unix:///var/run/docker.sock`
   so the inner daemon has no TCP listener.
2. Wait until `docker info` succeeds, up to `VAULT_DOCKERD_TIMEOUT` seconds (default 30).
   On timeout, stop `dockerd` and fail with a hint: `dockerd failed to start; are you running with --privileged (or the sysbox runtime)?`
3. `docker load` every `/vault/images/*.tar` (optional offline preload; a missing folder
   is skipped, a failing tarball stops `dockerd` and exits `1`, naming the file).
4. Run `docker compose` from `/vault` in the background and `wait` for it:
   - no arguments → `docker compose up ${COMPOSE_UP_ARGS}`
   - with arguments → `docker compose "$@"` (e.g. `docker run vault up --build`, `docker run vault config`)
5. Stop:
   - **compose exits on its own** → stop `dockerd` only (no `docker compose down`);
   - **SIGTERM / SIGINT** → `docker compose down` (a failure only warns), then stop `dockerd`.
   A signal received before compose has started stops `dockerd` (if started) and exits with
   `128 + signal` (143 / 130). A second signal during shutdown is ignored.
6. Exit with compose's exit code.

### Conventions

- **`/vault` is the working directory.** The user mounts (or a derived image `COPY`s)
  the `docker-compose.yml` and any files it needs there. Relative paths resolve against `/vault`.
- **Bind mounts in the inner compose file refer to the outer container's filesystem**,
  not the host's — anything the inner stack needs must be mounted into the outer container first.
- **Compose's own env vars are the configuration surface:** `COMPOSE_FILE`
  (`:`-separated list allowed), `COMPOSE_PROJECT_NAME`. Vault adds only
  `COMPOSE_UP_ARGS` (whitespace split into a bash array with `read -ra`; **no quoting
  support**) and `VAULT_DOCKERD_TIMEOUT` (positive integer, default 30).
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

### CLI

The `vault` CLI is a host-side client: it builds the `docker run` of a Vault image for the
user. Details: [Architecture](docs/agents/architecture.md) and [Flow](docs/agents/flow.md);
user docs: the README `## CLI` section.

- **Source and packaging:** `cli/bin/vault` (entry point; the only script that reads the
  environment, `PWD`, `DOCKER_HOST` and `.vaultrc`) plus `cli/lib/*.sh` (function libraries),
  bundled into the single file `build/vault` by `scripts/bundle_cli.sh` (`make bundle-cli`).
  The image ships it as `/usr/local/bin/vault`, with the completions
  (`cli/completion/vault.bash`, `_vault`) in `/usr/local/share/vault/completion/`.
- **Commands:** `up` (detached unless `-f`), `down` (keeps the data volume), `logs`,
  `status`, `compose` (`docker exec ... docker compose`), `run` (one-shot `docker run --rm`,
  refused while the instance runs), `version`, `help`.
- **Instance identity:** a name (`--name`, else `.vaultrc` `name=`, else the image name with
  `--image` and no `[dir]`, else the sanitized basename of `[dir]` / `$PWD`) gives the
  container `vault-<name>` and the data volume `vault-<name>-data` on `/var/lib/docker`.
- **Runtime selection** (`up`, `run`): `--runtime auto|sysbox|privileged`, default `auto`.
  `auto` uses `--runtime=sysbox-runc` when `docker info` lists it, else `--privileged` with a
  warning. A forced `sysbox` without Sysbox fails; a failed Sysbox run never escalates to
  `--privileged`. Rootless Docker is refused.
- **Guardrails** (exit 2, flags and `.vaultrc` alike): no mount of the host Docker socket, no
  published container port 2375 / 2376.
- **Configuration:** flags > `.vaultrc` > built-in defaults; a repeatable flag replaces every
  `.vaultrc` entry of its key. `.vaultrc` (in `[dir]`, else `$PWD`) is parsed, **never
  sourced**. `.vault.env` is passed as the first `--env-file` of `up` / `run`.
- **Privilege model:** runs as the current user, never calls `sudo`, writes nothing on the
  host. Only `install.sh` writes (the install and completion dirs).
- **Distribution:** `install.sh` (`curl | bash`) runs
  `docker run --user "$(id -u):$(id -g)" --entrypoint vault-install` (the image's
  `source/bin/install.sh`, no root, no `--privileged`) on a staging dir, then moves the CLI
  to `~/.local/bin/vault` and the completions to `~/.local/share/vault/completion/`.
  `vault-install` is an image entry, not a `vault` subcommand. GitHub releases carry
  `vault`, `install.sh`, `vault.bash`, `_vault` and `SHA256SUMS`.
- **Versioning:** `cli/bin/vault` and `install.sh` each hold one `VAULT_VERSION="X.Y.Z"`
  line, stamped by `scripts/bump_version.sh` and checked by `scripts/check_tag_version.sh`.
  `docs/guides/vault.md` likewise holds one `**Vault version:** X.Y.Z` line, stamped and
  checked by the same scripts.

### Release (CircleCI)

Modelled after the `navi` project:

- Release jobs only run on `X.Y.Z` tags (`branches: ignore: /.*/`).
- Chain: `check-version-tag` + `build-and-test` → `build-and-release` → `update-description`
  and `github-release` (in parallel).
- `check-version-tag`: tag must match the `VERSION` file, the README `**Current Version:**`
  line, the `VAULT_VERSION="X.Y.Z"` lines of `cli/bin/vault` and `install.sh` and the
  `**Vault version:**` line of `docs/guides/vault.md`;
  `scripts/bump_version.sh X.Y.Z` updates all of them.
- `build-and-release`: `make ci-release-setup` (buildx/QEMU setup + `docker login`), then
  `make release TAG=$CIRCLE_TAG` — multi-arch (`linux/amd64`,
  `linux/arm64`) with `docker buildx`, pushes `darthjee/vault:<version>` and `:latest`.
- `update-description`: pushes `DOCKERHUB_DESCRIPTION.md` via `darthjee/scripts`' `docker_hub.sh`.
- `github-release`: `make github-release TAG=$CIRCLE_TAG` (`scripts/github_release.sh`) — builds
  the CLI bundle, creates a published GitHub release marked Latest with generated notes (or keeps
  an existing one), and uploads `vault`, `install.sh`, `vault.bash`, `_vault` and `SHA256SUMS`
  with `--clobber`, using the `gh` CLI from the machine image. A failure never rolls back the
  Docker image; the job can be re-run.
- On PRs / branches: the `build-and-test` job runs `make lint`, `make test`,
  `make test-docs` (link check of `docs/guides/`, `scripts/check_guides_links.sh`),
  `make test-image` (build the image, then start Vault `--privileged` with a tiny compose file,
  `curl` the exposed port, stop it) and then `make test-cli-e2e` (drive the bundled CLI
  `up` / `status` / `compose ps` / `down` against that image, then `install.sh` from it).
  Docker jobs use the `machine: image: ubuntu-2404:current` executor (the bare `machine: true` form is deprecated).
- Credentials: `DOCKER_HUB_USERNAME`, `DOCKER_HUB_PASSWORD`, stored in the restricted
  CircleCI context `docker-hub` (not project env vars) and attached only to the release jobs
  `build-and-release` and `update-description`. `GITHUB_TOKEN` (passed to `gh` as `GH_TOKEN`)
  lives in the restricted context `github`, attached only to `github-release`. PR jobs never
  receive any of them.
- CircleCI YAML only sets up executors, contexts and filters and calls make targets; any
  logic lives in `scripts/*.sh`, and CI-only wrappers (`docker login`, buildx/QEMU setup,
  fetching `docker_hub.sh`) live in `scripts/ci/`.
- Makefile targets: `bundle-cli` (`build/vault`), `build-image` (runs `bundle-cli` first),
  `lint` (shellcheck), `test` (bats, including bash 3.2 and `zsh -n`), `test-docs` (link
  check of `docs/guides/`, run on the host), `test-image`,
  `test-cli-e2e` (after `test-image` in CI),
  `bump-version VERSION=X.Y.Z`, `check-version-tag TAG=X.Y.Z`, `release TAG=x` (fails fast
  without `TAG`), `github-release TAG=X.Y.Z` (fails fast without `TAG`), `update-description`,
  `ci-release-setup` (CI-only).
  Variables: `SHELLCHECK_IMAGE`, `BATS_IMAGE`, `BASH32_TEST_IMAGE`, `ZSH_IMAGE`, `IMAGE`,
  `SMOKE_TIMEOUT`, `RELEASE_IMAGE`, `PUSH`, `DOCKER_VERSION` (build arg for the pinned
  `docker:<version>-dind` base).

### Future work

- **Vulnerability scanning** of the published image.
- **Sysbox in CI:** CI smoke-tests only `--privileged` today.
- **Renovate / Dependabot** for the pinned images (`docker:*-dind`, shellcheck, bats).
- **CLI:**
  - `vault up --wait` (wait for the inner stack to be ready);
  - a Homebrew tap;
  - Windows support;
  - `vault build` / `vault pack` (bake a stack into a derived image);
  - self-update and uninstall;
  - `vault ls` (list instances);
  - remote Docker hosts (`DOCKER_HOST`, contexts);
  - coloured output.

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
| [Specs](docs/agents/specs.md) | Spec hub: what a spec is, naming, precedence, and the list of active specs (`specs/`). |

### Issues (`docs/agents/issues/`)

Each file documents an issue in detail. Naming convention:

```
docs/agents/issues/<issue_id>-<slug>.md
```

Example: `docs/agents/issues/10-readme-agent-docs-sync-and-spec-removal.md` for issue #10.

### Plans (`docs/agents/plans/`)

Each plan is a directory named after the issue ID and slug, containing `plan.md` and one or more related files:

```
docs/agents/plans/<issue_id>-<slug>/plan.md
```

Example: `docs/agents/plans/10-readme-agent-docs-sync-and-spec-removal/plan.md` for issue #10.

## Agents

Specialist sub-agents live in [`.claude/agents/`](.claude/agents/):

| Agent | Scope |
|-------|-------|
| `architect` | Coordinator: root-level files (except `install.sh`), `.github/`, `.claude/`, cross-cutting decisions; fallback for `docs/agents/` |
| `product-owner` | `docs/agents/` (incl. `specs/`), `docs/guides/` — issue specs, plans, project documentation, user guides |
| `dev` | `Dockerfile`, `source/` (incl. `source/bin/install.sh`), `test/lib/`, `test/fixture/` and the image tests — the image, the entrypoint, the in-image install entry and their tests |
| `automation` | `.circleci/`, `Makefile`, `scripts/`, `VERSION`, `DOCKERHUB_DESCRIPTION.md`, `test/bash32/`, `test/scripts/`, `build/` — build, release, publishing |
| `cli` | `cli/` (`bin/vault`, `lib/*.sh`, `completion/*`), root `install.sh`, `test/cli/`, `test/install/` — the `vault` CLI and its installer |
