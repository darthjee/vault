# logs: line in vault status, with masking

In `cli/lib/instance.sh` (issue "Implementation notes → cli/lib/instance.sh" and "Masking sensitive option values"):

- `_instance_status_format`: **append** `{{"\n"}}{{.HostConfig.LogConfig.Type}}{{"\n"}}{{range $k, $v := .HostConfig.LogConfig.Config}}{{$k}}={{$v}} {{end}}` after the env-keys part (lines 6 and 7).
- `instance_status_print`: read lines 6 and 7, store them in `INSTANCE_LOG_DRIVER` / `INSTANCE_LOG_OPTS` (reset to empty for a missing instance; document in the header comment), and print `_instance_status_line logs "$(instance_logs ...)"` as the **last** line, after `env`.
- New public `instance_logs <driver> <option-words>` after `instance_status_print`: `<driver>` alone, or `<driver> <opt>, <opt>` via `_instance_join`, with words passed through the new private `_instance_mask_log_opts` (keys containing `token|password|secret|credential`, case-insensitive via `tr`, become `<key>=***`).

Tests:
- `test/cli/helpers/vault_cli.bash`: extend `STATUS_FORMAT` with the two new template lines; update every inspect stub output used by `status.bats` and `up.bats` ("up when already running") with a driver line and an options line, and add `logs:` as the last expected line.
- `test/cli/status.bats`: driver plus sorted options; bare driver; stopped instance shows `logs:`; template-like value `tag={{.Name}}` printed literally; driver `none`; missing instance unchanged.
- `test/cli/instance.bats`: `instance_logs` masks `splunk-token`, `Splunk-Password`, `aws-secret`, `some-credential`; leaves `max-size=10m`, `tag={{.Name}}`, `gelf-tls-key=/path` unchanged.

## Files to Change
- `cli/lib/instance.sh` — status format, globals, `instance_logs`, `_instance_mask_log_opts`.
- `test/cli/helpers/vault_cli.bash` — `STATUS_FORMAT` fixture.
- `test/cli/status.bats`, `test/cli/up.bats`, `test/cli/instance.bats` — stubs and assertions.
