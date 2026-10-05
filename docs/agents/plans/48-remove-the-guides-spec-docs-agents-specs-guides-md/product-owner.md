# Product-owner Plan: Remove the guides spec (docs/agents/specs/guides-*.md)

Main plan: [plan.md](plan.md)

## Overview
Delete the guides spec and its row in the spec hub, once the architect has moved the lasting rules into `AGENTS.md` (see [plan.md](plan.md)).

## Context
The spec hub (`docs/agents/specs.md`) says the epic's last sub-issue deletes the spec files and the hub row. The folder stays with its `.gitkeep`, and the "Active specs" table stays with only its header row, ready for the next epic.

## Implementation Steps

### Step 1 — Delete the spec files
`git rm` `docs/agents/specs/guides-overview.md`, `guides-pages.md`, `guides-portability.md` and `guides-readme.md`. Keep `docs/agents/specs/.gitkeep`.

### Step 2 — Remove the hub row and check
In `docs/agents/specs.md` → "Active specs", remove the `guides-` row and keep the header and separator rows. Then check:

- `grep -rn 'specs/guides-\|guides-overview\|guides-pages\|guides-portability\|guides-readme' . --exclude-dir=.git` only matches this issue's own issue and plan files;
- `make test-docs` passes.

## Files to Change
- `docs/agents/specs/guides-overview.md` — deleted.
- `docs/agents/specs/guides-pages.md` — deleted.
- `docs/agents/specs/guides-portability.md` — deleted.
- `docs/agents/specs/guides-readme.md` — deleted.
- `docs/agents/specs.md` — remove the `guides-` row from "Active specs".

## CI Checks
- `docs/guides/`: `make test-docs` (CI job: `build-and-test`).

## Notes
- Do not touch `AGENTS.md` or `.claude/`: the architect owns those changes.
- No other doc in `docs/agents/` links to the guides spec (checked while planning).
