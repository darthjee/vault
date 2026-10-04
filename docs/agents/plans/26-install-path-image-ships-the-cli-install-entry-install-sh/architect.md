# Architect Plan: Install path: image ships the CLI, install entry, install.sh

Main plan: [plan.md](plan.md)

## Shared contracts

- **Relies on** `cli`'s `install.sh` surface (env vars, messages, completion paths) from
  [plan.md](plan.md#shared-contracts).

## Implementation Steps

### Step 1 — README Install section
Add an `## Install` section to `README.md`, before `## Usage`, covering:
- the one-liner `curl -fsSL https://github.com/darthjee/vault/releases/latest/download/install.sh | bash`;
- that it needs Docker, runs no `sudo`, and copies the CLI out of `darthjee/vault:<version>`
  (so the CLI matches the image), into `~/.local/bin` by default;
- the overrides `VAULT_VERSION`, `VAULT_INSTALL_DIR`, `VAULT_IMAGE` (a table, like
  `## Environment variables`), with a pinned-version example;
- completion setup (bash `source` line, zsh `fpath`) and the PATH note;
- a short integrity note: the tag is not immutable, and the release ships `SHA256SUMS` (#28).

Keep the existing sections unchanged, and keep the README `**Current Version:**` line intact.

## Files to Change
- `README.md` — new Install section.

## Notes
- The release URL only works once #28 publishes `install.sh` as a release asset. Say so briefly,
  or word it so it doesn't promise more than exists.
- `DOCKERHUB_DESCRIPTION.md` is owned by `automation` and is out of scope here.
