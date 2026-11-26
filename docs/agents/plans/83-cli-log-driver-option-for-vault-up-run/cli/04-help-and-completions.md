# Help and completions

- `cli/lib/usage.sh` — `usage_print`: add the `--log-driver <name>` line right before `--log-opt`, aligned with the existing column, mentioning `up, run` and that `none` disables `vault logs` (see plan.md → Shared contracts).
- `cli/completion/vault.bash`:
  - `_vault_complete_options`: add `--log-driver` before `--log-opt` for `up` and `run`.
  - `_vault_complete_takes_value`: add `--log-driver`.
  - `_vault_complete_value`: `--log-driver) _vault_complete_words 'json-file local journald syslog gelf fluentd awslogs splunk etwlogs gcplogs none' "$cur" "$prefix" ;;`.
- `cli/completion/_vault` — `runtime_opts`: add `'--log-driver=[log driver]:driver:(json-file local journald syslog gelf fluentd awslogs splunk etwlogs gcplogs none)'` before the `--log-opt` spec. Zsh's `(...)` action only suggests; any other value is still accepted.

Tests:

- `test/cli/completion.bats`: `--log-driver` offered on `up` and `run`, not on `down`/`logs`/`status`/`compose`; value completion after `--log-driver j` offers `journald json-file`; `--log-driver=` prefix form.
- `test/cli/vault.bats`: `vault help` lists `--log-driver`.

## Files to Change

- `cli/lib/usage.sh` — help line.
- `cli/completion/vault.bash`, `cli/completion/_vault` — option and value hints.
- `test/cli/completion.bats`, `test/cli/vault.bats` — cases above.
