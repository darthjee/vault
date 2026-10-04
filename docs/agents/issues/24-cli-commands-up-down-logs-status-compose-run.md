# Issue: CLI commands: up, down, logs, status, compose, run

## Description
Part of epic #20 (Vault CLI). Depends on the CLI core sub-issue (#23, closed). Agent: `cli`.
Follow `docs/agents/specs/*.md`, mainly `cli-commands.md` (commands, container arguments,
messages, exit codes, edge cases) and `cli-overview.md` (open points 2–6, settled here).

## Problem
The CLI core (#23) parses options, reads `.vaultrc`, names the instance, selects the runtime and
builds `CONTAINER_ARGS`, but no command uses them yet: `vault_main` only dispatches `version`
and `help`.

## Expected Behavior
- **`vault up [dir]`:** `docker run` of the image as `vault-<name>`, **detached by default**,
  with the `CONTAINER_ARGS` built by #23 (runtime, `--stop-timeout`, `-v dir:/vault` unless
  `--image` is given without a `[dir]`, `-v vault-<name>-data:/var/lib/docker`, extra `-v`,
  ports, env files, `-e`).
  - Detached success prints `vault-<name> started`.
  - `-f` / `--attach` runs it in the foreground and passes through the exit code.
  - Already running → `vault-<name> is already running`, then the status; exit 0.
  - Exists but stopped → `docker rm`, then a fresh `docker run` with the current flags. The
    volume is kept.
  - Sysbox fails at run time → docker's error, then `sysbox-runc failed to start the
    container` + the `fix sysbox or use --runtime=privileged` hint; exit 1. Never escalates to
    `--privileged`.
  - Port in use → docker's error + `choose another host port with -p HOST:80`; exit 1.
  - A missing `[dir]` fails (`directory not found: <dir>`, exit 1). A missing compose file
    (none of `compose.yaml`, `compose.yml`, `docker-compose.yaml`, `docker-compose.yml`) only
    warns, and is checked only when `[dir]` is mounted.
- **`vault down`:** `docker stop -t <stop-timeout>`, then `docker rm`. Prints
  `vault-<name> stopped and removed (volume vault-<name>-data kept)`. The volume is never
  removed. A missing instance prints `vault-<name> does not exist` and exits 0.
- **`vault logs [-f]`:** `docker logs [-f] vault-<name>`. A missing or stopped instance fails
  with `instance vault-<name> is not running` (exit 1).
- **`vault status`:** prints the status block (layout kept as drafted in the spec: `name`,
  `state`, `image`, `runtime`, `ports`, `volume`, `env` keys only). A missing or stopped instance
  is reported (`state: not found` / `stopped`), not a failure: exit 0.
- **`vault compose <args>`:** `docker exec vault-<name> docker compose <args>`, passing through
  the exit code. Fails with `instance vault-<name> is not running` when it is not running.
- **`vault run [dir] <args>`:** one-shot `docker run --rm` in the foreground, passing `<args>` to
  the image's entrypoint and passing through the exit code.
- **Open points settled by this issue** (the spec is updated to mark them settled):
  - **2 — `run` while the instance is running:** refused with an error naming the running
    instance (hint: use `vault compose`), exit 1, since both would share `vault-<name>-data`.
  - **3 — TTY flags:** `run` and `compose` add `-t` when stdout is a TTY and `-i` when stdin
    is a TTY (so `vault compose exec app bash` works). `up` never adds them.
  - **4 — status layout:** kept as drafted.
  - **5 — missing instance vs. unreachable daemon** (`down`, `logs`, `status`, `compose`,
    which skip `docker info`): `docker inspect` failing with "No such object" → missing
    instance; any other failure → `cannot reach the Docker daemon` (exit 1).
  - **6 — failed `docker run` attribution:** docker's error containing
    `port is already allocated` or `address already in use` → port hint; any other start
    failure under `sysbox-runc` → Sysbox hint; other failures under `--privileged` → docker's
    error, exit 1.
- **Bats tests** (`test/cli/`), with the stub `docker`, covering each command, each message
  and exit code above, the full `docker` argument lists (including `-i`/`-t` with and without a
  TTY), and edge cases 2, 4–8 of `cli-commands.md`, under bash 3.2 and a current bash.

## Solution
- Add one function per command in `cli/bin/vault` (dispatched from `vault_main`), each calling
  `vault_resolve` first, with the docker-facing logic (inspect/state lookup, error
  classification, status rendering) in `cli/lib/` helpers.
- Update `docs/agents/specs/cli-commands.md` and `cli-overview.md` to record open points 2–6 as
  settled, and the TTY flags in the container-argument order.

## Benefits
Makes the CLI usable end to end: users can start, inspect, operate and stop a Vault instance
without hand-writing `docker run` lines, with the privilege model enforced.
