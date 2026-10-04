# Flow

## Overview

What happens from `docker run --runtime=sysbox-runc ... darthjee/vault [args]` (or
`docker run --privileged ...`) until the container exits. The entrypoint is
`source/bin/entrypoint.sh`; the steps are implemented by the libraries in `source/lib/`.

The SIGTERM / SIGINT trap is installed **before step 1**, so a signal at any point runs
the shutdown sequence (see [Edge cases](#edge-cases)).

1. **Pre-checks** (`preflight.sh`)
   - `VAULT_DOCKERD_TIMEOUT` must be a positive integer.
   - Privilege probe: mount a tmpfs on a temporary directory, then unmount and remove it.
     Mounting needs `CAP_SYS_ADMIN`, which both `--privileged` and Sysbox grant; a
     default container fails at once.
2. **Start dockerd** (`dockerd.sh`) — in the background through the base image's
   `dockerd-entrypoint.sh`, with an explicit `--host=unix:///var/run/docker.sock`.
   Without it, the base entrypoint builds its own host list, which with
   `DOCKER_TLS_CERTDIR=""` includes an unauthenticated `tcp://0.0.0.0:2375` listener.
   Vault never listens on TCP.
3. **Wait for dockerd** — poll `docker info` once per second until it succeeds or
   `VAULT_DOCKERD_TIMEOUT` (default 30) polls elapse.
   - Timeout → print `dockerd failed to start; are you running with --privileged (or the sysbox runtime)?`, stop dockerd and exit 1.
4. **Preload images** (`images.sh`) — `docker load -i` every `/vault/images/*.tar`.
   Missing directory or no tarballs → skip.
   - A failing load names the file, stops dockerd and exits 1.
5. **Run compose** (`compose.sh`) from `/vault`, in the background, and `wait` on it so
   traps fire immediately (bash defers traps while a foreground child runs):
   - no args → `docker compose up "${COMPOSE_UP_ARGS[@]}"`
   - args → `docker compose "$@"`
   - `COMPOSE_UP_ARGS` is split on whitespace (`read -ra`), with **no quoting support**.
   - Compose pulls missing images and builds services with `build:` as needed.
6. **Shutdown**
   - **6a. Compose exits on its own** (`up` or a passthrough command) → stop dockerd
     only. **No `compose down`.**
   - **6b. SIGTERM / SIGINT** (`signals.sh`) → `docker compose down`, then stop dockerd
     and wait for it to exit.
7. **Exit** — with compose's exit code (on both 6a and 6b), so outer orchestrators see
   failures.

## Exit codes and messages

Vault's own messages go to stderr.

| Situation | Exit code | Message |
|-----------|-----------|---------|
| Compose exits on its own | compose's exit code | compose's own output |
| SIGTERM / SIGINT after compose started | compose's exit code (0 on a clean `docker stop`) | — |
| Privilege probe fails | 1 | `dockerd failed to start; are you running with --privileged (or the sysbox runtime)?` |
| Invalid `VAULT_DOCKERD_TIMEOUT` | 1 | `VAULT_DOCKERD_TIMEOUT must be a positive integer, got: '<value>'` |
| dockerd timeout | 1 | `dockerd failed to start; are you running with --privileged (or the sysbox runtime)?` Dockerd is stopped first. |
| Tarball load fails | 1 | `failed to load image tarball: <file>`. Dockerd is stopped first. |
| Signal before compose started | `128 + signal`: 143 (SIGTERM), 130 (SIGINT) | — Dockerd is stopped first if it was started. |
| `compose down` fails during shutdown | compose's exit code (unchanged) | `vault: docker compose down failed`; dockerd is still stopped. |

## Edge cases

- **No compose file in `/vault`** — no pre-check: compose prints its own error, then
  Vault stops dockerd and exits with compose's exit code.
- **Second signal during shutdown** — ignored; the shutdown already in progress
  continues. A signal after compose has exited is ignored too.
- **Shutdown longer than `docker stop`'s 10s grace period** — `compose down` may be
  killed. Give more time with `docker stop -t <seconds>` or `docker run --stop-timeout <seconds>`.
- **Shared `/var/lib/docker` volume** — never mount one volume on `/var/lib/docker` of
  two running containers; two daemons on one data root corrupt it. Vault does not detect this.

## Service failures

The container exits only when compose exits. A single crashing service is handled by
its compose `restart:` policy. Fail-fast behaviour is opt-in via
`COMPOSE_UP_ARGS="--abort-on-container-exit"`.

## State across restarts

Everything lives under `/var/lib/docker`. Without a mounted volume, each new container
starts empty. With a named volume, pulled images, inner volumes (e.g. database data)
and stopped containers persist, and compose reuses / recreates containers on the next `up`.

## CLI flow

What happens when a user runs `vault <command> [options] [dir] [args]` on the host. The
entry point is `cli/bin/vault`; the steps are implemented by the libraries in `cli/lib/`.
User-facing wording: [the CLI guide](../guides/vault/cli.md).

1. **Dispatch** — no command prints the usage to stderr (exit 2); `version` and `help` (or
   `-h` / `--help` on any command) print to stdout and exit 0 without touching docker. An
   unknown command exits 2.
2. **Resolution** (every other command, `vault_resolve`):
   1. parse options, `[dir]` and passthrough arguments (`args.sh`); a usage error exits 2;
   2. `[dir]` (else `$PWD`) made absolute; `up` / `run` fail with
      `directory not found: <dir>` (exit 1) when a given `[dir]` does not exist;
   3. read `.vaultrc` from that directory when it exists (parsed from stdin, never sourced);
   4. merge flags > `.vaultrc` > defaults (`config.sh`);
   5. instance name → `vault-<name>` / `vault-<name>-data` (`naming.sh`);
   6. `docker` on `PATH`, else `docker not found in PATH` (exit 1).
3. **`up` / `run` only** (still in `vault_resolve`):
   1. one `docker info`: daemon reachable, rootless refused, Sysbox detected
      (`runtime.sh`), then the runtime selection (`auto` falls back to `--privileged` with a
      warning; a forced `sysbox` without Sysbox exits 1);
   2. guardrails on the merged volumes and ports (`guardrails.sh`, exit 2);
   3. `<dir>/.vault.env`, when it exists, placed as the first `--env-file`;
   4. the ordered `docker run` argument list (`container.sh`): runtime, `--stop-timeout`,
      `-v <dir>:/vault` (skipped for `--image` without `[dir]`),
      `-v vault-<name>-data:/var/lib/docker`, extra `-v`, `-p`, `--env-file`, `-e`, then
      `--name vault-<name> [-d]` (`up`) or `[-i] [-t] --rm` (`run`), the image and (`run`)
      the compose arguments.
4. **`up`** — warns when the mounted dir has no compose file (`COMPOSE_FILE` may point
   elsewhere), then reads the instance state with one `docker inspect`:
   - running → prints `vault-<name> is already running` and the status, exit 0;
   - stopped → `docker rm`, then a fresh run with the current options (the volume is kept);
   - missing → run.
   Detached: `docker run -d`, then `vault-<name> started`. With `-f`: foreground, Ctrl+C only
   reaches docker, so the image's graceful shutdown runs.
5. **`run`** — same compose-file warning; refuses with `instance vault-<name> is running`
   (exit 1) while the instance runs; otherwise `docker run [-i] [-t] --rm` in the foreground,
   passing the compose arguments to the image's entrypoint.
6. **Failed `docker run`** (`up`, `run`) — docker's stderr is shown first. When the container
   did not start (any failure of `up` detached; codes 125 / 126 / 127 for `run` and `up -f`):
   a port conflict adds the `-p HOST:80` hint; under Sysbox, `sysbox-runc failed to start the
   container` + hint (never a retry with `--privileged`); exit 1.
7. **`down` / `logs` / `status` / `compose`** — no `docker info`. One `docker inspect` tells
   running / stopped / missing (`No such object`) / daemon unreachable (exit 1). Then:
   - `down`: `docker stop -t <stop-timeout>` (when running) and `docker rm`, printing
     `vault-<name> stopped and removed (volume vault-<name>-data kept)`; missing → exit 0;
   - `logs`: `docker logs [-f]`; not running → exit 1;
   - `status`: the status block (`docker inspect` + `docker image inspect` for env keys),
     exit 0 in every state;
   - `compose`: `docker exec [-i] [-t] vault-<name> docker compose <args>`; not running →
     exit 1.

### Install flow

`curl -fsSL .../install.sh | bash` (root `install.sh`):

1. Resolve `VAULT_VERSION` (default: the stamped line), `VAULT_IMAGE`
   (`darthjee/vault:<version>`) and `VAULT_INSTALL_DIR` (`$HOME/.local/bin`).
2. Check `docker` is on `PATH` and the daemon is reachable; create the install dir and check
   it is writable (exit 1 otherwise).
3. Create a `mktemp -d` staging dir (removed on exit).
4. `docker run --rm --user "$(id -u):$(id -g)" --entrypoint vault-install -v <staging>:/install <image>`
   (docker pulls the image when missing). The entry copies `vault` and
   `completion/{vault.bash,_vault}` into `/install`, as the host user, without starting
   `dockerd`.
5. Move `vault` into the install dir and the completions into
   `~/.local/share/vault/completion/`, then print the result and the completion lines.
6. Warn, without failing, when the install dir is not in `PATH`, printing the
   `export PATH=...` line to add.

### CLI exit codes and messages

Diagnostics go to stderr, prefixed `vault: error: `, `vault: warning: ` or `vault: hint: `;
normal output goes to stdout.

| Situation | Exit code | Example message |
|-----------|-----------|-----------------|
| Success, including no-ops (`up` already running, `down` / `status` of a missing instance) | 0 | `vault-<name> started` |
| Usage error: unknown command / option, unexpected argument, bad or missing value, empty sanitized name | 2 | `unknown option '<option>'` |
| Guardrail refusal | 2 | `refusing to mount the Docker socket (<src>)`, `refusing to publish the Docker daemon port <port>` |
| `docker` missing, daemon unreachable, rootless Docker | 1 | `docker not found in PATH`, `cannot reach the Docker daemon` |
| Forced Sysbox missing, Sysbox run failed, port in use | 1 | `--runtime=sysbox requested but sysbox-runc is not available` |
| Instance not running (`logs`, `compose`), `run` while running, missing `[dir]` | 1 | `instance vault-<name> is not running` |
| Malformed `.vaultrc` | 1 | `.vaultrc:<line>: expected key=value` |
| `compose`, `run`, `up -f` once the container started | the inner command's code | — |
| Install: install dir not writable, docker missing, `vault-install` failed | 1 | `<dir> is not writable` |
