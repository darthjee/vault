# Architect Plan: Remove the CLI spec (docs/agents/specs)

Main plan: [plan.md](plan.md)

## Shared contracts

- Link to the hub `docs/agents/specs.md`, which `product-owner` creates (`../../docs/agents/specs.md` from `.claude/agents/`).
- Use this generic docs-table description: "Spec hub: what a spec is, naming, precedence, and the list of active specs (`specs/`)."
- Do not restate the precedence rule with an epic number. Link to the hub instead.

## Implementation Steps

### Step 1 — AGENTS.md
- In the docs table, replace the `Specs` row (currently `[Specs](docs/agents/specs/)` "CLI spec for epic #20 …") with `[Specs](docs/agents/specs.md)` and the generic description.
- Remove the line "During epic #20, `docs/agents/specs/*.md` overrides these docs where they conflict."
- Keep "(incl. `specs/`)" in the `product-owner` scope row of the Agents table.

### Step 2 — Agent definitions under `.claude/agents/`
- `architect.md`: replace the `Specs` row with `[Specs](../../docs/agents/specs.md)` and the generic description. Drop "overrides the docs above … until #30 removes it".
- `product-owner.md`: replace the `specs/` bullet with "`specs.md` and `specs/` — the spec hub and temporary per-epic specs (`<topic>-*.md`); see `specs.md`".
- `cli.md`: delete the line "During epic #20, follow the CLI spec in `docs/agents/specs/cli-*.md` …". Keep "`docs/agents/` (including `docs/agents/specs/`) — owned by `product-owner`".
- `automation.md`: delete the sentence "During epic #20, follow `docs/agents/specs/cli-*.md` for the CLI's Make targets, scripts, version line, bundling rule and CI jobs."
- `dev.md`: delete the sentence "During epic #20, follow `docs/agents/specs/cli-*.md` for anything the image ships for the CLI (paths, install entry contract)."

## Files to Change
- `AGENTS.md` — `Specs` row and the epic #20 precedence note.
- `.claude/agents/architect.md` — `Specs` row.
- `.claude/agents/product-owner.md` — `specs/` scope bullet.
- `.claude/agents/cli.md` — epic #20 spec line.
- `.claude/agents/automation.md` — epic #20 spec sentence.
- `.claude/agents/dev.md` — epic #20 spec sentence.

## CI Checks
- Documentation only. After the `product-owner` work lands, run the acceptance grep from [plan.md](plan.md#shared-contracts). It must print nothing.

## Notes
- The front-matter `description` of each agent file does not mention the spec, so it stays unchanged.
