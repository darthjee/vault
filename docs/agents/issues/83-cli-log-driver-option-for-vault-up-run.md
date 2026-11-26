# Issue: CLI: --log-driver option for vault up / run

## Description

Add a `--log-driver <name>` option to `vault up` and `vault run`, and a matching `log-driver=` key in `.vaultrc`, so the Vault instance's outer container can use a log driver of its own (e.g. `local`, `journald`, `syslog`, `none`) without changing the host's global `daemon.json`. Follow-up of #81 (`--log-opt`), which explicitly left the driver out of scope.

## Problem

#81 adds `--log-opt` to `vault up` / `vault run`, but the options always apply to whatever driver is in effect: Docker's default (`json-file`) or the host's global `daemon.json`. There is no way to pick a driver for the Vault instance alone — e.g. `local` (rotates and compresses by default) or `journald` / `syslog` (ships the log off the host disk) — without changing every container on the machine.

Current behaviour (reference):

| Location | Behaviour today |
|----------|-----------------|
| `cli/lib/args.sh` — `_args_key` / `_args_canonical` | `--log-driver` is unknown for every command: `vault: error: unknown option '--log-driver'`, exit 2. |
| `cli/lib/config.sh` — `_config_set` | `log-driver=` in `.vaultrc` hits the unknown-key branch: warning, line skipped. |
| `cli/lib/container.sh` — `container_build_args` | No `--log-driver` is ever emitted; `--log-opt` entries are emitted after `-e` and before `--name` / `-i -t --rm`. |
| `cli/lib/instance.sh` — `instance_warn_stale_log_opts` | Warns `log options differ from the running instance (...)` only when a requested `--log-opt` is missing from the running instance; the driver is never compared. |
| `cli/lib/instance.sh` — `instance_status_print` | The `logs:` line already prints the running driver (#81). |

## Expected Behavior

Docker run line:

- `vault up --log-driver local` produces a `docker run` line containing `--log-driver local` right before the `--log-opt` entries (i.e. after `-e`, before `--name`); `vault run --log-driver local config` does the same, before `-i`/`-t`/`--rm`.
- `vault up --log-driver local --log-opt max-size=10m` emits `--log-driver local --log-opt max-size=10m`.
- With no `--log-driver` flag and no `log-driver=` key, the `docker run` line is byte-identical to today's.
- `log-driver=journald` in `.vaultrc` emits `--log-driver journald`; `--log-driver local` with `log-driver=journald` in `.vaultrc` emits only `--log-driver local` (flag > `.vaultrc` > Docker default).
- `--log-driver json-file --log-driver local` emits only `--log-driver local` (scalar: last value wins).
- `--log-driver none` is accepted and emitted.

Validation (structural only; the name is passed verbatim, no driver list):

- `vault up --log-driver ""`, `--log-driver "a b"` and `--log-driver json-file=x` exit 2 with `vault: error: invalid value for --log-driver: '<value>'`.
- `vault up --log-driver` (no argument) exits 2 with the usual missing-value error.
- `log-driver=` (empty, or whitespace only) and `log-driver=a=b` in `.vaultrc` exit 1 with `vault: error: .vaultrc:<line>: invalid value for log-driver: '<value>'`.
- An unknown driver, a missing plugin, an unreachable backend, or a `--log-opt` the driver does not accept fail at `docker run` and exit 1 with Docker's message only (no CLI pre-check).
- `vault down --log-driver local` exits 2 with `vault: error: unknown option '--log-driver'`; same for `logs`, `status` and `compose`.

Stale-configuration hint (`vault up` on a running instance):

- Started with `journald`, `vault up --log-driver local` prints the status block (exit 0) and on stderr `vault: warning: log configuration differs from the running instance (journald); run 'vault down' then 'vault up' to apply them`. Same with `log-driver=local` in `.vaultrc`.
- No warning when the requested driver matches the running one, or when no driver is requested (the running one may be the daemon default).
- The existing `--log-opt` mismatch cases from #81 keep firing, now with the reworded `log configuration differs …` message (same masking of sensitive values).
- The instance is never recreated.

`vault logs` and `vault status`:

- `vault logs` remains a pass-through to `docker logs`; with `--log-driver none` Docker's error and exit code are surfaced unchanged.
- `vault status` is unchanged; its `logs:` line already shows the running driver (e.g. `logs:     local max-size=10m`).

Help, completions, docs:

- `vault help` lists `--log-driver <name>`, noting that `none` and some remote drivers make `vault logs` unusable.
- Both completions offer `--log-driver` on `up` and `run`, expect a value, and suggest Docker's built-in drivers (`json-file`, `local`, `journald`, `syslog`, `gelf`, `fluentd`, `awslogs`, `splunk`, `etwlogs`, `gcplogs`, `none`) as a hint only — any other value is still accepted.
- `docs/guides/vault/cli.md` documents the option, the `log-driver=` key, the `--log-opt` interaction footgun (see Solution), and a host-impact note.
- `make lint`, `make test`, `make test-docs` and `make test-cli-e2e` pass.

## Solution

```bash
vault up  [--log-driver <name>] [--log-opt <KEY=VALUE>]... [options] [dir]
vault run [--log-driver <name>] [--log-opt <KEY=VALUE>]... [options] [dir] [args...]
```

```ini
# .vaultrc
log-driver=local
log-opt=max-size=10m
```

### Parsing and config

- `cli/lib/args.sh`: add `--log-driver` as a value option of `up` and `run` only (`_args_key`, `_args_canonical`), stored in the scalar pair `ARGS_LOG_DRIVER` / `ARGS_LOG_DRIVER_SET`, last value wins. Add a structural validator (e.g. `args_valid_log_driver`): non-empty, no whitespace, no `=`. Invalid → `invalid value for --log-driver: '<value>'`, exit 2.
- `cli/lib/config.sh`: accept the `log-driver` key in `config_reset` / `_config_set`, reusing the same validator (invalid → `.vaultrc:<line>: invalid value for log-driver`, exit 1). `config_merge` resolves `CONFIG_LOG_DRIVER` as a scalar: flag > `.vaultrc` > empty (Docker default).
- Driver and options resolve **independently**. No coupling: a `--log-driver` flag does not drop `log-opt=` entries inherited from `.vaultrc`.

### Docker run line

- `cli/lib/container.sh` — `container_build_args`: when `CONFIG_LOG_DRIVER` is non-empty, emit `--log-driver "$CONFIG_LOG_DRIVER"` immediately before the `--log-opt` loop; update the documented order and inputs in the header comment. The name is its own argv element (no shell).

### Stale-configuration hint

- `cli/lib/instance.sh`: rename `instance_warn_stale_log_opts` → `instance_warn_stale_log_config`. It warns when a driver is requested (`CONFIG_LOG_DRIVER` non-empty) and differs from `INSTANCE_LOG_DRIVER` (plain string comparison), or when a requested log option is missing (existing #81 rule). Silent when nothing is requested or everything matches. Always returns 0.
- Reword the message to `log configuration differs from the running instance (<driver> <opts>); run 'vault down' then 'vault up' to apply them`. Update the caller and the comment in `cli/bin/vault` (around line 70), and the #81 assertions in `test/cli/instance.bats` and `test/cli/up.bats`. This is safe: #81 is on `main` but not in any release (latest tag `0.3.0`), so both changes should ship together.

### Help, completions, docs

- `cli/lib/usage.sh`: list `--log-driver <name>` next to `--log-opt`.
- `cli/completion/vault.bash` (`_vault_complete_options`, `_vault_complete_takes_value`) and `cli/completion/_vault` (`runtime_opts`): add `--log-driver`, with a static, hint-only list of Docker's built-in driver names as value candidates (not used for validation).
- `docs/guides/vault/cli.md` and `docs/agents/flow.md`: document the option and key, and add:
  - **`--log-opt` interaction**: options must be valid for the effective driver; `--log-driver` on the command line does not reset `log-opt=` entries from `.vaultrc` — edit `.vaultrc` or pass `--log-opt` flags (which replace them wholesale).
  - **`vault logs`**: `none` (and remote drivers on Docker < 20.10) cannot be read by `docker logs`.
  - **Host impact**: the driver runs in the host's Docker daemon; addresses (`syslog`, `gelf`, `fluentd`) resolve from the host network; on Docker Desktop, `journald` is the Linux VM's journal; remote drivers ship all instance output (inner services included) off the host; plugin drivers must be installed on the daemon.

### Tests

- Bats (`test/cli/`): args (valid, empty, whitespace, `=`, missing argument, repeated → last wins, rejected on `down`/`logs`/`status`/`compose`), config (key accepted, empty / whitespace-only / `=` → exit 1, flag overrides `.vaultrc`), container (position before `--log-opt`, absent when unset → byte-identical line, `up` and `run`), instance (driver differs → warning, matches → silent, not requested → silent, reworded `--log-opt` cases).
- E2E (`make test-cli-e2e`): `vault up --log-driver local` then `vault status` shows `logs:     local`; `vault up --log-driver json-file` on that running instance prints the warning.

### Out of scope

- Driver-name or driver/option compatibility checks in the CLI; `docker info` pre-flight.
- Clearing inherited log options (e.g. `--no-log-opt`) and a friendlier `vault logs` message for `none`: possible follow-ups only if needed.
- `vault compose` / inner services' log drivers (they belong to the user's compose file); driver-specific shortcut flags; `vault status` changes; image / entrypoint / runtime-privilege changes; recreating a running instance.

## Benefits

- Bound or relocate the instance's log per instance (`local`, `journald`, `syslog`, `none`) without touching the host's global `daemon.json`.
- Consistent with #81's model: flag > `.vaultrc` > default, structural validation, Docker owns driver knowledge — no driver list to maintain, plugin drivers work.
- No user-facing break: the `docker run` line is unchanged when the option isn't used.
