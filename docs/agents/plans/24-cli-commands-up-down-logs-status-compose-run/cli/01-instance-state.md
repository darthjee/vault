# Instance state library
Add `cli/lib/instance.sh`, which tells whether `vault-<name>` is running, stopped or missing
(contract 1), and register it in the bundle.

- `instance_state <name>`: calls `docker_run_cmd inspect --format '{{.State.Running}}' vault-<name>`
  and sets `INSTANCE_STATE` to `running`, `stopped` or `missing`. On any other failure it
  passes docker's stderr through, prints the "cannot reach the Docker daemon" error and hint,
  and returns 1.
- `instance_require_running <name>`: calls `instance_state`. When the state is not `running`,
  prints `instance vault-<name> is not running` and returns 1 (used by `logs` and `compose`).
- `instance_tty_flags`: fills `INSTANCE_TTY_ARGS` with `-i` when `[ -t 0 ]` and `-t` when
  `[ -t 1 ]`, in that order (contract 3).
- Add `instance.sh` to `LIBS` in `scripts/bundle_cli.sh` (after `container.sh`) and source it
  in `cli/bin/vault`'s `BEGIN LIBS` block.
- Tests in `test/cli/instance.bats`: running, stopped, missing ("No such object"), and
  unreachable daemon (docker's stderr then the CLI error). Also `instance_tty_flags` with no
  TTY (empty).

## Files to Change
- `cli/lib/instance.sh` — new library.
- `cli/bin/vault` — source it.
- `scripts/bundle_cli.sh` — add it to `LIBS`.
- `test/cli/instance.bats` — new tests.
