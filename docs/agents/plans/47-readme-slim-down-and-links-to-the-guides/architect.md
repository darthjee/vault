# Architect Plan: README slim-down and links to the guides

Main plan: [plan.md](plan.md)

## Shared contracts

- The README keeps a `## Security` heading (anchor `#security`). The summary says rootless
  Docker is unsupported, and names Sysbox (preferred) and `--privileged` (fallback).
- Removed README anchors are listed in [plan.md](plan.md#shared-contracts).
- Links from root files to the guides are relative (`docs/guides/vault.md`, ...).

## Steps

- [01 — Slim down the README](architect/01-slim-down-readme.md)
- [02 — Update AGENTS.md](architect/02-update-agents-md.md)
- [03 — Fix product-owner.md and cross-check](architect/03-agent-file-and-cross-check.md)

## CI Checks
- `make lint`, `make test`, `make test-docs` (CI job: `build-and-test`)

## Notes
- `make check-version-tag` reads the README `**Current Version:**` line, so keep it exactly as
  it is.
