# Product Owner Plan: Remove the CLI spec (docs/agents/specs)

Main plan: [plan.md](plan.md)

## Shared contracts

- Create the hub at `docs/agents/specs.md`. `architect` links to it from `AGENTS.md` and `.claude/agents/`.
- Keep `docs/agents/specs/` with a `.gitkeep`.
- Spec naming is `docs/agents/specs/<topic>-*.md`. The precedence rule lives in the hub.

## Steps

- [01 — Delete the CLI spec files](product-owner/01-delete-cli-spec.md)
- [02 — Write the spec hub](product-owner/02-write-spec-hub.md)
- [03 — Update folder-structure.md](product-owner/03-update-folder-structure.md)

## CI Checks
- Documentation only, so no lint or test target applies. Run the acceptance grep from [plan.md](plan.md#shared-contracts) together with the `architect` changes. Before then, the remaining hits should only be in architect-owned files.

## Notes
- Draft issue #40 (guides spec) will be the first new spec. It adds itself to the hub's active-specs list, so this issue leaves that list empty.
