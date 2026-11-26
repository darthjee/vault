# .vaultrc key, merge and dedupe

In `cli/lib/config.sh` (issue "Implementation notes → cli/lib/config.sh"):

- `config_reset`: `CONFIG_RC_LOG_OPTS=()`.
- `_config_set`: a `log-opt` branch (no path resolution), rejecting anything not matching `?*=*` via `_config_bad_value` (return 1), appending verbatim.
- `config_merge`: after the `CONFIG_ENV_FILES` block, `CONFIG_LOG_OPTS` = `ARGS_LOG_OPTS` when `ARGS_LOG_OPTS_SET=1`, else `CONFIG_RC_LOG_OPTS`; then call `_config_dedupe_log_opts`.
- New private `_config_dedupe_log_opts` (after the public functions, before `_config_pick`): keep the last occurrence of each key (text before the first `=`), preserving survivor order; O(n²) lookahead, bash 3.2 safe.

Tests in `test/cli/config.bats`: "parses every key" gains two `log-opt` lines, one being `log-opt=max-size=10m` (value keeps its inner `=`); add `log-opt` to the empty-value loop; "log-opt without = or with an empty key fails (exit 1)"; "merge: log-opt flags replace the .vaultrc entries"; "merge: duplicate log-opt keys keep the last one"; "merge: distinct log-opt keys are all kept, in order". Also pin that `log-opt = x` (spaces around `=`) is the existing unknown-key warning.

## Files to Change
- `cli/lib/config.sh` — new key, merge block, dedupe helper.
- `test/cli/config.bats` — new and extended cases.
