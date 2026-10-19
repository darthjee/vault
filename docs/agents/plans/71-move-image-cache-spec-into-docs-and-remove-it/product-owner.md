# Product-owner Plan: Move image-cache spec into docs and remove it

Main plan: [plan.md](plan.md)

## Overview
Write `docs/agents/release.md` as the single home of the image build rules introduced by epic #65, link it from the other agent docs and agent files, and delete the image-cache spec. Docs only: no `Dockerfile`, script, `Makefile` or CI change.

## Context
- The spec lives under `docs/agents/specs/` (`image-cache-overview.md`, `-agents.md`, `-dockerfile.md`, `-reproducible.md`, `-registry-cache.md`). #66, #68, #69 and #70 are merged; per `docs/agents/specs.md` the last sub-issue moves what stays relevant and deletes the spec.
- Already covered outside the spec: `Makefile` comments, `docs/agents/folder-structure.md` (`build-image`, `BUILD_CACHE`), `DOCKERHUB_DESCRIPTION.md` (`:buildcache` note), the `scripts` agent ownership in the agent files.
- Decisions from the discussion: a new `docs/agents/release.md` (not a section of `architecture.md`); keep a short rationale; the README is not changed; the *Active specs* table stays with its header and no rows.

## Steps

- [01 — Write docs/agents/release.md](product-owner/01-write-release-doc.md)
- [02 — Link release.md from the agent docs](product-owner/02-link-agent-docs.md)
- [03 — Point AGENTS.md and the agent files at release.md](product-owner/03-update-root-and-agent-files.md)
- [04 — Delete the spec and its row](product-owner/04-delete-spec.md)

## CI Checks
- `docs/agents/`, `AGENTS.md`, `.claude/agents/`: `make test-docs` (CI job: `build-and-test`, step "Check docs links").
- Final check: `grep -rn "image-cache" --exclude-dir=.git . | grep -v "docs/agents/issues/\|docs/agents/plans/"` prints nothing.

## Notes
- Step 03 touches `AGENTS.md` and `.claude/agents/*.md`, which are in the `architect` scope (root-level files and `.claude/`). `product-owner` drafts the exact wording; the `architect` applies it (or `product-owner` applies it when the architect delegates it explicitly).
- `docs/agents/flow.md` documents the runtime flow only and has no build / release part, so it gets no change (the issue's table listed it tentatively).
- `release.md` must not link to the spec files (they are deleted in step 04); issue numbers and repo paths outside `docs/` stay inline code or plain text, as elsewhere in the agent docs.
- Facts to copy must match the merged code (`Dockerfile`, `Makefile`, `scripts/release.sh`, `scripts/check_reproducible.sh`, `scripts/ci/setup_buildx.sh`); where the spec and the code disagree, the code wins and the doc follows it.
