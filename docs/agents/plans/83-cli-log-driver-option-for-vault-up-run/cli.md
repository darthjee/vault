# Cli Plan: CLI: --log-driver option for vault up / run

Main plan: [plan.md](plan.md)

## Shared contracts

Everything in [plan.md → Shared contracts](plan.md#shared-contracts) applies to this agent; it produces all of it. In particular:

- `ARGS_LOG_DRIVER` / `ARGS_LOG_DRIVER_SET`, `CONFIG_RC_LOG_DRIVER` / `CONFIG_RC_LOG_DRIVER_SET`, `CONFIG_LOG_DRIVER` (`""` when unset).
- Error strings, the reworded warning, the emission order, the help line, the completion hint list, and the rename `instance_warn_stale_log_opts` → `instance_warn_stale_log_config`.

## Steps

- [01 — Parse `--log-driver` and the `log-driver=` key](cli/01-parse-and-config.md)
- [02 — Emit `--log-driver` on the `docker run` line](cli/02-container-args.md)
- [03 — Generalise the stale-configuration warning](cli/03-stale-log-config-warning.md)
- [04 — Help and completions](cli/04-help-and-completions.md)
- [05 — End-to-end check](cli/05-e2e.md)

## CI Checks

- `cli/`, `test/cli/`: `make lint` and `make test` (CI job: `build-and-test`)
- docs links touched by help text: `make test-docs` (CI job: `build-and-test`)
- `scripts/test_cli_e2e.sh`: `make test-cli-e2e` (CI job: `build-and-test`; needs a built image, `make bundle-cli` / `make test-image` run before it in CI)

## Notes

- bash 3.2 compatibility: indexed arrays only, no `${var,,}`, no `[[ =~ ]]` captures needed here — a `case` pattern (`*[[:space:]=]*`) is enough for validation.
- `.vaultrc` values are not trimmed by `config_parse`; whitespace-only values are rejected by the whitespace rule (the issue's "trimmed to empty" wording is satisfied in effect: exit 1).
- Keep `_vault_complete_options` in sync with `_args_key` (comment in `cli/completion/vault.bash`).
- The #81 message is not in any release (latest tag `0.3.0`), so rewording it is not a user-facing break; update every assertion in the same change.
