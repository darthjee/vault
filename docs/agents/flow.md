# Flow

## Overview

What happens from `docker run --privileged ... darthjee/vault [args]` until the container exits.

1. **Start dockerd** — launched in the background through the base image's `dockerd-entrypoint.sh`.
2. **Wait for dockerd** — poll `docker info` until it succeeds or `VAULT_DOCKERD_TIMEOUT` (default 30s) elapses.
   - Timeout → print `dockerd failed to start; are you running with --privileged (or the sysbox runtime)?` and exit non-zero.
3. **Preload images** — `docker load -i` every `/vault/images/*.tar`. No tarballs → skip.
   - A failing load aborts startup with a non-zero exit.
4. **Run compose** in the foreground, from `/vault`:
   - no args → `docker compose up "${COMPOSE_UP_ARGS[@]}"`
   - args → `docker compose "$@"`
   - Compose pulls missing images and builds services with `build:` as needed.
5. **Shutdown** — on SIGTERM / SIGINT: `docker compose down`, then stop `dockerd` and wait for it to exit.
6. **Exit** — with compose's exit code, so outer orchestrators see failures.

## Service failures

The container exits only when compose exits. A single crashing service is handled by
its compose `restart:` policy. Fail-fast behaviour is opt-in via
`COMPOSE_UP_ARGS="--abort-on-container-exit"`.

## State across restarts

Everything lives under `/var/lib/docker`. Without a mounted volume, each new container
starts empty. With a named volume, pulled images, inner volumes (e.g. database data)
and stopped containers persist, and compose reuses / recreates containers on the next `up`.
