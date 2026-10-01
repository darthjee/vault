# Dev Plan: Docker image: compose run, signal handling and exit code

Main plan: [plan.md](plan.md)

## Shared contracts

Implement the behaviour table in [plan.md](plan.md#shared-contracts) exactly. In particular:

- Signal before compose started → exit `128 + signal`.
- A failing `compose down` only warns; the exit code stays compose's.
- When compose exits on its own, there is no `compose down`.

## Steps

- [01 — Compose library](dev/01-compose-library.md)
- [02 — Signals library](dev/02-signals-library.md)
- [03 — Wire the entrypoint](dev/03-wire-entrypoint.md)

## CI Checks
- `source/`, `test/`: `make lint` (shellcheck) and `make test` (bats), both run in Docker
- Image: `make build-image`
- No CircleCI config exists yet (#8). `make test-image` is still a placeholder (#7).

## Notes
- **Why background + `wait`**: bash runs a trap only after the foreground command finishes. If compose ran in the foreground, `docker stop` would hit the 10s grace period before the trap even ran. A `wait` builtin, by contrast, returns as soon as a trapped signal arrives.
- **stdin**: a background job in a non-interactive shell gets `/dev/null` as stdin. Start compose with an explicit `<&0` so passthrough commands such as `docker run -it vault exec app sh` keep the terminal.
- **Re-waiting**: after a trap interrupts `wait`, the status is `128 + signal`, not compose's. The entrypoint must `wait` on the same PID again. Bash remembers the status of a reaped background child, so this second `wait` returns compose's real code. Detect the interruption with a counter the handler increments (not by looking at the status, since compose itself may exit with 143).
- **No double teardown**: once compose has exited on its own, ignore TERM / INT before stopping dockerd. Otherwise a late signal would run `compose down` against a daemon that is shutting down.
- The libraries only define functions. Only `entrypoint.sh` reads the environment (`COMPOSE_UP_ARGS` is parsed there and handed to the lib).
- The end-to-end check (`docker stop` exits 0) belongs to #7's smoke test. Here, check it manually once with `make build-image` and a tiny compose file.
