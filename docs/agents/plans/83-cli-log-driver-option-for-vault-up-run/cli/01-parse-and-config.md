# Parse `--log-driver` and the `log-driver=` key

Add the option to the parser and the key to `.vaultrc`, resolved as a scalar.

- `cli/lib/args.sh`:
  - Add `args_valid_log_driver <value>`: returns 0 when the value is non-empty and contains no whitespace and no `=` (e.g. `case "$1" in "" | *[[:space:]=]*) return 1 ;; esac`). Document it next to `args_valid_runtime`.
  - `_args_reset`: `ARGS_LOG_DRIVER=""`, `ARGS_LOG_DRIVER_SET=0`; document them in the `args_parse` header.
  - `_args_key`: add `--log-driver` to the `up | run` value-option group; `_args_canonical`: `--log-driver) echo log-driver ;;`.
  - `_args_store`: `log-driver)` validates with `args_valid_log_driver` (`_args_bad_value` → exit 2), then sets `ARGS_LOG_DRIVER` / `ARGS_LOG_DRIVER_SET=1` (overwrite: last value wins).
- `cli/lib/config.sh`:
  - `config_reset`: `CONFIG_RC_LOG_DRIVER=""`, `CONFIG_RC_LOG_DRIVER_SET=0`; update the `config_parse` header (scalars list).
  - `_config_set`: `log-driver)` validates with `args_valid_log_driver` (`_config_bad_value` → exit 1), last line wins.
  - `config_merge`: `CONFIG_LOG_DRIVER="$(_config_pick "$ARGS_LOG_DRIVER_SET" "$ARGS_LOG_DRIVER" "$CONFIG_RC_LOG_DRIVER_SET" "$CONFIG_RC_LOG_DRIVER" "")"`; document it in the header. Do not touch the `log-opt` merge (independent resolution).

Tests:

- `test/cli/args.bats`: valid value (`local`, `--log-driver=local`), last wins on repeat, `""`, `"a b"`, `json-file=x` → exit 2 with `invalid value for --log-driver: '<value>'`, missing argument → usual missing-value error, rejected on `down`/`logs`/`status`/`compose` → `unknown option '--log-driver'`.
- `test/cli/config.bats`: `log-driver=journald` accepted; last line wins; `log-driver=`, `log-driver=   `, `log-driver=a=b` → exit 1 with `.vaultrc:<line>: invalid value for log-driver: '<value>'`; merge: flag overrides `.vaultrc`, unset → `CONFIG_LOG_DRIVER=""`; a `--log-driver` flag keeps `.vaultrc` `log-opt` entries.

## Files to Change

- `cli/lib/args.sh` — option, validator, storage.
- `cli/lib/config.sh` — key, merge.
- `test/cli/args.bats`, `test/cli/config.bats` — cases above.
