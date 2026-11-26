# Plan: CLI: --log-opt option for vault up / run to bound the instance's log

Issue: [81-cli-log-opt-option-for-vault-up-run-to-bound-the-instance-s-log.md](../../issues/81-cli-log-opt-option-for-vault-up-run-to-bound-the-instance-s-log.md)

## Overview

Add a repeatable `--log-opt <KEY=VALUE>` to `vault up` / `vault run` and a repeatable `log-opt` key to `.vaultrc`, emitted as `--log-opt` entries on the `docker run` line so the outer container's `json-file` log can be bounded. Values are checked structurally only (`<non-empty key>=<value>`), deduped by key (last wins), and a flag list replaces the `.vaultrc` list wholesale. `vault status` gains a last `logs:` line (sensitive values masked), and `vault up` on a running instance warns on stderr when a requested option is not in effect. The issue file is the detailed spec (code snippets, edge cases, test list); every step below refers to it.

## Agents involved

- [cli](cli.md) — option parsing, `.vaultrc`, `docker run` assembly, status line, stale-options warning, usage, completions, bats tests.
- [scripts](scripts.md) — one new assertion step in `scripts/test_cli_e2e.sh`.
- [product-owner](product-owner.md) — `docs/guides/vault/cli.md` and `docs/agents/flow.md`.

## Shared contracts

All three agents rely on the user-visible CLI behaviour `cli` produces:

1. **Flag:** `--log-opt <KEY=VALUE>` / `--log-opt=<KEY=VALUE>`, repeatable, accepted by `up` and `run` only. Any other command: `vault: error: unknown option '--log-opt'`, exit 2.
2. **`.vaultrc` key:** `log-opt=<KEY=VALUE>`, repeatable, one per line, value verbatim (the line splits at its first `=`).
3. **Validation:** value must match the bash pattern `?*=*`. Otherwise: flag → `vault: error: invalid value for --log-opt: '<value>'` (exit 2); `.vaultrc` → `.vaultrc:<line>: invalid value for log-opt: '<value>'` (exit 1).
4. **Precedence and dedupe:** flags replace the `.vaultrc` list wholesale; then dedupe by the text before the first `=`, last occurrence wins, survivor order kept. No default: with no source, no `--log-opt` is emitted.
5. **`docker run` position:** one `--log-opt <item>` pair per surviving entry, after the `-e` entries and before `--name` (`up`) / `-i`/`-t`/`--rm` (`run`).
6. **`vault status`:** a new **last** line, after `env:`, for any existing instance: `logs:     <driver>` with no options, else `logs:     <driver> <k=v>, <k=v>` sorted by key (e.g. `logs:     json-file max-file=2, max-size=10m`). Values of keys containing `token`, `password`, `secret` or `credential` (case-insensitive) print as `<key>=***`. A missing instance still prints only `name:` and `state:    not found`.
7. **Stale-options warning:** on `vault up` against a running instance, after the status block, stderr gets `vault: warning: log options differ from the running instance (<logs value>); run 'vault down' then 'vault up' to apply them` when any requested `KEY=VALUE` is not among the running options. Exit 0, stdout unchanged. Silent when nothing is requested or the running set is a superset.
8. **Version note:** the feature ships in vault CLI 0.4.0 (the guide says `log-opt` requires vault CLI ≥ 0.4.0).

## CI Checks

- `make lint`, `make test`, `make test-docs`, `make test-cli-e2e` (CircleCI jobs running those same targets).
