# Plan: CLI: --log-driver option for vault up / run

Issue: [83-cli-log-driver-option-for-vault-up-run.md](../../issues/83-cli-log-driver-option-for-vault-up-run.md)

## Overview

Add a scalar `--log-driver <name>` option to `vault up` / `vault run` and a `log-driver=` key in `.vaultrc` (flag > `.vaultrc` > Docker default), emitted as `--log-driver <name>` on the `docker run` line right before #81's `--log-opt` entries. Validation is structural only (non-empty, no whitespace, no `=`); Docker owns driver knowledge. The stale-options warning from #81 is generalised to a "log configuration differs" warning that also covers a driver mismatch. The `cli` agent implements the CLI, completions, help and tests; the `product-owner` agent documents it in the user guide and the agent flow doc.

## Agents involved

- [cli](cli.md)
- [product-owner](product-owner.md)

## Shared contracts

Both agents must use these exact names and strings.

- **Option**: `--log-driver <name>` (also `--log-driver=<name>`), accepted on `up` and `run` only. On `down`, `logs`, `status`, `compose`: `vault: error: unknown option '--log-driver'`, exit 2.
- **`.vaultrc` key**: `log-driver` — single value, last line wins. Table row: `` | `log-driver` | `--log-driver` | no (last line wins) | ``.
- **Precedence**: flag > `.vaultrc` > unset (no `--log-driver` emitted; Docker's / `daemon.json`'s default applies). A repeated flag: last value wins. Driver and log options resolve independently — a `--log-driver` flag does **not** drop `log-opt=` lines from `.vaultrc`.
- **Validation** (structural only, no driver list): value must be non-empty and contain no whitespace and no `=`.
  - Flag: `vault: error: invalid value for --log-driver: '<value>'`, exit 2.
  - `.vaultrc`: `vault: error: .vaultrc:<line>: invalid value for log-driver: '<value>'`, exit 1. (`.vaultrc` values are not trimmed, so `log-driver=   ` is rejected by the whitespace rule.)
  - Unknown driver / missing plugin / unreachable backend / options the driver does not accept: fail at `docker run`, exit 1, Docker's message only.
- **`docker run` order**: `... -e <env>... [--log-driver <name>] --log-opt <opt>... <up: --name ... | run: -i -t --rm> ...`. With no driver requested the line is byte-identical to today's.
- **Help line** (`vault help`, Options block, right before `--log-opt`):
  `  --log-driver <name>        Log driver (up, run); 'none' disables 'vault logs'`
  (aligned with the existing column; exact wording may be adjusted by `cli` to fit the column, product-owner docs need not quote it).
- **Completion hint list** (bash and zsh, hint only, never used for validation): `json-file local journald syslog gelf fluentd awslogs splunk etwlogs gcplogs none`.
- **Stale-configuration warning** (on `vault up` against a running instance), replacing #81's text:
  `vault: warning: log configuration differs from the running instance (<driver> <opts>); run 'vault down' then 'vault up' to apply them`
  Fires when a requested driver differs from the running one (plain string compare) or a requested log option is missing (#81 rule). Silent when no driver is requested or it matches. Exit stays 0; the instance is never recreated.
- **Function rename**: `instance_warn_stale_log_opts` → `instance_warn_stale_log_config`.
- **Versioning**: `log-driver` requires vault CLI 0.4.0 or later (same release as #81's `log-opt`; older CLIs warn `unknown key`).
