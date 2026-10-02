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
