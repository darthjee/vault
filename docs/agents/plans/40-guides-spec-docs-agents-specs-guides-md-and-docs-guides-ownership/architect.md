# Architect Plan: Guides spec (docs/agents/specs/guides-*.md) and docs/guides ownership

Main plan: [plan.md](plan.md)

## Shared contracts

- `product-owner`'s scope becomes `docs/agents/` (incl. `specs/`) **and** `docs/guides/`.
- No `AGENTS.md` override note for the spec: the existing `Specs` row points to the hub
  (`docs/agents/specs.md`), where `product-owner` adds the `guides-` row.

## Implementation Steps

### Step 1 — Extend the product-owner agent

In `.claude/agents/product-owner.md`:

- `description`: mention `docs/guides/` (portable user guides) next to `docs/agents/`.
- **Your scope**: add a bullet group for `docs/guides/` — `vault.md` and `vault/*.md`, the
  portable user guides copied by hand into consumer repos; follow the active guides spec
  (`docs/agents/specs/guides-*.md`, via `specs.md`) while epic #39 is open.
- Keep the "Do NOT touch" list as is (the README stays with `architect`).

### Step 2 — Update the agent tables

- `AGENTS.md` → **Agents** table, `product-owner` row:
  `` `docs/agents/` (incl. `specs/`), `docs/guides/` — issue specs, plans, project documentation, user guides ``.
- `.claude/agents/architect.md` → **Agents** table, `product-owner` row: same scope.
- Do not add a note under **Documentation**: the `Specs` row already points to the hub.

## Files to Change

- `.claude/agents/product-owner.md` — description and scope include `docs/guides/`.
- `AGENTS.md` — agents table row for `product-owner`.
- `.claude/agents/architect.md` — agents table row for `product-owner`.

## CI Checks

- Documentation only; no CI job is affected.

## Notes

- `docs/guides/` is under `docs/`, not a new root folder; it does not exist until #42.
