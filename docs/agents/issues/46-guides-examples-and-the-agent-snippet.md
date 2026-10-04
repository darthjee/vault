# Issue: Guides: examples and the agent snippet

## Description
Part of epic #39 (portable user guides for Vault). Last page sub-issue: it adds the two
remaining pages, `docs/guides/vault/examples.md` and `docs/guides/vault/agents-snippet.md`.
It links to the pages written by #42–#45, which have all landed.
Agent: `product-owner`.

## Problem
Readers learn fastest from complete setups, and consumer repos' AI agents need a short,
ready-made pointer to the copied guides.

## Expected Behavior
Following `docs/agents/specs/guides-*.md` (mainly `guides-pages.md` → `examples.md`,
`agents-snippet.md`, Ports, Image tags):
- `docs/guides/vault/examples.md`: complete worked setups, each with a `docker run` variant
  and a CLI variant:
  - app + Postgres;
  - app + Redis;
  - multiple compose files;
  - a baked image with offline preload.
  Each shows the compose file, the commands, and the resulting ports and volumes. Each variant
  states its own port mapping (`docker run` → `8080:80`; CLI → default `3000:80` unless `-p`
  is given). Images: `darthjee/vault:<version>` as the Vault tag placeholder; public
  `postgres:17` and `redis:7` plus a placeholder `my-app` image (settles open point #6 of
  `guides-overview.md`).
- `docs/guides/vault/agents-snippet.md`: a short block, ready to paste into a consumer repo's
  `AGENTS.md`, that points at the copied guides (relative to where they are copied; the
  snippet says to adjust the path) and states the key rules: privileges (Sysbox preferred,
  `--privileged` fallback), `/vault`, ports, bind mounts referring to the Vault container,
  secrets staying out of git and images. Layout: a short intro (where to paste it, adjust the
  path), then one fenced markdown block to copy.
- `vault.md`: only its page index gains the two rows (no extra pointer under "Choosing a
  path").
- All links follow the portability rules
  (`guides-portability.md`); `make test-docs` (link check) passes.
