# Write troubleshooting.md
Create `docs/guides/vault/troubleshooting.md`: diagnosing a Vault stack that fails.

- Header: one-line purpose + link to `../vault.md`.
- Startup errors table (exit `1`, stderr), exact messages from README `## Behaviour` and
  `source/lib/*.sh`, with cause and fix:
  - `dockerd failed to start; are you running with --privileged (or the sysbox runtime)?` —
    missing privileges, or `dockerd` not ready within `VAULT_DOCKERD_TIMEOUT`.
  - `VAULT_DOCKERD_TIMEOUT must be a positive integer, got: '<value>'`.
  - `failed to load image tarball: <file>`.
  - Shutdown message `vault: docker compose down failed`.
- Exit codes: image (compose's exit code; `128 + signal` when stopped by a signal) and CLI
  (`0` / `1` / `2`; inner exit code for `compose`, `run`, `up -f`; prefixes `vault: error:` /
  `vault: warning:`), linking to `cli.md` for details.
- Common mistakes: missing privileges, host paths in inner bind mounts (they refer to the Vault
  container), busy host ports, wrong port mapping (host → Vault `80` → inner service), Docker
  Desktop file sharing, two instances sharing a data volume.

## Files to Change
- `docs/guides/vault/troubleshooting.md` — new page.
