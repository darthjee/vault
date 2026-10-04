# Architecture

## Overview

Vault is a Docker-in-Docker image. Its container runs an inner `dockerd` and a
`docker compose` stack described by files mounted into (or copied to) `/vault`.
The outer container exposes one port; inside it, the application and its
dependencies (database, cache, ...) run as ordinary compose services.

```
host ──-p 8080:80──▶ Vault container (dockerd + compose)
                        ├── app   (ports: ["80:3000"])
                        └── db    (no published ports)
```

## Image

- Base: `docker:29.8.2-dind` (Alpine), which ships `dockerd`, the docker CLI and the compose / buildx plugins. Overridable with the `DOCKER_VERSION` build arg (`make build-image DOCKER_VERSION=X.Y.Z`).
- All images (base, shellcheck, bats, smoke-test fixture) are pinned by tag, not by digest.
- `bash` added via `apk`.
- `ENV DOCKER_TLS_CERTDIR=""`.
- `VOLUME /var/lib/docker` (required: overlay2 cannot run on top of the container's overlay filesystem).
- `WORKDIR /vault`, `EXPOSE 80` (convention only).
- Built for `linux/amd64` and `linux/arm64` by the release.

### Image paths

| Path | Contents |
|------|----------|
| `/usr/local/lib/vault/` | Libraries from `source/lib/`. |
| `/usr/local/bin/vault-entrypoint` | `source/bin/entrypoint.sh`; the image `ENTRYPOINT`. |
| `/usr/local/bin/vault` | The bundled CLI (`build/vault`), copied out by the install entry. |
| `/usr/local/bin/vault-install` | `source/bin/install.sh`; the install entry (`--entrypoint vault-install`). |
| `/usr/local/share/vault/completion/` | `vault.bash` and `_vault` (mode `0644`), from `cli/completion/`. |
| `/vault` | `WORKDIR`; compose file(s) and their files. |
| `/vault/images` | Optional `*.tar` images preloaded before compose starts. |

## Source Code Layout

The image's own scripts live under `source/`; the CLI (`cli/`) is described in [CLI](#cli).

### `source/bin/`

Two entry points:

- `entrypoint.sh` — the container entrypoint. Reads the environment (`COMPOSE_UP_ARGS`,
  `VAULT_DOCKERD_TIMEOUT`), sources the libraries and orchestrates the flow described in
  [flow.md](flow.md).
- `install.sh` — the install entry (`vault-install`). Copies the bundled CLI and the
  completions into the bind-mounted `/install` dir, as the host user (`--user`). Takes no
  arguments, never starts `dockerd`, exits `0` silently or `1` with
  `vault-install: error: ...`.

### `source/lib/`

Function libraries; sourcing them has no side effects.

| File | Responsibility |
|------|----------------|
| `preflight.sh` | Fast checks before dockerd starts: validate the timeout (positive integer), tmpfs mount probe for privileges. |
| `dockerd.sh` | Start `dockerd` (via the base image's `dockerd-entrypoint.sh`) with an explicit `--host=unix:///var/run/docker.sock`, wait for it with a timeout, stop it. |
| `images.sh` | `docker load` every tarball in a given directory. |
| `compose.sh` | Run the `docker compose` command in the background (default `up` + extra args, or passthrough args), wait on it, and provide `down`. No `down` when compose exits on its own; `down` runs only on the signal path. |
| `signals.sh` | Trap SIGTERM / SIGINT and run the shutdown sequence (`compose down`, then stop dockerd). |
| `install.sh` | `install_copy`: copy the CLI (`0755`) and the completions (`0644`) into a target dir; fails when it is not a writable dir. Used by `source/bin/install.sh`. |

## CLI

The host-side `vault` CLI builds the `docker run` of a Vault image for the user. Commands and
user-facing behaviour: README `## CLI`; runtime flow: [flow.md → CLI flow](flow.md#cli-flow).

### Layout

- `cli/bin/vault` — the entry point. The **only** file that reads `.vaultrc`, the environment,
  `PWD` and `DOCKER_HOST`; it dispatches the commands and resolves everything a command needs
  (`vault_resolve`).
- `cli/lib/*.sh` — function libraries. Sourcing them only defines functions; they take values
  as arguments and return results in `UPPER_CASE` globals (`ARGS_*`, `CONFIG_*`,
  `NAMING_NAME`, `RUNTIME_*`, `CONTAINER_ARGS`, `INSTANCE_*`). They open no file and read no
  environment variable (the `.vaultrc` parser reads stdin).

| File | Responsibility |
|------|----------------|
| `output.sh` | Diagnostics on stderr: `output_error`, `output_warning`, `output_hint`. |
| `usage.sh` | The usage text (`usage_print`). |
| `docker.sh` | `docker_run_cmd`: every docker call goes through it, so tests can stub it. |
| `args.sh` | Parse options, `[dir]` and passthrough arguments; validate names, runtimes, stop timeouts. |
| `naming.sh` | Resolve and sanitize the instance name; `vault-<name>` and `vault-<name>-data`. |
| `config.sh` | Parse `.vaultrc` (never sourced), merge flags > `.vaultrc` > defaults, place `.vault.env` first. |
| `guardrails.sh` | Refuse a Docker socket mount and container ports 2375 / 2376 (exit 2). |
| `runtime.sh` | `docker` on `PATH`, one `docker info` (runtimes, rootless), runtime selection. |
| `container.sh` | Build the ordered `docker run` argument list of `up` and `run`. |
| `instance.sh` | Instance state (`docker inspect`), TTY flags, status output, `docker run` result attribution. |

### Bundling

`scripts/bundle_cli.sh` (`make bundle-cli`) replaces the `# BEGIN LIBS` / `# END LIBS` block
of `cli/bin/vault` with the libraries, concatenated in a fixed order (not glob order), into the
self-contained executable `build/vault` (mode `0755`). Every `cli/lib/*.sh` must be listed in
that order. `make build-image` and `make release` bundle first; the image ships the bundle as
`/usr/local/bin/vault`.

### Constraints

- **bash 3.2+** (stock macOS bash): indexed arrays only — no associative arrays, no
  `mapfile` / `readarray`, no `${var,,}` / `${var^^}`, no `compopt`. Empty arrays are expanded
  with `${a[@]+"${a[@]}"}` under `set -u`.
- Linux and macOS only; not Windows.
- No `sudo`; nothing is written on the host by the CLI.

### Messages and exit codes

- Diagnostics go to stderr, prefixed `vault: error: `, `vault: warning: ` or `vault: hint: `
  (a hint on its own line, after its error). Normal output (`status`, `version`, `help`,
  `started`, `already running`, `stopped and removed`) goes to stdout. No colours.
- Docker's own errors are passed through unchanged, before the CLI's message.

| Code | Meaning |
|------|---------|
| 0 | Success, including no-ops (`up` already running, `down` / `status` on a missing instance). |
| 1 | Runtime or environment error: docker missing, daemon unreachable, rootless, instance not running, `docker run` failed to start the container, missing `[dir]`, malformed `.vaultrc`. |
| 2 | Usage error: unknown command or option, bad or missing value, guardrail refusal, empty sanitized name. |
| passthrough | `compose`, `run` and `up -f` exit with the inner command's code once the container has started (docker's own 125 / 126 / 127 are attributed as start failures). |

### Completion

`cli/completion/vault.bash` (bash 3.2+, `complete -F _vault_complete vault`) and
`cli/completion/_vault` (zsh). Not bundled into `build/vault`; mode `0644`. They complete the
commands, each command's options, `--runtime` values, files for `--env-file` and `-v`,
directories for `[dir]`, and instance names for `--name` (from `docker ps -a`, silently
nothing when docker fails).

## Installer

- `install.sh` (repo root, owner `cli`) is self-contained for `curl | bash`: it sources
  nothing and runs everything from `main`, called on the last line, so a truncated download
  runs nothing.
- Environment: `VAULT_VERSION` (default: its own stamped `VAULT_VERSION` line),
  `VAULT_INSTALL_DIR` (default `$HOME/.local/bin`), `VAULT_IMAGE` (default
  `darthjee/vault:$VAULT_VERSION`).
- Steps: check `docker` and the daemon, create / check the install dir is writable, create a
  `mktemp -d` staging dir, run
  `docker run --rm --user "$(id -u):$(id -g)" --entrypoint vault-install -v <staging>:/install <image>`,
  move the CLI to the install dir and the completions to `~/.local/share/vault/completion/`,
  print the result and the completion lines, then warn (never fail) when the install dir is
  not in `PATH`. The staging dir is always removed. It never calls `sudo`.
- **Release assets** (`scripts/github_release.sh`, on `X.Y.Z` tags): `vault` (the bundle),
  `install.sh`, `vault.bash`, `_vault` and `SHA256SUMS` (checksums of the four, file names
  only).
- **Versioning:** `cli/bin/vault` and `install.sh` each hold one `VAULT_VERSION="X.Y.Z"` line,
  updated by `scripts/bump_version.sh` and checked against the tag by
  `scripts/check_tag_version.sh`. The CLI's default image is `darthjee/vault:<VAULT_VERSION>`.

## Configuration

| Variable | Owner | Default | Purpose |
|----------|-------|---------|---------|
| `COMPOSE_FILE` | compose | `docker-compose.yml` in `/vault` | Compose file(s), `:`-separated. |
| `COMPOSE_PROJECT_NAME` | compose | `vault` (dir name) | Project name. |
| `COMPOSE_UP_ARGS` | Vault | empty | Extra args for the default `up` (e.g. `--abort-on-container-exit`, `--pull never`). Split on whitespace (`read -ra`), **no quoting support**. |
| `VAULT_DOCKERD_TIMEOUT` | Vault | `30` | Seconds to wait for `dockerd`. Must be a positive integer; otherwise Vault fails fast before starting dockerd. |

## Runtime requirements

| Topic | Decision |
|-------|----------|
| Supported runtimes | Sysbox, `--runtime=sysbox-runc` (recommended); `--privileged` (fallback). |
| Unsupported | Rootless; hand-picked capabilities (`--cap-add`); mounting the host's `docker.sock`. |
| Host must provide | cgroup nesting; a volume on `/var/lib/docker` (guaranteed by `VOLUME`); one published port. |
| Where it runs | Docker Desktop and Linux hosts. **Not** most managed platforms (ECS Fargate, Cloud Run, Kubernetes without privileged pods). |
| CI coverage | The smoke test runs only `--privileged`; Sysbox is checked manually. |

See the [README Security section](../../README.md#security) for the risks of `--privileged`.

## Security

- The inner daemon listens on the unix socket only; it never listens on TCP. The smoke test asserts that nothing listens on 2375.
- The container runs as root; see the [README Security section](../../README.md#security).

## Testing

| Layer | Command | Covers |
|-------|---------|--------|
| Lint | `make lint` | shellcheck over every `*.sh` / `*.bats` under `source/`, `scripts/`, `cli/` and `test/`, plus `cli/bin/vault`, `cli/completion/vault.bash` and `install.sh`. |
| Unit | `make test` | Builds `build/vault`, then bats on `BATS_IMAGE` over `test/lib/` (`source/lib/` functions), `test/cli/` (CLI and completion), `test/install/` (`install.sh`) and `test/scripts/` (repo scripts), with external commands (`docker`, `mount`, `gh`, ...) stubbed; `test/cli/` and `test/install/` again on the bash 3.2 image built from `test/bash32/`; `zsh -n` on `cli/completion/_vault` (`ZSH_IMAGE`). |
| Smoke | `make test-image` | `scripts/test_image.sh` with the fixture `test/fixture/docker-compose.yml`: build the image, run it `--privileged`, `curl` the published port, assert no listener on 2375, `docker stop` and expect exit 0, then always clean up. |
| End-to-end | `make test-cli-e2e` | `scripts/test_cli_e2e.sh` with the same fixture: run the real bundled `build/vault` `up` / `status` / `compose ps` / `down` against the built image (`--runtime=privileged`, a free localhost port, a unique `e2e-<pid>` name, volume kept after `down`), then run `install.sh` from the local image into a temp `HOME`; cleanup always runs. Last line `test-cli-e2e: OK`. |

Not covered by CI: Sysbox at runtime and arm64 at runtime (built by the release, not run).
