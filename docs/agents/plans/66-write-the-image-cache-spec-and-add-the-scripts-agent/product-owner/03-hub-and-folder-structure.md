# Register the spec and update folder-structure.md

- `docs/agents/specs.md` — add the row `` `image-cache-` `` | #65 | #71 to the *Active specs* table, linking `specs/image-cache-overview.md`.
- `docs/agents/folder-structure.md`:
  - `test/` table: the `scripts/` row's owner becomes `scripts`.
  - `## scripts/` section: state that top-level `scripts/*.sh` are owned by `scripts` and `scripts/ci/` by `automation` (one line each), keeping the existing content.

## Files to Change

- `docs/agents/specs.md` — *Active specs* row.
- `docs/agents/folder-structure.md` — ownership of `scripts/` and `test/scripts/`.
