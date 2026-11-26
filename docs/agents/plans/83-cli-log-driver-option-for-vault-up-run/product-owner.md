# Product-owner Plan: CLI: --log-driver option for vault up / run

Main plan: [plan.md](plan.md)

## Shared contracts

Rely on the `cli` agent producing exactly what [plan.md → Shared contracts](plan.md#shared-contracts) lists. Document, in particular:

- `--log-driver <name>` on `up` / `run`; `log-driver` key, single value, last line wins; flag > `.vaultrc` > Docker default; requires vault CLI 0.4.0+.
- Structural validation only (non-empty, no whitespace, no `=`); Docker validates the name and option compatibility.
- The reworded warning text `log configuration differs from the running instance (...)`.

## Implementation Steps

### Step 1 — User guide (`docs/guides/vault/cli.md`)

- Options table: add a `--log-driver <name>` row before `--log-opt` (`up`, `run`, default "Docker's default (`json-file` unless `daemon.json` says otherwise)"), meaning: log driver for the Vault container, e.g. `local`, `journald`, `syslog`, `none`; the CLI only checks the shape; Docker validates the name.
- Log options bullet (around line 318): extend to cover the driver — it applies only at container creation; `up` warns when the requested driver or options differ from the running ones; `--log-opt` values must be valid for the effective driver. Add the **footgun**: a `--log-driver` flag does not reset `log-opt=` lines from `.vaultrc`; edit `.vaultrc` or pass `--log-opt` flags (which replace them all).
- `vault logs`: `none` (and remote drivers on Docker < 20.10) cannot be read; `vault logs` then shows Docker's error and exit code.
- Host-impact note: the driver runs in the host's Docker daemon; `syslog` / `gelf` / `fluentd` addresses resolve from the host network (`localhost` is the host); on Docker Desktop `journald` is the Linux VM's journal; plugin drivers must be installed on the daemon (`docker plugin install`); remote drivers ship all instance output, inner services included, off the host. `local` bounds and compresses the log by default.
- `.vaultrc` example: add `log-driver=local`; key table: `| `log-driver` | `--log-driver` | no (last line wins) |`; the version note (`log-opt` requires 0.4.0) extended to `log-driver`.
- Precedence list: `--log-driver` is a single-value key; resolved independently from `log-opt`.

### Step 2 — Agent flow doc (`docs/agents/flow.md`)

- In the `up` / `run` `docker run` line description (around line 105), insert `--log-driver <name>` (only when requested) before `--log-opt <opt>`.
- In the running-instance branch (around line 111), describe the warning as covering a requested driver or `--log-opt` entries that differ, with the new `log configuration differs` text.

## Files to Change

- `docs/guides/vault/cli.md` — option row, log bullet, footgun, `vault logs` note, host-impact note, `.vaultrc` example / table / version note, precedence.
- `docs/agents/flow.md` — `docker run` order and running-instance warning.

## CI Checks

- `docs/`: `make test-docs` (CI job: `build-and-test`)

## Notes

- Keep `docs/guides/` portable (no repo-internal paths), as for #81.
- If `docs/guides/vault/security.md` has a logging section, a one-line cross-reference to the host-impact note is welcome but optional.
