# Stale-options warning on vault up

Depends on step 04 (`INSTANCE_LOG_DRIVER` / `INSTANCE_LOG_OPTS`, `instance_logs`).

- `cli/lib/instance.sh`: new public `instance_warn_stale_log_opts` after `instance_logs` (issue "Stale-options hint" snippet): return 0 when `CONFIG_LOG_OPTS` is empty; otherwise warn via `output_warning` with the contract-7 message when any requested `KEY=VALUE` is not a word of `INSTANCE_LOG_OPTS` (subset check — extra running keys from `daemon.json` are ignored). Always returns 0.
- `cli/bin/vault` `vault_up`, `running` branch: `instance_status_print "$NAMING_NAME" running || return`, then `instance_warn_stale_log_opts`, then `return`. Extend the comment above `vault_up` ("Already running: no-op, prints the status") with "and warns when the requested log options differ". `vault run` is unchanged (it already refuses while running).

Tests:
- `test/cli/up.bats`: warns for a differing flag value (stdout unchanged, `run` not called, exit 0); warns for a differing `.vaultrc` value; silent for a matching set in another order; silent when the running set has extra daemon-default keys; silent with duplicate requested keys whose deduped value matches; silent with nothing requested; "up when stopped applies the log options" (`rm` then `run` with the entries, no warning). The existing "up when already running" case keeps its empty-stderr assertion.
- `test/cli/instance.bats`: unit cases for `instance_warn_stale_log_opts` (empty, same set reordered, superset, differing value, missing key, masked value in the message).

## Files to Change
- `cli/lib/instance.sh` — `instance_warn_stale_log_opts`.
- `cli/bin/vault` — call it in the already-running branch of `vault_up`; comment.
- `test/cli/up.bats`, `test/cli/instance.bats` — warning cases.
