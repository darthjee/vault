# `vault compose`, `vault run`, usage
Add `vault_compose` and `vault_run`, dispatch them, and list every command in the usage.

- **compose:**
  1. `instance_require_running`.
  2. `instance_tty_flags`.
  3. `docker exec [-i] [-t] vault-<name> docker compose <ARGS_PASSTHROUGH...>`, passing
     through the exit code.
- **run:**
  1. `vault_resolve run "$@"`.
  2. The `directory not found` check (only when `[dir]` was given) and the compose-file
     warning when a dir is mounted, as in `up`.
  3. `instance_state` → `running` refuses per contract 2.
  4. `instance_tty_flags`, inserting `INSTANCE_TTY_ARGS` before `--rm` in `CONTAINER_ARGS`.
     Either extend `container_build_args` with an optional tty-args parameter, or splice in
     `vault_run`. Prefer the builder, so the argument order lives in one place, and update
     `test/cli/resolve.bats` if its expected list changes.
  5. `docker_run_cmd "${CONTAINER_ARGS[@]}"`: passthrough exit code, with contract 5 for codes
     125–127.
- **usage:** add `up`, `down`, `logs`, `status`, `compose` and `run`, with one-line
  descriptions and the main options, to `usage_print`. Update the help assertions in
  `test/cli/vault.bats` if they check the text.

Tests in `test/cli/compose.bats`, `run.bats`:
- full argument lists with no TTY;
- with a TTY, by redefining `instance_tty_flags` (or a stubbed `[ -t ]` wrapper) to assert
  `-i -t` placement;
- not running → error, exit 1, no `exec`;
- `run` refused while running;
- `run` allowed when stopped or missing;
- `vault run config` vs. an existing dir;
- passthrough exit codes;
- the Sysbox and port attribution for `run`.

Also run each command once against the bundle (`build/vault`), as `vault.bats` does.

## Files to Change
- `cli/bin/vault` — `vault_compose`, `vault_run`, dispatch.
- `cli/lib/container.sh` — optional TTY args in the `run` slot.
- `cli/lib/usage.sh` — list the new commands.
- `test/cli/compose.bats`, `test/cli/run.bats`, `test/cli/vault.bats`, `test/cli/resolve.bats`
  — tests.
