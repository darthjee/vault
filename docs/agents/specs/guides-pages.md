# Guides Spec: Pages

Part of the [guides spec](guides-overview.md). Fixes the audience, the style and the content of
every page under `docs/guides/`.

## Audience and style

- **Readers:** developers of a consumer project **and** AI agents working in that repo.
- **Style:** plain, task-oriented Markdown. Short sections, tables for mappings, copy-paste
  ready commands.
- **Page header:** every `vault/*.md` page starts with a one-line purpose and a link back to
  `../vault.md`.
- Pages describe the current behaviour of the image and the CLI; content is checked by hand
  against the README sections listed in [guides-readme.md](guides-readme.md) and `AGENTS.md`.
- Links follow [guides-portability.md](guides-portability.md#portability-rules).

## Page list

| Page | Written by |
|------|------------|
| [`vault.md`](#vaultmd) | #42 |
| [`vault/concepts.md`](#conceptsmd) | #42 |
| [`vault/security.md`](#securitymd) | #42 |
| [`vault/docker-run.md`](#docker-runmd) | #43 |
| [`vault/base-image.md`](#base-imagemd) | #43 |
| [`vault/cli.md`](#climd) | #44 |
| [`vault/configuration.md`](#configurationmd) | #45 |
| [`vault/operations.md`](#operationsmd) | #45 |
| [`vault/troubleshooting.md`](#troubleshootingmd) | #45 |
| [`vault/examples.md`](#examplesmd) | #46 |
| [`vault/agents-snippet.md`](#agents-snippetmd) | #46 |

## `vault.md`

- Top block (see [guides-portability.md → Top block](guides-portability.md#top-block)): copy
  the whole tree, where the originals live, the version line.
- What Vault is: a Docker-in-Docker image running a `docker compose` stack in one container
  that exposes one port.
- When to use it (ship an app and its dependencies as one image) and when not (managed
  platforms that refuse privileged containers; see `vault/security.md`).
- **Choosing a path:**
  - image directly (`docker run`, `vault/docker-run.md`) vs. the `vault` CLI (`vault/cli.md`);
  - image as is (mount the project at `/vault`) vs. base image (`vault/base-image.md`).
- Page index: one line per page, filled as each page lands; pages not written yet are named in
  inline code, not linked (see [Sub-issue map](guides-overview.md#sub-issue-map)).

## `concepts.md`

- Docker-in-Docker: an inner `dockerd` started by the entrypoint.
- `/vault` as the working directory; relative paths resolve against it.
- Port flow: host → Vault `80` → inner service (see [Ports](#ports)).
- Bind mounts in the inner compose file refer to the **Vault container's** filesystem, not the
  host's.
- Persistence model: `VOLUME /var/lib/docker`, named volume for the image cache and inner
  named volumes.
- Startup sequence in short: pre-checks, `dockerd`, offline preload, `docker compose`, exit
  code.

## `docker-run.md`

- Sysbox (`--runtime=sysbox-runc`, recommended) vs. `--privileged` (fallback, link to
  `security.md`).
- Mounting the project at `/vault`; the data volume on `/var/lib/docker`.
- Ports (`-p 8080:80`), env vars (`-e`, `--env-file`, link to `configuration.md`).
- Compose passthrough arguments: no arguments → `docker compose up ${COMPOSE_UP_ARGS}`;
  arguments → `docker compose "$@"` (`config`, `ps`, `up --build`).
- Stopping: one short stop-timeout example (`docker stop -t`, `--stop-timeout`), pointing to
  `operations.md` for the full shutdown sequence (stop timeouts are owned by #45).

## `cli.md`

- Install: `curl -fsSL …/install.sh | bash`, pinning `VAULT_VERSION`, installer variables,
  completion and `PATH`, download and verify (`SHA256SUMS`).
- Commands: `up`, `down`, `logs`, `status`, `compose`, `run`, `version`, `help`; exit codes and
  message prefixes.
- Instance naming (`vault-<name>`, `vault-<name>-data`) and the shared-volume warning.
- Runtime selection (`--runtime auto|sysbox|privileged`) and the `--privileged` fallback
  warning.
- Options, `.vaultrc`, `.vault.env`, precedence, guardrails.
- Baked images (`vault up --image`), Docker Desktop file sharing.
- Supported platforms: Linux and macOS, bash 3.2+; Windows not supported.

## `base-image.md`

- `FROM darthjee/vault:<version>` + `COPY . /vault`.
- Offline preload: `/vault/images/*.tar` (`docker save`), `COMPOSE_UP_ARGS="--pull never"` or
  `pull_policy:`.
- Running a baked image with `docker run` and with `vault up --image` (link to `cli.md`).
- No secrets baked into a derived image (link to `configuration.md`).

## `configuration.md`

- Env vars: `COMPOSE_FILE`, `COMPOSE_PROJECT_NAME`, `COMPOSE_UP_ARGS` (whitespace split, no
  quoting), `VAULT_DOCKERD_TIMEOUT` (positive integer, default 30); other `COMPOSE_*`.
- Multiple compose files (`COMPOSE_FILE` `:`-separated list).
- **Secrets handling:** keep `.vault.env` and env files out of git; never bake secrets into a
  derived image; the CLI prints env keys only, never values.

## `operations.md`

- Persistence and the data volume; what is lost without it.
- Shutdown: SIGTERM / SIGINT → `docker compose down` → stop `dockerd`; stop timeouts
  (`docker stop -t`, `--stop-timeout`, CLI default `60`).
- Logs (`docker logs`, `vault logs -f`).
- Running compose commands against a running stack (`docker exec … docker compose`,
  `vault compose`).
- Service failures and `restart:` policies; fail fast with `--abort-on-container-exit`.
- Never share one `/var/lib/docker` volume between two running containers.

## `troubleshooting.md`

- Startup errors (exit `1`) with their exact messages, as in the README `## Behaviour`.
- Exit codes: image (compose's exit code, `128 + signal`) and CLI (`0` / `1` / `2`, inner exit
  code for `compose`, `run`, `up -f`).
- Common mistakes: missing privileges, host paths in inner bind mounts, busy ports, Docker
  Desktop file sharing, two instances sharing a data volume.

## `security.md`

- `--privileged` risks: host escape, device access, no seccomp/AppArmor, refused by most
  managed platforms.
- Sysbox: own user namespace, root inside is not root on the host.
- Root inside the container.
- Never expose the inner Docker socket (no TCP listener, no published 2375 / 2376).
- Do not mount the host's `docker.sock`.
- Secrets (link to `configuration.md`).
- Supported / unsupported runtimes and platforms, architectures (`linux/amd64`,
  `linux/arm64`).

## `examples.md`

Complete worked setups, each with a `docker run` variant and a CLI variant, each stating its
own port mapping:

- app + Postgres;
- app + Redis;
- multiple compose files;
- a baked image with offline preload.

## `agents-snippet.md`

- A short, ready-to-paste block for a consumer repo's `AGENTS.md`.
- Points at the copied guides (relative to where the consumer copies the tree; the snippet
  says to adjust the path).
- States the key rules: privileges (Sysbox preferred, `--privileged` fallback), `/vault`,
  ports, bind mounts refer to the Vault container, secrets stay out of git and images.

## Ports

The CLI default is `-p 3000:80`; the README `docker run` examples use `-p 8080:80`. Both map a
host port to Vault's port `80`.

| Where | Mapping |
|-------|---------|
| `concepts.md` | Explains the port flow: host port → Vault `80` → inner service (`ports: ["80:3000"]`). |
| `docker-run.md`, `base-image.md` | `-p 8080:80`, said on the page. |
| `cli.md` | CLI default `3000:80` (no `-p` needed); `-p` / `port=` to change it. |
| `examples.md` | Each variant states its own mapping (`docker run` → `8080:80`, CLI → `3000:80` unless `-p` is given). |

Every page that shows a port mapping says which one it uses.

## Image tags

- Examples use `darthjee/vault:<version>` as a placeholder.
- `darthjee/vault` / `darthjee/vault:latest` only in quick starts, and the page says so
  explicitly.
