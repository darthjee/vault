# Cli Plan: CLI: --log-opt option for vault up / run to bound the instance's log

Main plan: [plan.md](plan.md)

## Shared contracts

Produces contracts 1–8 of [plan.md](plan.md#shared-contracts). The exact strings (error messages, `logs:` line format, warning text) are consumed by the `scripts` e2e step and by the `product-owner` guide update; do not change them without updating the main plan.

## Steps

- [01 — Parse --log-opt](cli/01-parse-log-opt.md)
- [02 — .vaultrc key, merge and dedupe](cli/02-vaultrc-merge-dedupe.md)
- [03 — Emit --log-opt on docker run](cli/03-emit-docker-run.md)
- [04 — logs: line in vault status, with masking](cli/04-status-logs-line.md)
- [05 — Stale-options warning on vault up](cli/05-stale-options-warning.md)
- [06 — Usage and completions](cli/06-usage-completions.md)

## CI Checks

- `cli/`, `test/cli/`: `make lint` and `make test`.

## Notes

- bash 3.2 compatibility everywhere (`test/bash32` runs the suite there): no associative arrays, no `${var,,}`; guard empty-array expansions with `${a[@]+"${a[@]}"}`.
- The status template is positional: only **append** lines 6 and 7, never insert, so `_instance_line` indices 1..5 keep their meaning.
- The shared `STATUS_FORMAT` fixture in `test/cli/helpers/vault_cli.bash` and every status stub output must gain the two new lines, otherwise existing `status.bats` / `up.bats` assertions break — the main ripple of the change.
- No new library file, so `scripts/bundle_cli.sh` needs no change.
