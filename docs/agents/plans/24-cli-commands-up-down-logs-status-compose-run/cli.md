# Cli Plan: CLI commands: up, down, logs, status, compose, run

Main plan: [plan.md](plan.md)

## Shared contracts

Implement contracts 1–5 of [plan.md](plan.md#shared-contracts) exactly:
- instance state through one `docker inspect`, with "No such object" meaning `missing`;
- `run` refused while the instance is running;
- `-i`/`-t` from `[ -t 0 ]`/`[ -t 1 ]` for `run` (before `--rm`) and `compose`;
- the status layout as drafted;
- `docker run` failure attribution, only for exit codes 125–127 on passthrough commands.

Every other message, stream and exit code comes from `docs/agents/specs/cli-commands.md` and
is asserted verbatim.

## Steps

- [01 — Instance state library](cli/01-instance-state.md)
- [02 — `vault up`](cli/02-up.md)
- [03 — `vault down`, `logs`, `status`](cli/03-down-logs-status.md)
- [04 — `vault compose`, `vault run`, usage](cli/04-compose-run-usage.md)

## CI Checks
- `cli/`, `test/cli/`: `make lint` (CI job step "Lint shell scripts")
- `test/cli/` on a current bash and bash 3.2: `make test` ("Run unit tests")
- Bundle: `make bundle-cli` ("Build CLI bundle"). Every new `cli/lib/*.sh` must be added to
  `LIBS` in `scripts/bundle_cli.sh`.

## Notes
- Keep bash 3.2 compatible: no `mapfile`, no `${var,,}`, no associative arrays, and guard
  empty arrays with `${a[@]+"${a[@]}"}` as `container.sh` does.
- All docker calls go through `docker_run_cmd`. Libraries only define functions, prefixed by
  module.
- The stub `docker` scripts output by first argument (`inspect`, `run`, `rm`, `stop`, `logs`,
  `exec`). That is enough for every case here, since each command calls `inspect` once.
  Extend `test/cli/helpers/docker_stub.bash` only if needed.
- Put the TTY checks in one small function (e.g. `instance_tty_flags`) so tests can redefine
  it. bats has no TTY, so the "no TTY" case is the default.
- `up -f` and `run` run docker in the foreground: use `exec`-free calls so the exit code can be
  classified (contract 5), then return the code unchanged.
