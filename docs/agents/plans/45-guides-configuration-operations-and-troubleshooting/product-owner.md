# Product Owner Plan: Guides: configuration, operations and troubleshooting

Main plan: [plan.md](plan.md)

Issue: [45-guides-configuration-operations-and-troubleshooting.md](../../issues/45-guides-configuration-operations-and-troubleshooting.md)

## Overview
Three new reference pages under `docs/guides/vault/`, then index and cross-reference updates.
Content follows [guides-pages.md](../../specs/guides-pages.md) (sections `configuration.md`,
`operations.md`, `troubleshooting.md`, [Ports](../../specs/guides-pages.md#ports),
[Image tags](../../specs/guides-pages.md#image-tags)) and links follow
[guides-portability.md](../../specs/guides-portability.md#portability-rules).

## Context
- Sibling pages already landed: `vault.md`, `concepts.md`, `security.md` (#42),
  `docker-run.md`, `base-image.md` (#43), `cli.md` (#44). Match their style: one-line purpose
  plus a link back to `../vault.md` at the top, short sections, tables for mappings,
  copy-paste-ready commands, `darthjee/vault:<version>` as the image placeholder.
- Source of truth (check every message, default and exit code by hand):
  - README `## Environment variables`, `## Behaviour`, `### Persistence`, and the CLI
    sections (`### Commands` exit codes and message prefixes, `### Options and configuration`,
    `### Instances`, `### Docker Desktop`).
  - `source/bin/entrypoint.sh`, `source/lib/{preflight,dockerd,images,signals,compose}.sh`.
  - `cli/lib/*.sh` for CLI defaults (stop timeout `60`, env-key-only printing).
- [guides-readme.md](../../specs/guides-readme.md) maps README sections to these pages; the README
  itself is **not** changed here (that is #47).

## Steps

- [01 — Write configuration.md](product-owner/01-configuration.md)
- [02 — Write operations.md](product-owner/02-operations.md)
- [03 — Write troubleshooting.md](product-owner/03-troubleshooting.md)
- [04 — Index and cross-references](product-owner/04-cross-references.md)

## CI Checks
- `docs/guides/`: `make test-docs` (CI job: `build-and-test`, step `make test-docs`)

## Notes
- Do not duplicate whole sections that other pages own: link to `docker-run.md` / `cli.md` for
  how to run, to `concepts.md` for the persistence model, to `security.md` for privileges.
- `vault: docker compose down failed` (from `signals.sh`) is printed on shutdown but is not in
  the README; list it in troubleshooting as a shutdown message (not a startup error, does not
  change the exit code path described in the README).
- If writing the pages reveals that `guides-pages.md` needs a wording fix, update the spec in the
  same PR (as #43 did).
