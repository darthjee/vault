# `vault down`, `logs`, `status`
Add `vault_down`, `vault_logs` and `vault_status`, dispatched from `vault_main`. None of them
calls `docker info`.

- **down:** `instance_state`.
  - `missing` → `vault-<name> does not exist`, exit 0.
  - Otherwise `docker stop -t <CONFIG_STOP_TIMEOUT> vault-<name>` (skipped when already
    stopped), then `docker rm vault-<name>`, then
    `vault-<name> stopped and removed (volume vault-<name>-data kept)`.
  - Never `docker volume rm`. A failing `stop`/`rm` passes docker's error through, exit 1.
- **logs:** `instance_require_running`, then `docker logs [-f] vault-<name>`, passing through
  its exit code.
- **status:** `instance_state`.
  - `missing` → only the `name:` and `state: not found` lines.
  - Otherwise one `docker inspect --format` call reads the image, the runtime (`HostConfig.Runtime`
    `sysbox-runc`, else `privileged` when `HostConfig.Privileged`), the ports
    (`NetworkSettings.Ports`, rendered `3000->80/tcp`), the data volume and the env **keys**
    (`Config.Env`, split on the first `=`, values dropped).
  - Render the block per contract 4 in a function `instance_status_print` in `instance.sh`
    (reused by `up`'s "already running").
  - Always exit 0 for running/stopped/missing. An unreachable daemon is still exit 1.
  - The image's own env vars (e.g. `PATH`) appear in `Config.Env` too. List only keys that are
    not image defaults, by comparing with `docker image inspect --format '{{json .Config.Env}}'`,
    or document the choice in the spec if that is too costly. Never print values.

Tests in `test/cli/down.bats`, `logs.bats`, `status.bats`:
- every message and exit code above;
- `-f` for logs;
- `--stop-timeout` used by `stop -t`;
- missing vs. unreachable daemon for each command;
- status never prints an env value (fixture with `SECRET=abc` asserts `abc` is absent).

## Files to Change
- `cli/bin/vault` — `vault_down`, `vault_logs`, `vault_status`, dispatch.
- `cli/lib/instance.sh` — `instance_status_print` and the inspect parsing.
- `test/cli/down.bats`, `test/cli/logs.bats`, `test/cli/status.bats` — new tests.
