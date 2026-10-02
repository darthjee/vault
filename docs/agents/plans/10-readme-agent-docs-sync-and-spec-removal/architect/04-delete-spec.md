# Delete the spec and verify

Run this after the product-owner steps and architect steps 01–03.

1. Check that everything still relevant from `docs/agents/specs/docker-image/` is now covered by `flow.md`, `architecture.md`, `folder-structure.md`, `AGENTS.md` or `README.md`. The spec's sub-issue map, conflicts table and alternatives are intentionally dropped.
2. `git rm -r docs/agents/specs/`.
3. Verify: `grep -rn "specs/" --exclude-dir=.git --exclude-dir=state .` returns nothing, apart from historical issue or plan files under `docs/agents/issues/` and `docs/agents/plans/` that only describe this task. Also confirm that no "planned" wording remains in `docs/agents/folder-structure.md`.
4. `make check-version-tag TAG=0.1.0` still passes (the README version line is intact).

## Files to Change
- `docs/agents/specs/` — deleted.
