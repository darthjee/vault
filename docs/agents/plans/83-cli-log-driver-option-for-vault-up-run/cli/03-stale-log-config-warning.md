# Generalise the stale-configuration warning

- `cli/lib/instance.sh`: rename `instance_warn_stale_log_opts` → `instance_warn_stale_log_config`. New rule:
  - Mismatch when `CONFIG_LOG_DRIVER` is non-empty and differs from `INSTANCE_LOG_DRIVER` (plain string compare), **or** a requested `CONFIG_LOG_OPTS` item is missing from `INSTANCE_LOG_OPTS` (existing rule, unchanged).
  - Silent when neither a driver nor options are requested, or everything requested matches. Always returns 0.
  - Message: `log configuration differs from the running instance ($(instance_logs "$INSTANCE_LOG_DRIVER" "$INSTANCE_LOG_OPTS")); run 'vault down' then 'vault up' to apply them` (masking unchanged). Update the function comment.
- `cli/bin/vault`: call `instance_warn_stale_log_config` in `vault_up`'s `running)` branch; update the `vault_up` comment ("warns when the requested log configuration differs").

Tests:

- `test/cli/instance.bats`: update the three existing assertions to the new text; add: driver differs (`journald` running, `local` requested) → warning `(journald)`; driver matches → silent; no driver requested with a different running driver → silent; driver matches but an option is missing → warning.
- `test/cli/up.bats`: update the four existing `check_up_running` expectations; add `vault up --log-driver local` on a running `journald` instance → status block, exit 0, warning on stderr; same with `log-driver=local` in `.vaultrc`; matching driver → empty stderr.
- `grep -rn "log options differ"` over the repo must return nothing afterwards (outside `docs/agents/issues` / `docs/agents/plans`).

## Files to Change

- `cli/lib/instance.sh` — rename, driver comparison, message.
- `cli/bin/vault` — caller and comment.
- `test/cli/instance.bats`, `test/cli/up.bats` — updated and new assertions.
