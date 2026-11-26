# Emit --log-opt on docker run

In `cli/lib/container.sh` `container_build_args`, after the `-e` loop and before the `case "$command"` block, append `CONTAINER_ARGS+=(--log-opt "$item")` for each `CONFIG_LOG_OPTS` entry (guarded empty-array expansion). Extend the header comment's `Order:` block with `--log-opt <opt>...` between `-e <env>...` and `up: --name vault-<name>`.

Tests in `test/cli/up.bats` and `test/cli/run.bats`: extend the full-argument-list cases with two `--log-opt` entries in the right position (before `--name` for `up`, before `-i`/`-t`/`--rm` for `run`); "up without --log-opt emits no --log-opt"; "a log-opt value with spaces stays one argument" (`--log-opt "max-size=1m --privileged"` → exactly one argument after `--log-opt`, no standalone `--privileged`); `.vaultrc`-only entries emitted in file order; flag replaces `.vaultrc`.

## Files to Change
- `cli/lib/container.sh` — emission loop and header comment.
- `test/cli/up.bats`, `test/cli/run.bats` — argument-list assertions.
