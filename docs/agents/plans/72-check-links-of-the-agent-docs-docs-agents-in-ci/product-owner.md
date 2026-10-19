# Product Owner Plan: Check links of the agent docs (docs/agents) in CI

Main plan: [plan.md](plan.md)

## Shared contracts

Document the contract from [plan.md](plan.md#shared-contracts): `check_guides_links.sh [ROOT [BOUND]]`, and `make test-docs` checking `docs/guides/` (portable rules, unchanged) and all of `docs/agents/` (relative links may point anywhere inside the repo but must resolve, anchors included; `https://` only, no images, no reference-style links).

## Implementation Steps

### Step 1 — Update the agent docs describing `test-docs`

- `docs/agents/architecture.md` (the "Docs | `make test-docs`" row): describe both trees and the bound. Rename "Check guides links" to "Check docs links" wherever the CircleCI step is named.
- `docs/agents/folder-structure.md`:
  - the `scripts/` script list entry: `check_guides_links.sh [ROOT [BOUND]]`, `BOUND` defaulting to `ROOT`;
  - the `test-docs` make-target row;
  - the `test/scripts/` row ("on fixture guide trees", plus bound cases).
- `docs/agents/contributing.md`: add a row so changes under `docs/agents/` run `make test-docs`.
- Mention in the plans/issues conventions (where `docs/agents/` describes them) that issue and plan files are link-checked, so links must resolve. Files that don't exist yet are named in inline code.

## Files to Change

- `docs/agents/architecture.md` — `test-docs` row covers both trees and the bound.
- `docs/agents/folder-structure.md` — script signature, `test-docs` row and `test/scripts/` row.
- `docs/agents/contributing.md` — `docs/agents/` changes run `make test-docs`.

## CI Checks

- `docs/agents/`: `make test-docs` (CI job: `build-and-test`). The updated docs must themselves pass the new check.
