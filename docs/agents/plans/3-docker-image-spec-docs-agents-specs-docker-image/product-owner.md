# Product Owner Plan: Docker image spec (docs/agents/specs/docker-image)

Main plan: [plan.md](plan.md)

## Overview
Create the spec for epic #2 under `docs/agents/specs/docker-image/`. Sub-issues #4–#10 implement against it; it is a working document, updated by later PRs that deviate from it, and deleted by #10.

## Context
- The design today lives in `AGENTS.md` and `docs/agents/{architecture,flow,folder-structure,contributing}.md`. It describes the target state; nothing is implemented yet.
- Issue #3 records every decision: shared contracts, edge cases, privileges, security, base image, tool images, scripts vs Makefile, testing strategy, and the conflicts with the existing docs.
- **Writing rule:** each spec section links to the existing doc for anything unchanged ("see `<doc>`; in addition / instead:"). Only new or changed content is written out in full.
- **Sub-issue map:**
  - #4 scaffolding
  - #5 Dockerfile, dockerd and preload
  - #6 compose and signals
  - #7 smoke test
  - #8 CI on PRs
  - #9 release and Docker Hub
  - #10 docs and spec removal

## Steps

- [01 — Write overview.md](product-owner/01-overview.md)
- [02 — Write image.md](product-owner/02-image.md)
- [03 — Write tooling.md](product-owner/03-tooling.md)
- [04 — Write ci.md](product-owner/04-ci.md)
- [05 — Register the spec in AGENTS.md (architect)](product-owner/05-agents-md.md)
- [06 — Consistency review and checks](product-owner/06-review.md)

## CI Checks
- `docs/`, `AGENTS.md`: no CI job applies. `.claude/scripts/check_product-owner.sh` is a no-op (documentation only).
- Manual checks: every relative link resolves, and no file outside `docs/agents/specs/` and `AGENTS.md` changes.

## Notes
- `AGENTS.md` is a root-level file. `product-owner` must not edit it, so step 05 is done by the architect.
- Facts the spec only states as "to be verified" (they are not checked here):
  - whether the dind entrypoint adds the TCP host (#5 verifies);
  - whether the bats image bundles the helper libraries (#4 verifies);
  - the exact privilege probe (#5 decides).
- The pins (`docker:29.8.2-dind`, `koalaman/shellcheck:v0.11.0`, `bats/bats:1.14.0`) were current on 2026-10-01. Re-check them if implementation starts much later.
