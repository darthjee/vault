# Scripts Plan: CLI: --log-opt option for vault up / run to bound the instance's log

Main plan: [plan.md](plan.md)

## Shared contracts

Relies on contracts 1, 5 and 6 of [plan.md](plan.md#shared-contracts): `vault up` accepts `--log-opt max-size=10m --log-opt max-file=2`, and `vault status` prints a `logs:` line listing the effective options as `KEY=VALUE` (sorted by key, comma-separated, possibly with extra keys from the host's `daemon.json`).

## Implementation Steps

### Step 1 — Assert log options end to end

In `scripts/test_cli_e2e.sh`, add `--log-opt max-size=10m --log-opt max-file=2` to the `vault up` call in the up step, and in `cli_status` assert that the `logs:` line contains both `max-file=2` and `max-size=10m` (containment checks with `grep -E '^logs:.*max-file=2'` / `'^logs:.*max-size=10m'`, so a CI host's `daemon.json` defaults cannot break it), failing with a message that quotes the output, like the existing `runtime:` check. Update the script's header comment list of what the e2e run proves.

This is the only test proving that real Docker accepts the generated `docker run` line and that the status template parses a real `LogConfig`.

## Files to Change
- `scripts/test_cli_e2e.sh` — `--log-opt` on `vault up`; `logs:` assertions in `cli_status`; header comment.

## CI Checks
- `make test-cli-e2e` (CircleCI job of the same target; needs the image built by `make build-image`), plus `make lint` for shellcheck.

## Notes
- Depends on the `cli` work landing in the same branch; run it after `cli` steps 03 and 04.
