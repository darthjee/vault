# Product Owner Plan: CLI: --log-opt option for vault up / run to bound the instance's log

Main plan: [plan.md](plan.md)

## Shared contracts

Documents contracts 1–8 of [plan.md](plan.md#shared-contracts) exactly as `cli` implements them (flag, `.vaultrc` key, validation errors, precedence and dedupe, `logs:` line format and masking, stale-options warning, version requirement).

## Implementation Steps

### Step 1 — User guide (`docs/guides/vault/cli.md`)

- Options table: a `--log-opt <KEY=VALUE>` row (repeatable, `up`/`run`, no default, Docker validates keys/values; structural `KEY=VALUE` check).
- `.vaultrc` key table: a `log-opt` row, repeatable like `volume`; note "requires vault CLI ≥ 0.4.0" (older CLIs only warn `unknown key`), and that credentials do not belong in a committed `.vaultrc`; list the masked key patterns.
- Precedence: one line — flags replace every `log-opt=` line; duplicate keys keep the last one.
- `vault status`: add `logs` to every list of status fields (the quick-reference comment near the top, the `vault status` row of the commands table, the comment above the example block) and a `logs:` line as the **last** line of the example block.
- A note under the option: log options apply only when the container is created — on a running instance, `vault down` then `vault up` (and `up` warns when they differ); only the outer container's log is bounded, not the inner services' logs in the `vault-<name>-data` volume; host `daemon.json` `log-opts` are merged in per key.

### Step 2 — Flow doc (`docs/agents/flow.md`)

- "CLI flow", step 3.4: add `--log-opt <opt>...` to the ordered `docker run` list between the `-e` entries and `--name` / `-i -t --rm`.
- The already-running branch of `up`: mention the stale-options warning on stderr.

## Files to Change
- `docs/guides/vault/cli.md` — option, key, precedence, status fields, notes.
- `docs/agents/flow.md` — `docker run` order and the `up` warning.

## CI Checks
- `make test-docs` (link check of `docs/guides/` and `docs/agents/`).

## Notes
- Per `docs/agents/contributing.md`, the guide update ships in the same PR as the code.
