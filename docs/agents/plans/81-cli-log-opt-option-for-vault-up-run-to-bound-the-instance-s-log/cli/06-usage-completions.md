# Usage and completions

- `cli/lib/usage.sh` `usage_print`: under `-e` / `--env-file`, add `  --log-opt <KEY=VALUE>      Log driver option, repeatable (up, run)` (align with the existing columns).
- `cli/completion/vault.bash`: add `--log-opt` to the `up` and `run` lines of `_vault_complete_options` and to the case list of `_vault_complete_takes_value` (both must stay in sync with `_args_key`).
- `cli/completion/_vault`: add `'*--log-opt=[log driver option, repeatable]:KEY=VALUE: '` to `runtime_opts`.

Tests: `test/cli/completion.bats` — `--log-opt` offered for `up` and `run`, not for `down`, `logs`, `status`, `compose`; `test/cli/vault.bats` (or wherever `vault help` is asserted) — help lists the option.

## Files to Change
- `cli/lib/usage.sh` — help line.
- `cli/completion/vault.bash`, `cli/completion/_vault` — completion entries.
- `test/cli/completion.bats` — completion cases; help assertion if one exists.
