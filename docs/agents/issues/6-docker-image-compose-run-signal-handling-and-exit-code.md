# Issue: Docker image: compose run, signal handling and exit code

## Description
Part of epic #2; depends on #5 (closed). This completes the Vault entrypoint: it runs `docker compose`, handles SIGTERM / SIGINT and exits with compose's exit code. It follows [docs/agents/specs/docker-image/image.md](../specs/docker-image/image.md) (entrypoint flow steps 5–7, exit codes, edge cases 6–8) and [docs/agents/flow.md](../flow.md) (steps 4–6). Owning agent: `dev`.

## Problem
`source/bin/entrypoint.sh` still ends with a placeholder (`wait "$DOCKERD_PID"`) once dockerd is ready and images are preloaded. Nothing runs the compose stack yet, signals are not handled, and the exit code says nothing about the stack. The entrypoint runs as PID 1, so a signal with no trap is ignored and `docker stop` only works by timing out and sending SIGKILL.

## Expected Behavior
- **No args** → `docker compose up "${COMPOSE_UP_ARGS[@]}"`; **with args** → `docker compose "$@"` (passthrough, e.g. `docker run vault config`). Both run from `/vault`.
- `COMPOSE_UP_ARGS` is split on whitespace with `read -ra`. There is **no quoting support**; the README must say so.
- **Compose exits on its own** (`up` or passthrough): stop dockerd only (**no `compose down`**), then exit with compose's exit code. This covers edge case 6: with no compose file, compose prints its own error and Vault exits with compose's code.
- **SIGTERM / SIGINT while compose is running**: `docker compose down`, then stop dockerd and wait for it, then exit with compose's exit code (0 on a clean `docker stop`; #7 asserts this).
- **Signal before compose has started** (edge case 7), e.g. while waiting for dockerd or loading images: stop dockerd (if started) and exit with `128 + signal number` (143 for SIGTERM, 130 for SIGINT). Record this in the spec's exit-code table.
- **Second signal during shutdown** (edge case 8): ignored; the shutdown already running continues.
- If `compose down` fails during shutdown: print a warning to stderr, still stop dockerd, and still exit with compose's exit code.

## Solution
- `source/lib/compose.sh` (functions only, like the other libs):
  - `compose_run [args...]`: with no args, starts `docker compose up "${COMPOSE_UP_ARGS[@]}"`; with args, starts `docker compose "$@"`. It runs in the **background** and stores the PID (e.g. `COMPOSE_PID`), so bash can run the trap at once instead of waiting for a foreground child to finish.
  - `compose_down`: runs `docker compose down`.
- `source/lib/signals.sh`:
  - `signals_install`: traps SIGTERM / SIGINT. The handler sets the traps to ignore first (edge case 8), then runs the shutdown.
  - Shutdown sequence: if compose started, `compose_down` (a failure only warns), then `dockerd_stop "$DOCKERD_PID"` if dockerd started. With compose running, the entrypoint then waits for compose and exits with its code. Otherwise it exits with `128 + signal number`.
- `source/bin/entrypoint.sh`:
  - Install the traps **before** the pre-checks / dockerd start, so a signal at any point is handled.
  - Parse `COMPOSE_UP_ARGS` into a bash array with `read -ra`.
  - Replace the placeholder: `cd /vault`, start compose, `wait` for it (looping again if the wait was cut short by a trapped signal) to get its real exit code, stop dockerd, exit with that code.
  - Keep reading the environment only in the entrypoint (the libs take arguments / globals as today).
- Update `docs/agents/specs/docker-image/image.md`: fill in the "Signal before compose started" row (`128 + signal`) and the decision that a failing `compose down` keeps compose's exit code.
- Tests: `test/lib/compose.bats` and `test/lib/signals.bats` in the same style as the existing bats files, with `docker` (and `dockerd_stop` where needed) stubbed. Cover: no-args vs passthrough, `COMPOSE_UP_ARGS` splitting (empty, several words), `compose_down`, the shutdown order (down before dockerd stop), signal before compose started, ignoring a second signal, and a failing `compose down`.

### Done when
`make lint`, `make test` and `make build-image` pass. Running the image `--privileged` with a compose file in `/vault` starts the stack, and `docker stop` shuts it down cleanly with exit code 0. The end-to-end smoke test itself belongs to #7.

## Benefits
Vault becomes usable end to end: the stack starts on boot, `docker stop` cleanly tears down the inner stack and daemon instead of being SIGKILLed after the grace period, and outer orchestrators see the real compose exit code.
