# Issue: Guides: configuration, operations and troubleshooting

## Description
Part of epic #39 (portable user guides for Vault). Writes the last three reference pages under
`docs/guides/vault/`: `configuration.md`, `operations.md` and `troubleshooting.md`, following
[`docs/agents/specs/guides-pages.md`](../specs/guides-pages.md) and
[`guides-portability.md`](../specs/guides-portability.md).

Depends on #42 (index, concepts, security), which has landed. Runs in parallel with #43 and #44
(both landed). #46 (examples and agent snippet) depends on this issue. Agent: `product-owner`.
There are no open points in `guides-overview.md` assigned to #45.

## Problem
Consumer repos need reference pages for configuring and operating a Vault stack, and for
diagnosing it when it fails. Today, `docker-run.md`, `base-image.md`, `cli.md`, `concepts.md`
and `security.md` already point readers at these pages by name in inline code ("not written
yet"), so the guides have dangling cross-references until this issue lands.

## Expected Behavior
Content follows `guides-pages.md`; behaviour is checked by hand against the README (`## Behaviour`,
CLI sections) and `AGENTS.md`. Every page starts with a one-line purpose and a link back to
`../vault.md`.

### `docs/guides/vault/configuration.md`
- Env vars: `COMPOSE_FILE`, `COMPOSE_PROJECT_NAME`, `COMPOSE_UP_ARGS` (whitespace split, no
  quoting support), `VAULT_DOCKERD_TIMEOUT` (positive integer, default `30`); other `COMPOSE_*`
  variables passed through to compose.
- Multiple compose files (`COMPOSE_FILE` as a `:`-separated list).
- How to pass them with `docker run` (`-e`, `--env-file`) and with the CLI (`.vault.env`, options).
- **Secrets handling:** keep `.vault.env` and env files out of git; never bake secrets into a
  derived image; the CLI prints env keys only, never values.

### `docs/guides/vault/operations.md`
- Persistence and the data volume (`/var/lib/docker`); what is lost without it.
- Shutdown: SIGTERM / SIGINT → `docker compose down` → stop `dockerd`; stop timeouts
  (`docker stop -t`, `--stop-timeout`, CLI default `60`).
- Logs (`docker logs`, `vault logs -f`).
- Running compose commands against a running stack (`docker exec … docker compose`,
  `vault compose`).
- Service failures and `restart:` policies; failing fast with `--abort-on-container-exit`.
- Never share one `/var/lib/docker` volume between two running containers.

### `docs/guides/vault/troubleshooting.md`
- Each startup error (exit `1`) with its exact message and cause, as in the README `## Behaviour`.
- Exit codes: image (compose's exit code, `128 + signal`) and CLI (`0` / `1` / `2`, inner exit
  code for `compose`, `run`, `up -f`).
- Common mistakes: missing privileges, host paths in inner bind mounts, busy ports, wrong port
  mapping, Docker Desktop file sharing, two instances sharing a data volume.

### Cross-references
- `vault.md`'s page index gets one row per new page.
- Every existing inline-code mention of these pages (currently in `docker-run.md`,
  `base-image.md`, `cli.md`, `concepts.md`, `security.md`) becomes a relative link, and the
  "(not written yet)" notes are removed.
- All links follow the portability rules; `make test-docs` passes.

## Solution
`product-owner` writes the three pages from the spec, sourcing every message, default and exit
code from the README and the scripts under `source/` and `cli/`, then updates `vault.md`'s index
and converts the pending mentions in the other guide pages into links.

## Benefits
Completes the reference set of the portable guides, removes every dangling "not written yet"
reference, and unblocks #46 (examples and the agent snippet).
