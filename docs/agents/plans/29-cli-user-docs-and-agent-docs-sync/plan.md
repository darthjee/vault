# Plan: CLI user docs and agent docs sync

Issue: [29-cli-user-docs-and-agent-docs-sync.md](../../issues/29-cli-user-docs-and-agent-docs-sync.md)

## Overview

Documentation-only sync after epic #20. `product-owner` writes the README `## CLI` section and
brings `AGENTS.md`, `folder-structure.md`, `architecture.md` and `flow.md` in line with what was
built. `automation` adds the CLI to `DOCKERHUB_DESCRIPTION.md`. The spec under
`docs/agents/specs/` is the source of facts and stays untouched (#30 removes it).

`README.md` and `AGENTS.md` are root-level files (architect scope); the issue assigns them to
`product-owner`, and the architect delegates them for this issue.

## Agents involved

- [product-owner](product-owner.md)
- [automation](automation.md)

## Shared contracts

- **README section:** a top-level `## CLI` heading, so its anchor is `#cli`
  (`https://github.com/darthjee/vault#cli`). The existing `## Install` section moves under it
  as `### Install` (its subsections become `####`).
- **Install one-liner** (same text in the README and the Docker Hub description):

  ```bash
  curl -fsSL https://github.com/darthjee/vault/releases/latest/download/install.sh | bash
  ```

- **Install defaults:** CLI in `~/.local/bin/vault`, completions in
  `~/.local/share/vault/completion/`; needs Docker, never `sudo`; `VAULT_VERSION=X.Y.Z` pins a
  version.
- **Quick-start commands:** `vault up` (detached, default port `3000:80`, Sysbox when detected,
  else `--privileged` with a warning), `vault status`, `vault down`.
- **Supported CLI platforms:** Linux and macOS (bash 3.2+); not Windows.
- The existing `https://github.com/darthjee/vault#security` anchor stays valid.
