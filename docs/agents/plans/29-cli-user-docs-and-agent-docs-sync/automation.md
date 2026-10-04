# Automation Plan: CLI user docs and agent docs sync

Main plan: [plan.md](plan.md)

## Shared contracts

- Link to the README CLI section as `https://github.com/darthjee/vault#cli`.
- Use the exact install one-liner, install defaults, quick-start commands and platform line
  from [plan.md → Shared contracts](plan.md#shared-contracts).

## Implementation Steps

### Step 1 — Add a CLI section to the Docker Hub description

Add a short `## CLI` section to `DOCKERHUB_DESCRIPTION.md`, after `## How to run`:

- one sentence: the `vault` CLI runs Vault containers for you (mounts, data volume, port,
  Sysbox detection with the `--privileged` fallback warning);
- the install one-liner, and that it installs into `~/.local/bin` from the image of the same
  version (`VAULT_VERSION=X.Y.Z` pins one);
- a three-line quick start: `vault up`, `vault status`, `vault down`;
- CLI platforms: Linux and macOS, not Windows;
- a link to the full docs: `https://github.com/darthjee/vault#cli`.

Keep it short: Docker Hub is a summary; the README is the reference. Absolute URLs only
(Docker Hub cannot resolve relative links).

## Files to Change

- `DOCKERHUB_DESCRIPTION.md` — new `## CLI` section.

## Notes

- Do not touch `scripts/ci/update_description.sh`; the description is pushed by the existing
  release job.
