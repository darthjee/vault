# Emit `--log-driver` on the `docker run` line

- `cli/lib/container.sh` — `container_build_args`: right before the `CONFIG_LOG_OPTS` loop, add `--log-driver "$CONFIG_LOG_DRIVER"` when `CONFIG_LOG_DRIVER` is non-empty. Update the header comment: inputs list (`CONFIG_LOG_DRIVER`) and the documented order (`[--log-driver <name>] --log-opt <opt>...`).

Tests (`test/cli/up.bats`, `test/cli/run.bats`, following #81's `--log-opt` cases):

- `vault up --log-driver local` → `... -e ... --log-driver local --name vault-<name> -d <image>` (exact position: after `-e`, before `--log-opt` / `--name`).
- `vault up --log-driver local --log-opt max-size=10m` → `--log-driver local --log-opt max-size=10m`.
- `vault run --log-driver local config` → before `-i`/`-t`/`--rm`.
- `log-driver=journald` in `.vaultrc` → `--log-driver journald`; with `--log-driver local` → only `--log-driver local`.
- `--log-driver none` emitted as-is.
- No driver anywhere → `docker run` line identical to the existing expectation (keep/extend the existing "no log option" assertion).
- Docker failing `docker run` (stubbed non-zero) with a driver set → exit 1, Docker's message only (reuse the existing failure-path helper).

## Files to Change

- `cli/lib/container.sh` — emission and header comment.
- `test/cli/up.bats`, `test/cli/run.bats` — cases above (and `test/cli/helpers/vault_cli.bash` only if a helper needs the new variable reset).
