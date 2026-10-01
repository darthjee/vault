# Compose library
Add `source/lib/compose.sh`. Like the other libs, sourcing it only defines functions:

- `compose_run [args...]` starts compose in the **background** and stores its PID in the global `COMPOSE_PID` (read by the entrypoint and the signal handler, the same pattern as `DOCKERD_PID`):
  - no args → `docker compose up "${COMPOSE_UP_ARGS[@]}"`. `COMPOSE_UP_ARGS` is a bash **array** set by the entrypoint and may be empty or unset. Guard the expansion so it is safe under `set -u`.
  - args → `docker compose "$@"`.
  - Redirect stdin explicitly (`<&0`) so the background job keeps the container's stdin.
- `compose_down` runs `docker compose down` and returns its status (the caller decides how to react).
- `compose_wait <pid>` waits for compose and prints / returns its real exit code. It re-runs `wait "$pid"` while a trapped signal interrupted the previous `wait` (detected through `SIGNALS_HANDLED`, a counter the signal handler increments, defaulting to 0). It must work under `set -e` (`wait … || status=$?`).

Add `test/lib/compose.bats`, written like `test/lib/dockerd.bats` (`CALLS_FILE`, `docker` stubbed as a function):

- no args with an empty / unset array → `docker compose up` with no extra args;
- no args with `COMPOSE_UP_ARGS=(--build --abort-on-container-exit)` → both passed as separate args;
- passthrough args → `docker compose config` / args with spaces stay single args;
- `compose_down` calls `docker compose down` and propagates a failure;
- `compose_wait` returns the background job's exit code (e.g. stub exits 3 → 3).

## Files to Change
- `source/lib/compose.sh` — new library: `compose_run`, `compose_down`, `compose_wait`.
- `test/lib/compose.bats` — new bats tests with a stubbed `docker`.
