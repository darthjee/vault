# Signals library
Add `source/lib/signals.sh`. It requires `compose.sh` and `dockerd.sh` to be sourced too; say so in the header, as `preflight.sh` does.

- `signals_install` traps TERM → `signals_shutdown 15` and INT → `signals_shutdown 2`.
- `signals_ignore` sets TERM and INT to be ignored (`trap '' TERM INT`).
- `signals_shutdown <signum>`:
  1. `signals_ignore` first, so a second signal does nothing (edge case 8);
  2. increment `SIGNALS_HANDLED`;
  3. **compose running** (`COMPOSE_PID` set): `compose_down`. On failure print `vault: docker compose down failed` (or similar) to stderr and carry on. Then `dockerd_stop "$DOCKERD_PID"` and **return**: the entrypoint's `compose_wait` collects compose's exit code and exits with it.
  4. **compose not started**: `dockerd_stop "$DOCKERD_PID"` if `DOCKERD_PID` is set, then `exit $((128 + signum))`.

Add `test/lib/signals.bats` with `docker` / `dockerd_stop` / `compose_down` stubbed to log calls:

- with `COMPOSE_PID` set: `compose_down` is called before `dockerd_stop`, and the function returns (no exit);
- `compose_down` failing → warning on stderr, `dockerd_stop` still called;
- no `COMPOSE_PID`, `DOCKERD_PID` set → `dockerd_stop` called, exit 143 for 15 / 130 for 2 (use `run`);
- neither set (signal during pre-checks) → no stop, exit 143;
- after `signals_shutdown`, `trap -p TERM` / `INT` show the signals ignored, and `SIGNALS_HANDLED` was incremented;
- `signals_install` registers handlers for both signals.

## Files to Change
- `source/lib/signals.sh` — new library: `signals_install`, `signals_ignore`, `signals_shutdown`.
- `test/lib/signals.bats` — new bats tests.
