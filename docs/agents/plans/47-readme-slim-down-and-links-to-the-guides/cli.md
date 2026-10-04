# Cli Plan: README slim-down and links to the guides

Main plan: [plan.md](plan.md)

## Shared contracts

- New rootless hint text (exact): `see Security in the README`, so stderr reads
  `vault: hint: see Security in the README`.
- The `sysbox-runc not found; running with --privileged (see Security in the README)` warning
  is unchanged.

## Implementation Steps

### Step 1 — Reword the rootless hint
In `runtime_check_rootless` in `cli/lib/runtime.sh`, change
`output_hint 'see "Supported runtimes" in the README'` to
`output_hint 'see Security in the README'`. The "Supported runtimes and platforms" section is
leaving the README, but its Security section stays.

### Step 2 — Update the tests
Update the expected stderr in `test/cli/runtime.bats` (around line 89) and
`test/cli/resolve.bats` (around line 334) to
`vault: hint: see Security in the README`. Grep `test/` for any other
`Supported runtimes" in the README` occurrence.

## Files to Change
- `cli/lib/runtime.sh`: hint text.
- `test/cli/runtime.bats`, `test/cli/resolve.bats`: expected stderr.

## CI Checks
- `cli/`, `test/cli/`: `make lint`, `make test` (CI job: `build-and-test`)

## Notes
- No behaviour change apart from the message. `build/vault` is generated, so don't commit it.
