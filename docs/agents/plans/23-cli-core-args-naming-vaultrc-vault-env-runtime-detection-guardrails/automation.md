# Automation Plan: CLI core: args, naming, .vaultrc, .vault.env, runtime detection, guardrails

Main plan: [plan.md](plan.md)

## Shared contracts

- The `LIBS` array of `scripts/bundle_cli.sh` lists, in this exact order: `output.sh`,
  `usage.sh`, `docker.sh`, `args.sh`, `naming.sh`, `config.sh`, `guardrails.sh`, `runtime.sh`,
  `container.sh`.
- `cli` creates those files in the same PR. Until they exist, `bundle_cli.sh` fails
  ("library listed but missing"), so this change must land together with `cli`'s work.

## Implementation Steps

### Step 1 — Register the new libraries in the bundle order
Extend `LIBS` in `scripts/bundle_cli.sh` with the seven new files, after `output.sh` and
`usage.sh`, in the order above. Nothing else changes: `make lint` and `make test` already pick
up new `cli/lib/*.sh` and `test/cli/*.bats` files, and both test images already run
`test/cli/`.

## Files to Change
- `scripts/bundle_cli.sh` — add the new libraries to `LIBS`, in the fixed order.

## CI Checks
- `scripts/`: `make lint` and `make test` (CI job: `build-and-test`, which also runs
  `make bundle-cli`).

## Notes
- If `cli` needs a test helper file that the bats images must load in a special way, report it
  here; plain `load` of a file under `test/cli/` needs no tooling change.
